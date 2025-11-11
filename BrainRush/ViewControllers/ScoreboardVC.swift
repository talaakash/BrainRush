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
    
    var gameSession: Game?
    private var scores: [Score] = [] { 
        didSet {
            self.scoreTbl.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doInitSetup()
    }
    
    private func doInitSetup() {
        FirebaseManager.shared.fetchAllQuestionAnswers(sessionId: gameSession!.id!, completion: { result in
            switch result {
            case .success(let success):
                self.calculateScore(with: success)
                break
            case .failure(let failure):
                debugPrint("Error: \(failure.localizedDescription)")
                break
            }
        })
    }
}

extension ScoreboardVC {
    private func calculateScore(with allQuestionAnswers: [QuestionAnswers]) {
        var userScores: [String: Int] = [:]
        
        for questionData in allQuestionAnswers {
            var allSubmissions: [(uid: String, answerId: Int, points: Int, time: Double)] = []
            
            for (uid, answers) in questionData.submissions {
                for ans in answers {
                    allSubmissions.append((uid, ans.answerId, ans.points, ans.time))
                }
            }
            
            // Group all submissions by answerId and reward the first responder
            let grouped = Dictionary(grouping: allSubmissions, by: { $0.answerId })
            
            for (_, submissions) in grouped {
                if let fastest = submissions.min(by: { $0.time < $1.time }) {
                    userScores[fastest.uid, default: 0] += fastest.points
                }
            }
        }
        
        // Convert dictionary to Score model array
        let scores = userScores.map { key, value in
            Score(name: key, score: value)
        }
        
        // Optional: sort descending by score
        self.scores = scores.sorted { $0.score > $1.score }
    }
}

extension ScoreboardVC {
    @IBAction private func homeBtnTapped(_ sender: UIButton) {
        self.navigationController?.popToViewController(HomeVC.self, animated: true)
    }
}

extension ScoreboardVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.scores.count
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
