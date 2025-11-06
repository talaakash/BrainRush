//
//  ViewController.swift
//  BrainRush
//
//  Created by Admin on 04/11/25.
//

import UIKit
import SVProgressHUD

class HomeVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doInitSetup()
    }

    private func doInitSetup() {
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
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
        FirestoreManager.shared.findOrCreateSession(for: userName, completion: { sessionId in
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                let vc = self.storyboard?.instantiateViewController(withIdentifier: String(describing: WaitingVC.self)) as! WaitingVC
                vc.gameId = sessionId
                self.navigationController?.pushViewController(vc, animated: true)
            }
        })
    }
}

class GameSessionCell: UITableViewCell {
    @IBOutlet weak var sessionNameLbl: UILabel!
}
