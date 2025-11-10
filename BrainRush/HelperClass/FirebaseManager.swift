//
//  FirebaseManager.swift
//  BrainRush
//
//  Created by Admin on 06/11/25.
//

import Foundation
import FirebaseFirestore

final class FirebaseManager {
    
    // MARK: - Singleton Instance
    static let shared = FirebaseManager()
    private init() {}
    
    // MARK: - Firestore References
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    // MARK: - Cached Session Info
    private(set) var currentSessionId: String?
    
    // MARK: - Create or Join Session
    func findOrCreateSession(userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let sessionsRef = db.collection("gameSessions")
        
        // Find waiting session with <5 players
        sessionsRef
            .whereField("status", isEqualTo: "waiting")
            .whereField("currentPlayers", isLessThan: 6)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let doc = snapshot?.documents.first,
                   var players = doc.data()["players"] as? [String: Any],
                   let count = doc.data()["currentPlayers"] as? Int {
                    
                    // Join existing session
                    let newPlayerData: [String: Any] = [
                        "name": userId,
                        "answers": []
                    ]
                    players[userId] = newPlayerData
                    
                    doc.reference.updateData([
                        "players.\(userId)": newPlayerData,
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
                        "name": userId,
                        "answers": []
                    ]
                    
                    let sessionData: [String: Any] = [
                        "status": "waiting",
                        "currentPlayers": 1,
                        "players": [userId: playerData],
                        "questionUrl":  "https://firebasestorage.googleapis.com/v0/b/the-patel.appspot.com/o/DevelopmentJsons%2FBrainRush_Car.json?alt=media",
                        "startTime": Double(Date().timeIntervalSince1970),
                        "hostId": userId,
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
                             onChange: @escaping (Game) -> Void) {
        listener?.remove()
        listener = db.collection("gameSessions")
            .document(sessionId)
            .addSnapshotListener { snapshot, error in
                guard let document = snapshot, document.exists else {
                    print("Document not found or deleted")
                    return
                }
                
                do {
                    onChange(try document.data(as: Game.self))
                } catch {
                    print("Decoding error: \(error)")
                }
            }
    }
    
    func removePlayer(from sessionId: String, playerId: String, completion: ((Bool) -> Void)? = nil) {
        let ref = db.collection("gameSessions").document(sessionId)
        
        db.runTransaction({ transaction, _ -> Any? in
            do {
                let snapshot = try transaction.getDocument(ref)
                guard let session = snapshot.data() else { return }
                
                // Extract session data
                let currentPlayers = (session["currentPlayers"] as? Int) ?? 0
                var players = (session["players"] as? [String: Any]) ?? [:]
                let hostId = session["hostId"] as? String
                
                players.removeValue(forKey: playerId)
                
                // If this was the last player, delete session entirely
                if currentPlayers <= 1 || players.isEmpty {
                    transaction.deleteDocument(ref)
                    return
                }
                
                // Prepare updated data
                var updateData: [String: Any] = [
                    "players.\(playerId)": FieldValue.delete(),
                    "currentPlayers": FieldValue.increment(Int64(-1))
                ]
                
                // If host left, transfer host role
                if hostId == playerId {
                    if let newHostId = players.keys.first {
                        updateData["hostId"] = newHostId
                    }
                }
                
                transaction.updateData(updateData, forDocument: ref)
            } catch {
                completion?(false)
            }
            return
        }) { (_, error) in
            if let error = error {
                debugPrint("Error: \(error.localizedDescription)")
                completion?(false)
                self.currentSessionId = nil
            } else {
                completion?(true)
            }
        }
    }
    
    // MARK: - Submit Answers (Batch Update)
    func submitAnswers(userId: String, answers: [[String: Any]], completion: ((Error?) -> Void)? = nil) {
        guard let sessionId = currentSessionId else { return }
        
        let sessionRef = db.collection("gameSessions").document(sessionId)
        sessionRef.updateData([
            "players.\(userId).answers": FieldValue.arrayUnion(answers)
        ], completion: completion)
    }
    
    // MARK: - Mark Session Complete
    func updateSessionStatus(_ status: Status, completion: ((Error?) -> Void)? = nil) {
        guard let sessionId = currentSessionId else { return }
        db.collection("gameSessions").document(sessionId).updateData(["status": status.rawValue], completion: completion)
    }
    
    // MARK: - Stop Listener
    func stopListening() {
        listener?.remove()
        listener = nil
    }
}
