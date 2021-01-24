//
//  FileStorage.swift
//  CameraApp
//
//  Created by Ilya Slipak on 24.01.2021.
//  Copyright © 2021 Ilya Slipak. All rights reserved.
//

import Foundation

protocol FileStorage {
    
    // MARK: - Properties
    
    var storageURL: URL? { get }
}

extension FileStorage {
    
    func saveFile(data: Data, fileName: String) throws -> URL {
        
        guard let storageURL = storageURL else {
            throw FileStorageError.emptyStorage
        }
        
        let fileURL = storageURL.appendingPathComponent(fileName)
        let isExist = fileExists(atPath: fileURL.path)
        if !isExist {
            try data.write(to: fileURL)
        }
        
        return fileURL
    }
    
    func getFileURL(fileName: String) throws -> URL {
        
        guard let storageURL = storageURL else {
            throw FileStorageError.emptyStorage
        }
        
        let fileURL = storageURL.appendingPathComponent(fileName)

        return fileURL
    }
    
    func deleteFile(_ path: String) {
        
        let isExist = fileExists(atPath: path)
        if isExist {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                debugPrint("Failed to delete file:",error.localizedDescription)
            }
        }
    }
    
    func fileExists(atPath path: String) -> Bool {
        
        return FileManager.default.fileExists(atPath: path)
    }
    
    func removeAll() {
        
        guard let storageURL = storageURL else {
            let error = FileStorageError.emptyStorage
            debugPrint("Error:", error.localizedDescription)
            return
        }
        
        deleteFile(storageURL.absoluteString)
    }
}
