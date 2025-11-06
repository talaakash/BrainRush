import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

final class FirebaseManager {
    
    // MARK: - Singleton Instance
    static let shared = FirebaseManager()
    private init() {}
    
    // MARK: - Firestore References
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    // MARK: - Cached Session Info
    private(set) var currentSessionId: String?
    private(set) var currentUserId: String = Auth.auth().currentUser?.uid ?? UUID().uuidString
    
    // MARK: - Create or Join Session
    func findOrCreateSession(completion: @escaping (Result<String, Error>) -> Void) {
        let sessionsRef = db.collection("gameSessions")
        
        // Find waiting session with <5 players
        sessionsRef
            .whereField("status", isEqualTo: "waiting")
            .order(by: "createdAt", descending: false)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let doc = snapshot?.documents.first,
                   var players = doc.data()["players"] as? [String: Any],
                   let count = doc.data()["currentPlayers"] as? Int,
                   count < 5 {
                    
                    // Join existing session
                    let newPlayerData: [String: Any] = [
                        "name": "Player_\(Int.random(in: 1000...9999))",
                        "joinedAt": FieldValue.serverTimestamp(),
                        "answers": []
                    ]
                    players[self.currentUserId] = newPlayerData
                    
                    doc.reference.updateData([
                        "players.\(self.currentUserId)": newPlayerData,
                        "currentPlayers": count + 1
                    ]) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            self.currentSessionId = doc.documentID
                            completion(.success(doc.documentID))
                        }
                    }
                    
                } else {
                    // Create new session
                    let newSessionRef = sessionsRef.document()
                    let playerData: [String: Any] = [
                        "name": "Player_\(Int.random(in: 1000...9999))",
                        "joinedAt": FieldValue.serverTimestamp(),
                        "answers": []
                    ]
                    
                    let sessionData: [String: Any] = [
                        "status": "waiting",
                        "createdAt": FieldValue.serverTimestamp(),
                        "currentPlayers": 1,
                        "players": [self.currentUserId: playerData]
                    ]
                    
                    newSessionRef.setData(sessionData) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            self.currentSessionId = newSessionRef.documentID
                            completion(.success(newSessionRef.documentID))
                        }
                    }
                }
            }
    }
    
    // MARK: - Listen for Game Status Updates
    func listenSessionStatus(sessionId: String,
                             onChange: @escaping (_ data: [String: Any]) -> Void) {
        listener?.remove() // avoid duplicates
        listener = db.collection("gameSessions")
            .document(sessionId)
            .addSnapshotListener { snapshot, error in
                guard let data = snapshot?.data(), error == nil else { return }
                onChange(data)
            }
    }
    
    // MARK: - Submit Answers (Batch Update)
    func submitAnswers(_ answers: [[String: Any]], completion: ((Error?) -> Void)? = nil) {
        guard let sessionId = currentSessionId else { return }
        
        let sessionRef = db.collection("gameSessions").document(sessionId)
        sessionRef.updateData([
            "players.\(currentUserId).answers": FieldValue.arrayUnion(answers)
        ], completion: completion)
    }
    
    // MARK: - Download Question JSON
    func downloadQuestions(from urlString: String,
                           completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data {
                completion(.success(data))
            }
        }.resume()
    }
    
    // MARK: - Mark Session Complete
    func markSessionComplete(completion: ((Error?) -> Void)? = nil) {
        guard let sessionId = currentSessionId else { return }
        db.collection("gameSessions").document(sessionId)
            .updateData(["status": "completed",
                         "endTime": FieldValue.serverTimestamp()],
                        completion: completion)
    }
    
    // MARK: - Stop Listener
    func stopListening() {
        listener?.remove()
        listener = nil
    }
}
