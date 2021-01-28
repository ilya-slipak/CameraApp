//
//  CameraActionManager.swift
//  CameraApp
//
//  Created by Ilya Slipak on 30.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import UIKit
import AVFoundation

final class CameraActionManager: CameraRecivable {
    
    // MARK: - Private Properties
    
    private var cameraComponents: CameraComponents
    
    // MARK: - Lifecycle Methods
    
    init(with components: CameraComponents) {
        
        cameraComponents = components
    }
    
    // MARK: Private Methods
    
    private func switchCamera(to position: AVCaptureDevice.Position) throws {
        
        guard let oldCameraInput = cameraComponents.cameraInput else {
            throw CameraError.invalidOperation
        }
        let newCameraDevice = try getCamera(position: position)
        cameraComponents.captureSession.beginConfiguration()
        cameraComponents.captureSession.removeInput(oldCameraInput)
        
        let newCameraInput = try AVCaptureDeviceInput(device: newCameraDevice)
        if cameraComponents.captureSession.canAddInput(newCameraInput) {
            cameraComponents.captureSession.addInput(newCameraInput)
            cameraComponents.position = position
            cameraComponents.cameraInput = newCameraInput
        }
        cameraComponents.captureSession.commitConfiguration()
    }
    
    //TODO: Will be added soon
    private func currentVideoOrientation() -> AVCaptureVideoOrientation {
        
        var orientation: AVCaptureVideoOrientation
        
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = AVCaptureVideoOrientation.portrait
        case .landscapeRight:
            orientation = AVCaptureVideoOrientation.landscapeLeft
        case .portraitUpsideDown:
            orientation = AVCaptureVideoOrientation.portraitUpsideDown
        default:
            orientation = AVCaptureVideoOrientation.landscapeRight
        }
        
        return orientation
    }
}

// MARK: - CameraActionManagerProtocol

extension CameraActionManager: CameraActionManagerProtocol {
    
    func captureImage(delegate: AVCapturePhotoCaptureDelegate) {
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = cameraComponents.flashMode
        cameraComponents.photoOutput?.capturePhoto(with: settings, delegate: delegate)
    }
    
    func startRecording(delegate: AVCaptureFileOutputRecordingDelegate) {
        
        guard let movieOutput = cameraComponents.movieOutput else {
            return
        }
        
        if movieOutput.isRecording == false {
            
            guard let connection = movieOutput.connection(with: .video) else {
                return
            }
            
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .auto
            }
            
            var device: AVCaptureDevice
            
            guard  let frontCameraInput = cameraComponents.cameraInput else {
                return
            }
            
            device = frontCameraInput.device
            
            if device.isSmoothAutoFocusSupported {
                do {
                    try device.lockForConfiguration()
                    device.isSmoothAutoFocusEnabled = false
                    device.unlockForConfiguration()
                } catch {
                    print("Error setiing configuration: \(error)")
                }
            }
            
            let fileName = String.makeFilename(contentType: .video)
            guard let videoUrl = try? VideoStorage.shared.getFileURL(fileName: fileName) else {
                return
            }
            
            movieOutput.startRecording(to: videoUrl, recordingDelegate: delegate)
        } else {
            stopRecording()
        }
    }
    
    func stopRecording() {
        
        guard let movieOutput = cameraComponents.movieOutput else {
            return
        }
        
        if movieOutput.isRecording {
            movieOutput.stopRecording()
        }
    }
    
    func switchCamera() -> CameraOrientation {
        
        var cameraOrientation = CameraOrientation(orientation: .portrait, position: .unspecified)
        do {
            
            switch cameraComponents.position {
            case .front:
                try switchCamera(to: .back)
            case .back:
                try switchCamera(to: .front)
            default:
                break
            }
        } catch {
            print("Failed to switch camera:", error.localizedDescription)
        }
        
        cameraOrientation.position = cameraComponents.position
        
        return cameraOrientation
    }
    
    func switchFlashMode() -> AVCaptureDevice.FlashMode {
        
        switch cameraComponents.flashMode {
        case .auto:
            cameraComponents.flashMode = .on
        case .on:
            cameraComponents.flashMode = .off
        case .off:
            cameraComponents.flashMode = .auto
        @unknown default:
            break
        }
        return cameraComponents.flashMode
    }
}
