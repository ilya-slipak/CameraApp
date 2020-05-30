//
//  StorageManager.swift
//  CameraApp
//
//  Created by Ilya Slipak on 30.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import Foundation

class StorageManager {
    
    static var shared = StorageManager()
        
    func getURL(for content: ContentType) -> URL? {
        
        let paths = FileManager.default.temporaryDirectory
        
        let fileName = UUID().uuidString + content.mimeType
        let dataPath = paths.appendingPathComponent(fileName)
        
        return dataPath
    }
}
