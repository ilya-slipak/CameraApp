//
//  FileStorageError.swift
//  CameraApp
//
//  Created by Ilya Slipak on 24.01.2021.
//  Copyright © 2021 Ilya Slipak. All rights reserved.
//

import Foundation

enum FileStorageError {
    
    case emptyStorage
    case emptyFile
}

// MARK: - Error

extension FileStorageError: Error {
    
    var localizedDescription: String {
        
        switch self {
        case .emptyStorage:
            return "Storage doesn't exist"
        case .emptyFile:
            return "There is no file by specified URL"
        }
    }
}
