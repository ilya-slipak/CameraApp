//
//  ContentType.swift
//  CameraApp
//
//  Created by Ilya Slipak on 30.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import Foundation

enum ContentType {
    
    case image
    case video
    
    var mimeType : String {
        
        switch self {
        case .image:
            return ".jpg"
        case .video:
            return ".mp4"
        }
    }
}
