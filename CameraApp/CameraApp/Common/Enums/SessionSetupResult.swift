//
//  SessionSetupResult.swift
//  CameraApp
//
//  Created by Ilya Slipak on 07.06.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import Foundation

enum SessionSetupResult {
    
    case authorized
    case notAuthorized
    case configurationFailed
    
    var message: String {
        
        switch self {
        case .configurationFailed:
            return "Failed to configure camera"
        default:
            return "Something went wrong"
        }
    }
}
