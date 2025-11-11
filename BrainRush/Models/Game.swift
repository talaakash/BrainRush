//
//  Game.swift
//  BrainRush
//
//  Created by Admin on 10/11/25.
//
import FirebaseFirestore

enum Status: String, Codable {
    case waiting = "waiting"
    case active = "active"
    case completed = "completed"
}

class Game: Codable {
    @DocumentID var id: String?
    let hostId: String
    let status: Status
    let createdAt: Double
    let questionIds: [Int]
    let currentQuestionIndex: Int
    let currentPlayers: Int
    let players: [String]
}

class QuestionAnswers: Codable {
   let submissions: [String: [AnswerSubmission]]
}

class AnswerSubmission: Codable {
    let answerId: Int
    let points: Int
    let time: Double
    
    init(answerId: Int, points: Int, time: Double) {
        self.answerId = answerId
        self.points = points
        self.time = time
    }
    
    enum CodingKeys: String, CodingKey {
        case answerId, points, time
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        answerId = try container.decode(Int.self, forKey: .answerId)
        points = try container.decode(Int.self, forKey: .points)
        time = try container.decode(Double.self, forKey: .time)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(answerId, forKey: .answerId)
        try container.encode(points, forKey: .points)
        try container.encode(time, forKey: .time)
    }
}

class Score {
    let name: String
    let score: Int

    init(name: String, score: Int) {
        self.name = name
        self.score = score
    }
}
