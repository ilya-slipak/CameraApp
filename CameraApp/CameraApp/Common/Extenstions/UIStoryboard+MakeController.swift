//
//  UIViewController+MakeController.swift
//  CameraApp
//
//  Created by Ilya Slipak on 24.01.2021.
//  Copyright © 2021 Ilya Slipak. All rights reserved.
//

import UIKit

extension UIStoryboard {
    
    static func makeController(name: String, identifier: String) -> UIViewController {
        
        return UIStoryboard(name: name, bundle: nil)
            .instantiateViewController(identifier: identifier)
    }
}
