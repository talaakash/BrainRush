//
//  ScoreboardVC.swift
//  BrainRush
//
//  Created by Admin on 06/11/25.
//

import UIKit
import SVProgressHUD

class ScoreboardVC: UIViewController {

    @IBOutlet private weak var scoreTbl: UITableView!
    
    private var responses: [Response] = []
    var questions: Questions?
    var gameSession: GameSession?
    
    private var scores: [Score] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doInitSetup()
    }
    
    private func doInitSetup() {
        guard let id = gameSession?.id, let questions = questions?.questions else { return }
        SVProgressHUD.show()
        FirestoreManager.shared.getAllResponses(sessionId: id, completion: { responses in
            self.responses = responses ?? []
            let answerMap = Dictionary(uniqueKeysWithValues: questions.map { ($0.id, $0.answer.lowercased()) })
            
            var userScores: [String: Int] = [:]
            for response in self.responses {
                guard let correctAnswer = answerMap[response.questionId] else { continue }
                
                for user in response.responses {
                    if user.answer.lowercased() == correctAnswer {
                        userScores[user.name, default: 0] += 1
                    }
                }
            }
            self.scores = userScores.map { Score(name: $0.key, score: $0.value) }
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                self.scoreTbl.reloadData()
            }
        })
    }
}

extension ScoreboardVC {
    @IBAction private func homeBtnTapped(_ sender: UIButton) {
        self.navigationController?.popToViewController(HomeVC.self, animated: true)
    }
}

extension ScoreboardVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        scores.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScoreCell", for: indexPath) as! ScoreCell
        let score = self.scores[indexPath.row]
        cell.nameLbl.text = score.name
        cell.scoreLbl.text = "Score: \(score.score)"
        return cell
    }
}


class ScoreCell: UITableViewCell {
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var scoreLbl: UILabel!
}
