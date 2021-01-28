//
//  GetCamera.swift
//  CameraApp
//
//  Created by Ilya Slipak on 28.01.2021.
//  Copyright © 2021 Ilya Slipak. All rights reserved.
//

import Foundation
import AVFoundation

protocol CameraRecivable {
    
}

extension CameraRecivable {
    
    func getCamera(position: AVCaptureDevice.Position) throws -> AVCaptureDevice {
        
        let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: position)
        
        let cameras = session.devices.compactMap { $0 }
        guard
            !cameras.isEmpty,
            let camera = cameras.first else {
            
            throw CameraError.noCamerasAvailable
        }
        
        try camera.lockForConfiguration()
        if camera.isFocusModeSupported(.continuousAutoFocus) {
            camera.focusMode = .continuousAutoFocus
        }
        
        if camera.isExposureModeSupported(.continuousAutoExposure) {
            camera.exposureMode = .continuousAutoExposure
        }
        
        if camera.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
            camera.whiteBalanceMode = .continuousAutoWhiteBalance
        }
        camera.unlockForConfiguration()
        
        return camera
    }
}
