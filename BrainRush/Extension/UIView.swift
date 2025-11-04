//
//  UIView.swift
//  BrainRush
//
//  Created by Admin on 04/11/25.
//


import UIKit

private var isCircularKey: UInt8 = 0
extension UIView {
    @IBInspectable
    var cornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set {
            self.layer.cornerRadius = newValue
        }
    }
    
    @IBInspectable
    var borderColor: UIColor? {
        get{
            if let color = self.layer.borderColor {
                return UIColor(cgColor: color)
            } else {
                return UIColor.clear
            }
        }
        set {
            self.layer.borderColor = newValue?.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }
    
    @IBInspectable var shadowColor: UIColor? {
        get {
            return UIColor(cgColor: self.layer.shadowColor!)
        }
        set {
            self.layer.shadowColor = newValue?.cgColor
        }
    }
   
    @IBInspectable var shadowOpacity: Float {
        get {
            return self.layer.shadowOpacity
        }
        set {
            self.layer.shadowOpacity = newValue
        }
    }
    
    @IBInspectable var shadowOffset: CGSize {
        get {
            return self.layer.shadowOffset
        }
        set {
            self.layer.shadowOffset = newValue
        }
    }
    
    @IBInspectable var shadowRadius: Double {
        get {
            return Double(self.layer.shadowRadius)
        }
        set {
            self.layer.shadowRadius = CGFloat(newValue)
        }
    }

    func addEffect(with colors: UIColor = .white) {
        guard let sImage = self.generateDummyImage()?.withRenderingMode(.alwaysTemplate) else { return }
        let tempImageView = UIImageView(image: sImage)
        tempImageView.tintColor = colors.withAlphaComponent(0.8)
        guard let tintedSnapshot = tempImageView.generateDummyImage() else { return }
        
        let effectLayer = CALayer()
        effectLayer.frame = bounds
        effectLayer.contents = tintedSnapshot.cgImage
        
        let gradientMask = CAGradientLayer()
        gradientMask.colors = [
            UIColor.clear.cgColor,
            UIColor.clear.cgColor,
            UIColor.black.cgColor,
            UIColor.clear.cgColor,
            UIColor.clear.cgColor
        ]
        gradientMask.locations = [0.0, 0.4, 0.55, 0.6, 1.0]
        
        let angleD: CGFloat = 30
        let normalizedDAngle = angleD.truncatingRemainder(dividingBy: 360)
        let angle = normalizedDAngle < 0 ? 360 + normalizedDAngle : normalizedDAngle
        
        let middleOffSet: CGFloat = 0.5
        gradientMask.startPoint = CGPoint(x: 0, y: middleOffSet * tanAngle(angle) + middleOffSet)
        gradientMask.endPoint = CGPoint(x: 1, y: middleOffSet * tanAngle(-angle) + middleOffSet)
        
        gradientMask.frame = CGRect(x: -tintedSnapshot.size.width, y: 0, width: tintedSnapshot.size.width, height: tintedSnapshot.size.height)
        
        let animationEffect = CABasicAnimation(keyPath: "position.x")
        animationEffect.repeatCount = .infinity
        animationEffect.duration = 3.0
        animationEffect.byValue = tintedSnapshot.size.width * 2
        animationEffect.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        layer.addSublayer(effectLayer)
        effectLayer.mask = gradientMask
        gradientMask.add(animationEffect, forKey: "shimmerAnimation")
    }
    
    private func generateDummyImage() -> UIImage? {
        if bounds.size.height <= 0 {
            return nil
        }
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        drawHierarchy(in: bounds, afterScreenUpdates: true)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    private func tanAngle(_ angle: CGFloat) -> CGFloat {
        return tan(angle * .pi / 180)
    }
    
    
    func removeEffect() {
        layer.sublayers?.forEach { sublayer in
            sublayer.mask?.removeAnimation(forKey: "shimmerAnimation")
        }
    }
    
    @IBInspectable
    var isCircular: Bool {
        get { return objc_getAssociatedObject(self, &isCircularKey) as? Bool ?? false }
        set {
            objc_setAssociatedObject(self, &isCircularKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if newValue { UIView.swizzleLayoutSubviews() }
            setNeedsLayout()
        }
    }
    
    // MARK: - Swizzling
    private static var didSwizzle = false
    
    private static func swizzleLayoutSubviews() {
        guard !didSwizzle else { return }
        didSwizzle = true
        
        let original = class_getInstanceMethod(UIView.self, #selector(UIView.layoutSubviews))!
        let swizzled = class_getInstanceMethod(UIView.self, #selector(UIView.swizzled_layoutSubviews))!
        method_exchangeImplementations(original, swizzled)
    }
    
    @objc private func swizzled_layoutSubviews() {
        self.swizzled_layoutSubviews()
        
        if isCircular {
            self.layer.cornerRadius = self.bounds.height / 2
            self.clipsToBounds = true
        }
    }
}



