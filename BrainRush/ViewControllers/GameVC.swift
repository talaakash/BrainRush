//
//  GameVC.swift
//  BrainRush
//
//  Created by Admin on 04/11/25.
//

import UIKit

class GameVC: UIViewController {
    
    @IBOutlet private weak var questionLbl: UILabel!
    @IBOutlet private weak var answerTxt: UITextField!
    
    var gameSession: GameSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
}

extension GameVC {
    @IBAction private func submitBtnTapped(_ sender: UIButton) {
        guard let text = self.answerTxt.text, !text.isEmpty else { return }
        
    }
}
