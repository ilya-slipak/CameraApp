//
//  AlertShowable.swift
//  CameraApp
//
//  Created by Ilya Slipak on 24.01.2021.
//  Copyright © 2021 Ilya Slipak. All rights reserved.
//

import UIKit

protocol AlertPresentable: class {
    
    func showMessage(with message: String)
    func showSettingsAlert(with settingsType: SettingsAlertType)
}

extension AlertPresentable where Self: UIViewController {
    
    func showMessage(with message: String) {
        
        let alert = UIAlertController(title: message,
                                      message: nil,
                                      preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
    
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func showSettingsAlert(with settingsType: SettingsAlertType) {
        
        let alert = UIAlertController(title: "Permission required",
                                      message: settingsType.description,
                                      preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            
            let settingsUrl = URL(string: UIApplication.openSettingsURLString)
            if let url = settingsUrl {
                UIApplication.shared.open(url, options: [:]) { _ in }
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
}
