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
