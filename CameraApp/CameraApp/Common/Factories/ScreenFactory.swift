//
//  ScreenFactory.swift
//  CameraApp
//
//  Created by Ilya Slipak on 24.01.2021.
//  Copyright © 2021 Ilya Slipak. All rights reserved.
//

import UIKit

enum ScreenFactory {
        
    static func makePhotoPreviewScreen(with imageData: Data) -> PreviewPhotoViewController {
        
        let controller = UIStoryboard.makeController(name: "Main", identifier: "PreviewPhotoViewController") as! PreviewPhotoViewController
        controller.setup(imageData: imageData)
        
        return controller
    }
    
    static func makeVideoPreviewScreen(with videoURL: URL) -> PreviewVideoViewController {
        
        let controller = UIStoryboard.makeController(name: "Main", identifier: "PreviewVideoViewController") as! PreviewVideoViewController
        controller.setup(videoURL: videoURL)
        
        return controller
    }
}
