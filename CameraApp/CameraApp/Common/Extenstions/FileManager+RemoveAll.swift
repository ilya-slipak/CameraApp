//
//  FileManager+RemoveAll.swift
//  CameraApp
//
//  Created by Ilya Slipak on 24.01.2021.
//  Copyright © 2021 Ilya Slipak. All rights reserved.
//

import Foundation

extension FileManager {
    
    func removeAll()  {
        
        VideoStorage.shared.removeAll()
    }
}
