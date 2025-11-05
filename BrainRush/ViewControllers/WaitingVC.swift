//
//  WaitingScreen.swift
//  BrainRush
//
//  Created by Admin on 04/11/25.
//

import UIKit
internal import FirebaseFirestoreInternal

class WaitingVC: UIViewController {
    
    @IBOutlet private weak var waitingPlayerName: UITableView!
    @IBOutlet private weak var timerLbl: UILabel!
    
    private var currentSession: GameSession? {
        didSet {
            self.waitingPlayerName.reloadData()
            self.handleTimer()
        }
    }
    private var listner: Listner?
    private var waitingTimer: Timer?
    private var questionData: Questions?
    private var isDownloadingData: Bool = false
    private var isDataDownloaded: Bool = false
    
    var gameId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let id = self.gameId {
            self.listner = FirestoreManager.shared.addSessionListner(for: id) { sessions in
                self.currentSession = sessions
                if !self.isDownloadingData {
                    self.isDownloadingData = true
                    ApiHelper.shared.callAPI(url: sessions.data, method: .get, successBlock: { data in
                        self.questionData = try? JSONDecoder().decode(Questions.self, from: data)
                        self.isDataDownloaded = true
                    }, failureBlock: { _ in })
                }
            }
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.listner?.remove()
        self.listner = nil
    }
    
    private func handleTimer() {
        waitingTimer?.invalidate()
        waitingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            if let session = self.currentSession {
                let previousTime = TimeInterval(floatLiteral: session.startTime)
                let currentTime = Date().timeIntervalSince1970
                let elapsed = currentTime - previousTime
                self.timerLbl.text = "Start in \(Int(30 - elapsed))"
                if elapsed >= 30 {
                    if session.players.count > 1, self.isDataDownloaded {
                        self.waitingTimer?.invalidate()
                        if let id = session.id, session.players.first == UserDefaults.standard.string(forKey: "userName") {
                            FirestoreManager.shared.updateSessionStatus(withID: id, status: .active)
                        }
                        DispatchQueue.main.async {
                            let vc = self.storyboard?.instantiateViewController(withIdentifier: String(describing: GameVC.self)) as! GameVC
                            vc.gameSession = session
                            vc.questions = self.questionData
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    } else {
                        if let id = session.id {
                            self.listner?.remove()
                            FirestoreManager.shared.deleteSession(withID: id)
                        }
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            } else {
                if let id = self.currentSession?.id {
                    self.listner?.remove()
                    FirestoreManager.shared.deleteSession(withID: id)
                }
                self.waitingTimer?.invalidate()
                self.navigationController?.popViewController(animated: true)
            }
        })
    }
}

extension WaitingVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        currentSession?.players.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GameSessionCell", for: indexPath) as! GameSessionCell
        cell.sessionNameLbl.text = self.currentSession?.players[indexPath.row]
        return cell
    }
}
