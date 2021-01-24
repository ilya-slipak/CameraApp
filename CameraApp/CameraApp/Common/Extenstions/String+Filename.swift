//
//  String+Filename.swift
//  CameraApp
//
//  Created by Ilya Slipak on 24.01.2021.
//  Copyright © 2021 Ilya Slipak. All rights reserved.
//

import Foundation

extension String {
    
    static func makeFilename(contentType: ContentType) -> String {
        
        return UUID().uuidString.lowercased() + contentType.mimeType
    }
}
