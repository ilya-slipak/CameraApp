//
//  UiView+FromNib.swift
//  CameraApp
//
//  Created by Ilya Slipak on 30.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import UIKit

extension UIView {
    
    @discardableResult
    func makeFromNib<T: UIView>() -> T? {
        guard let contentView = Bundle(for: type(of: self)).loadNibNamed(String(describing: type(of: self)), owner: self, options: nil)?.first as? T else {
            // xib not loaded, or its top self is of the wrong type
            return nil
        }
        
        backgroundColor = .clear
        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
            contentView.leftAnchor.constraint(equalTo: leftAnchor, constant: 0),
            contentView.rightAnchor.constraint(equalTo: rightAnchor, constant: 0)
        ])
        
        return contentView
    }
}
