//
//  WaitingScreen.swift
//  BrainRush
//
//  Created by Admin on 04/11/25.
//

import UIKit
internal import FirebaseFirestoreInternal
import SVProgressHUD

class WaitingVC: UIViewController {
    
    @IBOutlet private weak var waitingPlayerName: UITableView!
    @IBOutlet private weak var timerLbl: UILabel!
    
    private var gameSession: Game? {
        didSet {
            self.waitingPlayerName.reloadData()
        }
    }
    private var waitingTime: Int = 60
    private var timer: Timer?
    var sessionId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doInitSetup()
    }
    
    private func doInitSetup() {
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let id = self.sessionId else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        SVProgressHUD.show()
        FirebaseManager.shared.listenSession(sessionId: id, onUpdate: { result in
            SVProgressHUD.dismiss()
            switch result {
            case .success(let success):
                if success.status == .active {
                    DispatchQueue.main.async {
                        let vc = self.storyboard?.instantiateViewController(withIdentifier: String(describing: GameVC.self)) as! GameVC
                        vc.sessionId = success.id
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                    return
                }
                self.gameSession = success
                self.setupTimer()
            case .failure(let failure):
                debugPrint("Error: \(failure.localizedDescription)")
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        FirebaseManager.shared.stopListening()
    }
}

extension WaitingVC {
    private func setupTimer() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            guard let session = self.gameSession else { return }
            let previousTime = TimeInterval(floatLiteral: session.createdAt)
            let currentTime = Date().timeIntervalSince1970
            let elapsed = currentTime - previousTime
            self.timerLbl.text = "Start in \(Int(30 - elapsed))"
            if elapsed >= 30 {
                self.timer?.invalidate()
                if session.players.count > 1 {
                    FirebaseManager.shared.updateSession(sessionId: session.id!, newStatus: .active)
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        })
    }
}

extension WaitingVC {
    @IBAction private func backBtnTapped(_ sender: UIButton) {

    }
}

extension WaitingVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        gameSession?.players.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GameSessionCell", for: indexPath) as! GameSessionCell
//        cell.sessionNameLbl.text = self.currentSession?.players[indexPath.row]
        cell.sessionNameLbl.text = self.gameSession?.players[indexPath.row]
        return cell
    }
}
