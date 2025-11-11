//
//  Game.swift
//  BrainRush
//
//  Created by Admin on 10/11/25.
//

class Questions: Codable {
    let questions: [Question]
    let suggestions: [String]
}

class Question: Codable {
    let id: Int
    let question: String
    let answers: [Answers]
}

class Answers: Codable {
    let id: Int
    let answer: String
    let points: Int
}
