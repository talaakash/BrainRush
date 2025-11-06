//
//  Firestore.swift
//  BrainRush
//
//  Created by Admin on 04/11/25.
//

import FirebaseFirestore

typealias Listner = ListenerRegistration

final class FirestoreManager {
    static let shared = FirestoreManager()
    
    private let db = Firestore.firestore()
    
    private init() { }
    
    func findOrCreateSession(for userName: String, completion: @escaping (String?) -> Void) {
        db.collection("gameSessions").whereField("status", isEqualTo: "waiting").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Query error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let documents = snapshot?.documents {
                for doc in documents {
                    let players = doc.data()["players"] as? [String] ?? []
                    if players.count < 5 {
                        self.appendPlayer(to: doc.documentID, playerName: userName, completion: completion)
                        return
                    }
                }
            }
            self.createNewSession(for: userName, completion: completion)
        }
    }
    
    func updateSessionStatus(withID sessionID: String, status: Status, error: (((Error?) -> Void))? = nil) {
        db.collection("gameSessions").document(sessionID).updateData(["status": status.rawValue]) { updateError in
            error?(updateError)
        }
    }
    
    func deleteSession(withID sessionID: String, completion: ((Bool) -> Void)? = nil) {
        db.collection("gameSessions").document(sessionID).delete { error in
            if let error = error {
                print("❌ Deletion error for \(sessionID): \(error.localizedDescription)")
                completion?(false)
            } else {
                print("✅ Session \(sessionID) deleted successfully.")
                completion?(true)
            }
        }
    }
    
    func addSessionListner(for sessionID: String, completion: @escaping ((GameSession) -> Void)) -> Listner {
        return db.collection("gameSessions").document(sessionID).addSnapshotListener { documentSnapshot, error in
            if let error = error {
                print("❌ Document listener error: \(error.localizedDescription)")
                return
            }
            
            guard let document = documentSnapshot, document.exists else {
                print("⚠️ Document not found or deleted")
                return
            }
            
            do {
                completion(try document.data(as: GameSession.self))
            } catch {
                print("⚠️ Decoding error: \(error)")
            }
        }
    }
    
    func submitResponse(sessionId: String, questionId: Int, userName: String, answer: String, timeTaken: Double) {
        let ref = db.collection("gameSessions").document(sessionId).collection("questions").document("\(questionId)")
        
        let newResponse: [String: Any] = [
            "name": userName,
            "answer": answer,
            "time": timeTaken
        ]
        
        ref.setData([
            "questionId": questionId,
            "responses": FieldValue.arrayUnion([newResponse])
        ], merge: true) { error in
            if let error = error {
                print("⚠️ Firestore error: \(error.localizedDescription)")
            } else {
                print("✅ Created/Updated document for question \(questionId)")
            }
        }
    }
    
    func getAllResponses(sessionId: String, completion: @escaping (([Response]?) -> Void)) {
        db.collection("gameSessions").document(sessionId).collection("questions").getDocuments(completion: {
            snapshot, error in
                if let error = error {
                    print("❌ Query error: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
            guard let document = snapshot?.documents else {
                print("⚠️ Document not found or deleted")
                return
            }
            
            Task { @MainActor in
                do {
                    let responses = try document.map { doc in
                        try doc.data(as: Response.self)
                    }
                    completion(responses)
                } catch {
                    print("⚠️ Decoding error: \(error.localizedDescription)")
                    completion([])
                }
            }
        })
    }
    
}

extension FirestoreManager {
    private func createNewSession(for userName: String, completion: @escaping (String?) -> Void) {
        let sessionsRef = db.collection("gameSessions")
        
        let sessionData: [String: Any] = [
            "status": "waiting",
            "players": [userName],
            "data": "https://firebasestorage.googleapis.com/v0/b/the-patel.appspot.com/o/DevelopmentJsons%2FBrainRush_Car.json?alt=media",
            "startTime": Double(Date().timeIntervalSince1970)
        ]
        
        var ref: DocumentReference? = nil
        ref = sessionsRef.addDocument(data: sessionData) { error in
            if let error = error {
                print("❌ Creation error: \(error.localizedDescription)")
                completion(nil)
            } else if let id = ref?.documentID {
                print("✅ New session \(id) created for \(userName)")
                completion(id)
            }
        }
    }
    
    private func appendPlayer(to sessionID: String, playerName: String, completion: @escaping (String?) -> Void) {
        db.collection("gameSessions").document(sessionID).updateData([
            "players": FieldValue.arrayUnion([playerName])
        ]) { error in
            if let error = error {
                print("⚠️ Append error: \(error.localizedDescription)")
                completion(nil)
            } else {
                print("✅ Player \(playerName) joined session \(sessionID)")
                completion(sessionID)
            }
        }
    }
}
