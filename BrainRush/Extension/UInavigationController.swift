//
//  UInavigationController.swift
//  BrainRush
//
//  Created by Admin on 05/11/25.
//

import UIKit

extension UINavigationController {
    func popToViewController<ViewControllerType: UIViewController>(_ type: ViewControllerType.Type, animated: Bool) {
        for eachVC in self.viewControllers {
            if eachVC.isKind(of: type.self) {
                self.popToViewController(eachVC, animated: animated)
                break
            }
        }
    }
}
