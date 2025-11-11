//
//  UIViewController.swift
//  BrainRush
//
//  Created by Admin on 10/11/25.
//

import UIKit

typealias AlertCompletionHandler = (_ isOk: Bool) -> Void

extension UIViewController {
    func showAlert(
        title: String = "Brain Rush",
        message: String?,
        okTitle: String = "Okay",
        cancelTitle: String? = nil,
        completion: AlertCompletionHandler? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let okAction = UIAlertAction(title: okTitle, style: .default) { _ in
            completion?(true)
        }
        alert.addAction(okAction)

        if let cancel = cancelTitle {
            let cancelAction = UIAlertAction(title: cancel, style: .cancel) { _ in
                completion?(false)
            }
            alert.addAction(cancelAction)
        }

        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
}
