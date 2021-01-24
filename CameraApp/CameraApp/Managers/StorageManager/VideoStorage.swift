//
//  VideoStorage.swift
//  CameraApp
//
//  Created by Ilya Slipak on 24.01.2021.
//  Copyright © 2021 Ilya Slipak. All rights reserved.
//

import Foundation

final class VideoStorage {
    
    static let shared = VideoStorage()
}

// MARK: - FileStorage

extension VideoStorage: FileStorage {
        
    var storageURL: URL? {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory: URL = paths[0]
        let dataPath = documentsDirectory.appendingPathComponent("Videos")
        
        if !FileManager.default.fileExists(atPath: dataPath.path) {
            
            do {
                try FileManager.default.createDirectory(at: dataPath,
                                                        withIntermediateDirectories: false,
                                                        attributes: nil)
            } catch {
                debugPrint(error.localizedDescription)
                return nil
            }
        }
        
        return dataPath
    }
}
