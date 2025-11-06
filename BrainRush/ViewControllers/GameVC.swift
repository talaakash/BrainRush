//
//  GameVC.swift
//  BrainRush
//
//  Created by Admin on 04/11/25.
//

import UIKit

class GameVC: UIViewController {
    
    @IBOutlet private weak var questionLbl: UILabel!
    @IBOutlet private weak var timerLbl: UILabel!
    @IBOutlet private weak var answerTxt: UITextField!
    @IBOutlet private weak var suggestionsTbl: UITableView!
    
    var gameSession: GameSession?
    var questions: Questions?
    
    var suggestions: [String] = [] {
        didSet {
            DispatchQueue.main.async {
                self.suggestionsTbl.reloadData()
            }
        }
    }
    
    private var questionIndex: Int = -1
    private var questionInteval: TimeInterval = 0.0
    private var gameDuration: Int = 60
    private var gameTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        answerTxt.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        guard let questions, questions.questions.count > 0 else {
            self.navigationController?.popToViewController(HomeVC.self, animated: true)
            return
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.showNextQuestion()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            self.gameDuration -= 1
            self.timerLbl.text = "Ends in: \(self.gameDuration)"
            if self.gameDuration == 0 {
                self.gameTimer?.invalidate()
                self.gameTimer = nil
                if let id = self.gameSession?.id, self.gameSession?.players.first == UserDefaults.standard.string(forKey: "userName") {
                    FirestoreManager.shared.updateSessionStatus(withID: id, status: .completed)
                }
                DispatchQueue.main.async {
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: String(describing: ScoreboardVC.self)) as! ScoreboardVC
                    vc.gameSession = self.gameSession
                    vc.questions = self.questions
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.gameTimer?.invalidate()
    }
}

extension GameVC {
    private func showNextQuestion() {
        self.questionIndex += 1
        self.questionLbl.text = self.questions?.questions[self.questionIndex].question
        self.answerTxt.text = nil
        self.questionInteval = Date().timeIntervalSince1970
        self.suggestions = self.questions?.suggestions ?? []
        self.answerTxt.text = nil
    }
}

extension GameVC {
    @IBAction private func submitBtnTapped(_ sender: UIButton) {
        guard let id = gameSession?.id, let questionId = self.questions?.questions[self.questionIndex].id, let text = self.answerTxt.text, !text.isEmpty else { return }
        let interval = Date().timeIntervalSince1970 - self.questionInteval
        FirestoreManager.shared.submitResponse(sessionId: id, questionId: questionId, userName: UserDefaults.standard.string(forKey: "userName")!, answer: text, timeTaken: Double(interval))
        self.showNextQuestion()
    }
    
    @objc private  func textFieldDidChange(_ textField: UITextField) {
        guard let text = textField.text, let suggestions = self.questions?.suggestions else { return }
        self.suggestions = suggestions.filter{ $0.lowercased().contains(text.lowercased()) }
    }
}

extension GameVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        suggestions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GameSessionCell", for: indexPath) as! GameSessionCell
        cell.sessionNameLbl.text = self.suggestions[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.answerTxt.text = self.suggestions[indexPath.row]
    }
}
