//
//  FirebaseManager 2.swift
//  BrainRush
//
//  Created by Admin on 10/11/25.
//


import Foundation
import FirebaseFirestore

final class FirebaseManager {
    static let shared = FirebaseManager()
    var currentUid: String = ""
    private init() {}
    
    private let db = Firestore.firestore()
    private var sessionListener: ListenerRegistration?
    
    // MARK: - Public API: Find or Create Session
    /// Attempts to join an existing waiting session (currentPlayers < 3). If none available or join fails, creates a new session.
    func findOrCreateSession(with questionIds: [Int],
                             completion: @escaping (Result<String, Error>) -> Void) {
        // 1) query waiting sessions with available slots
        let q = db.collection("gameSessions")
            .whereField("status", isEqualTo: Status.waiting.rawValue)
            .whereField("currentPlayers", isLessThan: 3)
            .order(by: "createdAt", descending: false)
            .limit(to: 5)
        
        q.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error)); return
            }
            
            // try to join the first candidate via transaction
            if let docs = snapshot?.documents, !docs.isEmpty {
                self.tryJoinAny(docs: docs, completion: completion)
            } else {
                // no waiting session found -> create new
                self.createSession(with: questionIds, completion: completion)
            }
        }
    }
    
    // Try joining several candidates (if first fails due to race, try next)
    private func tryJoinAny(docs: [QueryDocumentSnapshot],
                            completion: @escaping (Result<String, Error>) -> Void) {
        var remaining = docs
        func attemptNext() {
            guard let doc = remaining.first else {
                // none could be joined -> fall back to create a new session
                // For fallback we need a questionIds owner; caller should have passed questionIds earlier.
                completion(.failure(NSError(domain: "FirebaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No available session to join. Retry creating."])))
                return
            }
            remaining.removeFirst()
            self.joinSessionTransaction(sessionDoc: doc) { joined in
                if joined {
                    completion(.success(doc.documentID))
                } else {
                    attemptNext()
                }
            }
        }
        attemptNext()
    }
    
    // Atomic join transaction for a single document
    private func joinSessionTransaction(sessionDoc: QueryDocumentSnapshot,
                                        completion: @escaping (Bool) -> Void) {
        let ref = sessionDoc.reference
        db.runTransaction({ transaction, _ -> Any? in
            do {
                let snap = try transaction.getDocument(ref)
                guard let data = snap.data() else { return false }
                
                // read fields
                let status = (data["status"] as? String) ?? Status.waiting.rawValue
                let currentPlayers = (data["currentPlayers"] as? Int) ?? 0
                var players = (data["players"] as? [String]) ?? []
                
                // only allow join if still waiting and slot available
                if status != Status.waiting.rawValue || currentPlayers >= 3 {
                    return false
                }
                
                // protect against duplicate join
                if players.contains(self.currentUid) {
                    return true // already joined from this client
                }
                
                // update players array and count
                players.append(self.currentUid)
                transaction.updateData([
                    "players": players,
                    "currentPlayers": FieldValue.increment(Int64(1))
                ], forDocument: ref)
            } catch {
                completion(false)
            }
            return true
        }, completion: { (_, error) in
            if let error = error {
                print("Join transaction failed: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        })
    }
    
    // MARK: - Create session
    func createSession(with questionIds: [Int],
                       completion: @escaping (Result<String, Error>) -> Void) {
        let sessions = db.collection("gameSessions")
        let newDoc = sessions.document()
        let now = Double(Date().timeIntervalSince1970)
        let sessionData: [String: Any] = [
            "hostId": currentUid,
            "status": Status.waiting.rawValue,
            "createdAt": now,
            "questionIds": questionIds,
            "currentQuestionIndex": 0,
            "currentPlayers": 1,
            "players": [currentUid]
        ]
        
        newDoc.setData(sessionData) { err in
            if let err = err {
                completion(.failure(err)); return
            }
            completion(.success(newDoc.documentID))
        }
    }
    
    // MARK: - Listen to a session (single listener for session-level fields)
    func listenSession(sessionId: String, onUpdate: @escaping (Result<Game, Error>) -> Void) {
        sessionListener?.remove()
        let ref = db.collection("gameSessions").document(sessionId)
        sessionListener = ref.addSnapshotListener { snap, error in
            if let error = error { onUpdate(.failure(error)); return }
            guard let snap = snap, let data = try? snap.data(as: Game.self) else {
                onUpdate(.failure(NSError(domain: "FirebaseManager", code:0, userInfo: [NSLocalizedDescriptionKey: "Failed to decode Game"])))
                return
            }
            onUpdate(.success(data))
        }
    }
    
    func stopListening() {
        sessionListener?.remove()
        sessionListener = nil
    }
    
    // MARK: - Host starts session (transaction-safe)
    func startSessionIfHost(sessionId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let ref = db.collection("gameSessions").document(sessionId)
        db.runTransaction({ transaction, _ -> Any? in
            do {
                let snap = try transaction.getDocument(ref)
                guard let session = try? snap.data(as: Game.self) else { return nil }
                // Only host and waiting sessions can start
                if session.hostId == self.currentUid && session.status == .waiting {
                    transaction.updateData([
                        "status": Status.active.rawValue,
                        "startTime": Date().timeIntervalSince1970
                    ], forDocument: ref)
                }
            } catch {
                completion(.failure(error))
            }
            return nil
        }) { (_, error) in
            if let error = error { completion(.failure(error)) } else { completion(.success(())) }
        }
    }
    
    // MARK: - Submit answer (append into /answers/{questionId})
    /// Adds an AnswerSubmission for current user under /gameSessions/{gameId}/answers/{questionId}
    func submitAnswer(gameId: String, questionId: Int, submission: AnswerSubmission, completion: ((Error?) -> Void)? = nil) {
        let answersRef = db.collection("gameSessions").document(gameId)
            .collection("answers").document("\(questionId)")
        
        let field = "submissions.\(currentUid)"
        let dict: [String: Any] = [
            "answerId": submission.answerId,
            "points": submission.points,
            "time": submission.time
        ]
        
        // Use arrayUnion on the player's submissions array
        answersRef.setData([ : ], merge: true) { _ in
            answersRef.updateData([
                field: FieldValue.arrayUnion([dict])
            ], completion: completion)
        }
    }
    
    func updateSession(sessionId: String, newStatus: Status? = nil, moveToNextQuestion: Bool = false, completion: ((Result<Void, Error>) -> Void)? = nil) {
        
        let ref = db.collection("gameSessions").document(sessionId)
        
        db.runTransaction({ transaction, _ -> Any? in
            do {
                let snap = try transaction.getDocument(ref)
                guard let session = try? snap.data(as: Game.self) else {
                    throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode Game"])
                }
                
                // Only the host can perform updates
                guard session.hostId == self.currentUid else {
                    throw NSError(domain: "FirebaseManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unauthorized host update"])
                }
                
                var updates: [String: Any] = [:]
                
                // Handle status update
                if let status = newStatus, status != session.status {
                    updates["status"] = status.rawValue
                }
                
                // Handle next question index update
                if moveToNextQuestion {
                    let nextIndex = session.currentQuestionIndex + 1
                    if nextIndex < session.questionIds.count {
                        updates["currentQuestionIndex"] = nextIndex
                    } else {
                        // If questions are exhausted, mark session as completed
                        updates["status"] = Status.completed.rawValue
                    }
                }
                
                guard !updates.isEmpty else { return nil }
                transaction.updateData(updates, forDocument: ref)
            } catch {
                completion?(.failure(error))
            }
            return nil
        }) { (_, error) in
            if let error = error {
                completion?(.failure(error))
            } else {
                completion?(.success(()))
            }
        }
    }
    
    func fetchAllQuestionAnswers(sessionId: String,
                                 completion: @escaping (Result<[QuestionAnswers], Error>) -> Void) {
        
        let answersRef = db.collection("gameSessions").document(sessionId).collection("answers")
        
        answersRef.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                completion(.success([]))
                return
            }
            
            Task { @MainActor in
                var allAnswers: [QuestionAnswers] = []
                for document in documents {
                    do {
                        let data = try document.data(as: QuestionAnswers.self)
                        allAnswers.append(data)
                    } catch {
                        print("❌ Failed to decode \(document.documentID): \(error.localizedDescription)")
                    }
                }
                
                completion(.success(allAnswers))
            }
        }
    }
}
