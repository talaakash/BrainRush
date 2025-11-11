//
//  ViewController.swift
//  BrainRush
//
//  Created by Admin on 04/11/25.
//

import UIKit
import SVProgressHUD

var questions: Questions!

class HomeVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doInitSetup()
    }

    private func doInitSetup() {
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        if let fileUrl = Bundle.main.url(forResource: "QuestionSuggestions", withExtension: "json"), let data = try? Data(contentsOf: fileUrl), let obj = try? JSONDecoder().decode(Questions.self, from: data) {
            questions = obj
        } else {
            exit(-1)
        }
    }
}

extension HomeVC: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        self.navigationController?.viewControllers.count ?? 0 > 1
    }
}

extension HomeVC {
    @IBAction private func newGameBtnTapped(_ sender: UIButton) {
        if let userName = UserDefaults.standard.string(forKey: "userName") {
            self.findSession(with: userName)
            return
        }
        let alert = UIAlertController(title: "BrainRush", message: "Enter Your Name.", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Your name"
            textField.autocapitalizationType = .words
        }
        let submitAction = UIAlertAction(title: "Submit", style: .default) { _ in
            guard let userName = alert.textFields?.first?.text, !userName.isEmpty else {
                print("⚠️ name is empty")
                return
            }
            UserDefaults.standard.set(userName, forKey: "userName")
            self.findSession(with: userName)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(submitAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
    }
    
    private func findSession(with userName: String) {
        SVProgressHUD.show()
        FirebaseManager.shared.currentUid = userName
        let questionIds = Array(questions.questions.map { $0.id }.shuffled().prefix(3))
        FirebaseManager.shared.findOrCreateSession(with: questionIds) { result in
            SVProgressHUD.dismiss()
            switch result {
            case .success(let sessionID):
                DispatchQueue.main.async {
                    let vc = self.storyboard?.instantiateViewController(identifier: String(describing: WaitingVC.self)) as! WaitingVC
                    vc.sessionId = sessionID
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            case .failure(let error):
                self.showAlert(message: "Error: \(error.localizedDescription)")
            }
        }
    }
}

class GameSessionCell: UITableViewCell {
    @IBOutlet weak var sessionNameLbl: UILabel!
}
