//
//  File.swift
//  BrainRush
//
//  Created by Admin on 04/11/25.
//

import FirebaseFirestore

enum Status: String, Codable {
    case waiting = "waiting"
    case active = "active"
    case completed = "completed"
}

class GameSession: Codable {
    @DocumentID var id: String? 
    let players: [String]
    let startTime: Double
    let status: Status
    let data: String
}

class Response: Codable {
    @DocumentID var id: String?
    let questionId: Int
    let responses: [User]
}

class User: Codable {
    let name: String
    let answer: String
    let time: Double
}



class Questions: Codable {
    let questions: [Question]
    let suggestions: [String]
}

class Question: Codable {
    let id: Int
    let question: String
    let answer: String
}

class Score {
    let name: String
    let score: Int
    
    init(name: String, score: Int) {
        self.name = name
        self.score = score
    }
}

struct Game: Codable, Identifiable {
    @DocumentID var id: String?
    
    var status: GameStatus
    var players: [String: PlayerData]
    var questionUrl: String
    var currentPlayers: Int
    var startTime: Double?
    var hostId: String
    
    enum GameStatus: String, Codable {
        case waiting
        case active
        case completed
    }
    
    // MARK: - Default Empty Init (Optional)
    init(
        id: String? = nil,
        status: GameStatus = .waiting,
        players: [String: PlayerData] = [:],
        questionUrl: String = "",
        currentPlayers: Int = 0,
        startTime: Double? = nil,
        hostId: String
    ) {
        self.id = id
        self.status = status
        self.players = players
        self.questionUrl = questionUrl
        self.currentPlayers = currentPlayers
        self.startTime = startTime
        self.hostId = hostId
    }
}

struct PlayerData: Codable {
    var name: String
    var answers: [PlayerAnswer]
    
    init(name: String = "", answers: [PlayerAnswer] = []) {
        self.name = name
        self.answers = answers
    }
}

struct PlayerAnswer: Codable {
    var qid: Int
    var answer: String
    var time: Double
    
    init(qid: Int, answer: String, time: Double) {
        self.qid = qid
        self.answer = answer
        self.time = time
    }
}
