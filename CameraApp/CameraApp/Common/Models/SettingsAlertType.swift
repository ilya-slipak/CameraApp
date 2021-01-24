//
//  SettingsAlertType.swift
//  CameraApp
//
//  Created by Ilya Slipak on 24.01.2021.
//  Copyright © 2021 Ilya Slipak. All rights reserved.
//

import Foundation

enum SettingsAlertType {
    
    case cameraAccess
    
    var description: String {
        
        return "The app need access to camera to take photos and videos"
    }
}
