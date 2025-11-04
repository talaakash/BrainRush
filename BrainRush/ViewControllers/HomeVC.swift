//
//  ViewController.swift
//  BrainRush
//
//  Created by Admin on 04/11/25.
//

import UIKit

class HomeVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doInitSetup()
    }

    private func doInitSetup() {
        
    }
}

extension HomeVC {
    @IBAction private func newGameBtnTapped(_ sender: UIButton) {
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
            FirestoreManager.shared.findOrCreateSession(for: userName, completion: { sessionId in
                DispatchQueue.main.async {
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: String(describing: WaitingVC.self)) as! WaitingVC
                    vc.gameId = sessionId
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            })
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(submitAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
    }
}

class GameSessionCell: UITableViewCell {
    @IBOutlet weak var sessionNameLbl: UILabel!
}
