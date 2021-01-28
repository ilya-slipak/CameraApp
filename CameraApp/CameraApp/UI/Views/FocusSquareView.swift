//
//  FocusSquare.swift
//  CameraApp
//
//  Created by Ilya Slipak on 24.01.2021.
//  Copyright © 2021 Ilya Slipak. All rights reserved.
//

import UIKit

final class FocusSquareView: UIView {
    
    lazy var imageView: UIImageView = {
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "focusIcon")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        
        backgroundColor = .clear
        addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
    
    func animate(completion: @escaping(() -> Void)) {
        
        let animationOptions: UIView.AnimationOptions = .curveEaseInOut
        let keyframeAnimationOptions: UIView.KeyframeAnimationOptions = UIView.KeyframeAnimationOptions(rawValue: animationOptions.rawValue)
        self.alpha = 1
        UIView.animateKeyframes(withDuration: 2, delay: 0, options: [keyframeAnimationOptions]) {
            
            UIView.addKeyframe(withRelativeStartTime: 0.01, relativeDuration: 0.11) {
                self.transform = CGAffineTransform(scaleX: 1.333, y: 1.333)
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.12, relativeDuration: 0.11) {
                self.transform = CGAffineTransform(scaleX: 1, y: 1)
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.98, relativeDuration: 1) {
                self.alpha = 0
            }
            
        } completion: { isFinished in
            if isFinished {
                completion()
            }
        }
    }
    
    func stopAnimation() {
        
        layer.removeAllAnimations()
        removeFromSuperview()
    }
}
