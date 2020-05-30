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
    func fromNib<T: UIView>() -> T? {
        guard let contentView = Bundle(for: type(of: self)).loadNibNamed(String(describing: type(of: self)), owner: self, options: nil)?.first as? T else {
            // xib not loaded, or its top self is of the wrong type
            return nil
        }
        self.backgroundColor = .clear
        self.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
            contentView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 0),
            contentView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 0)
            ])
        
        return contentView
    }
}
