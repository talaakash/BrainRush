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
    @IBOutlet private weak var answerLbl1: UILabel!
    @IBOutlet private weak var answerLbl2: UILabel!
    @IBOutlet private weak var answerLbl3: UILabel!
    @IBOutlet private weak var answerLbl4: UILabel!
    
    private var gameSession: Game? {
        didSet {
            guard let session = self.gameSession else { return }
            if session.status == .completed {
                DispatchQueue.main.async {
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: String(describing: ScoreboardVC.self)) as! ScoreboardVC
                    vc.gameSession = session
                    self.navigationController?.pushViewController(vc, animated: true)
                }
                return
            }
            guard let question = questions.questions.first(where: { $0.id == session.questionIds[session.currentQuestionIndex] }) else { return }
            if self.currentQuestion?.id != question.id {
                self.currentQuestion = question
            }
        }
    }
    private var questionDuration: Int = 60
    private var currentQuestion: Question? {
        didSet {
            self.setupQuestion()
        }
    }
    private var interval: TimeInterval = Date().timeIntervalSince1970
    private var suggestions: [String] = [] {
        didSet {
            self.suggestionsTbl.reloadData()
        }
    }
    private var timer: Timer?
    
    var sessionId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doInitSetup()
    }
    
    private func doInitSetup() {
        NSLayoutConstraint.activate([
            self.suggestionsTbl.bottomAnchor.constraint(equalTo: self.view.keyboardLayoutGuide.topAnchor, constant: -8)
        ])
        answerTxt.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let id = self.sessionId else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        FirebaseManager.shared.listenSession(sessionId: id, onUpdate: { result in
            switch result {
            case .success(let session):
                self.gameSession = session
            case .failure(let failure):
                debugPrint("Error: \(failure.localizedDescription)")
                break
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        FirebaseManager.shared.stopListening()
    }
}

extension GameVC {
    private func setupQuestion() {
        guard let question = self.currentQuestion else { return }
        self.questionDuration = 60
        self.timer?.invalidate()
        self.interval = Date().timeIntervalSince1970
        self.questionLbl.text = question.question
        let answers = question.answers
        if answers.count >= 4 {
            self.answerLbl1.isHidden = true
            self.answerLbl2.isHidden = true
            self.answerLbl3.isHidden = true
            self.answerLbl4.isHidden = true
            self.answerLbl1.text = answers[0].answer
            self.answerLbl2.text = answers[1].answer
            self.answerLbl3.text = answers[2].answer
            self.answerLbl4.text = answers[3].answer
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { timer in
            self.questionDuration -= 1
            if self.questionDuration == 0 {
                timer.invalidate()
                self.questionDuration = 60
                FirebaseManager.shared.updateSession(sessionId: self.gameSession!.id!, moveToNextQuestion: true)
            }
        })
    }
}

extension GameVC {
    @IBAction private func submitBtnTapped(_ sender: UIButton) {
        guard let answer = self.answerTxt.text, !answer.isEmpty, let question = self.currentQuestion, let id = self.gameSession?.id else { return }
        if let answer = question.answers.first(where: { $0.answer.lowercased() == answer.lowercased() }) {
            let newInterval = Date().timeIntervalSince1970 - self.interval
            FirebaseManager.shared.submitAnswer(gameId: id, questionId: question.id, submission: AnswerSubmission(answerId: answer.id, points: answer.points, time: Double(newInterval)))
            switch answer.answer {
            case self.answerLbl1.text:
                self.answerLbl1.isHidden = false
            case self.answerLbl2.text:
                self.answerLbl2.isHidden = false
            case self.answerLbl3.text:
                self.answerLbl3.isHidden = false
            case self.answerLbl4.text:
                self.answerLbl4.isHidden = false
            default:
                break
            }
        } else {
            
        }
        self.answerTxt.text = ""
        self.suggestionsTbl.isHidden = true
        self.suggestions = []
    }
    
    @objc private  func textFieldDidChange(_ textField: UITextField) {
        guard let text = textField.text, text.count > 2 else {
            self.suggestionsTbl.isHidden = true
            return
        }
        self.suggestionsTbl.isHidden = false
        self.suggestions = questions.suggestions.filter{ $0.lowercased().contains(text.lowercased()) }
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
