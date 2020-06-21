//
//  CameraActionManager.swift
//  CameraApp
//
//  Created by Ilya Slipak on 30.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import UIKit
import AVFoundation

final class CameraActionManager {
    
    
    // MARK: - Properties

    var cameraComponents: CameraComponents
    
    
    // MARK: - Public Methods
    
    init(with components: CameraComponents) {
        
        cameraComponents = components
    }
    
    func captureImage(delegate: AVCapturePhotoCaptureDelegate) {
        
        var settings: AVCapturePhotoSettings
        switch cameraComponents.currentCameraPosition {
        case .rear:
            settings = AVCapturePhotoSettings()
            settings.flashMode = cameraComponents.flashMode
        default:
            settings = AVCapturePhotoSettings()
        }
        
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
            
            switch cameraComponents.currentCameraPosition {
            case .front:
                guard  let frontCameraInput = cameraComponents.frontCameraInput else {
                    return
                }
                
                device = frontCameraInput.device
            case .rear:
                guard  let rearCameraInput = cameraComponents.rearCameraInput else {
                    return
                }
                
                device = rearCameraInput.device
            default:
                return
            }
            
            if device.isSmoothAutoFocusSupported {
                do {
                    try device.lockForConfiguration()
                    device.isSmoothAutoFocusEnabled = false
                    device.unlockForConfiguration()
                } catch {
                    print("Error setiing configuration: \(error)")
                }
            }
            
            guard let videoUrl = StorageManager.shared.getURL(for: .video) else {
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
        
        if movieOutput.isRecording == true {
            movieOutput.stopRecording()
        }
    }
        
    func switchCameras() throws {
        
        cameraComponents.captureSession.beginConfiguration()
        
        switch cameraComponents.currentCameraPosition {
        case .front:
            try switchToRearCamera()
        case .rear:
            try switchToFrontCamera()
        case .none:
            throw CameraError.noCamerasAvailable
        }
        
        cameraComponents.captureSession.commitConfiguration()
    }
    
    func flashAction() -> AVCaptureDevice.FlashMode {
        
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
    
    
    // MARK: Private Methods
        
    private func switchToFrontCamera() throws {
        
        guard
            let rearCameraInput = cameraComponents.rearCameraInput, cameraComponents.captureSession.inputs.contains(rearCameraInput),
            let frontCamera = cameraComponents.frontCamera else { throw CameraError.invalidOperation }
        
        cameraComponents.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
        
        guard let frontCameraInput = cameraComponents.frontCameraInput else {
            return
        }
        
        cameraComponents.captureSession.removeInput(rearCameraInput)
        
        if cameraComponents.captureSession.canAddInput(frontCameraInput) {
            cameraComponents.captureSession.addInput(frontCameraInput)
            
            cameraComponents.currentCameraPosition = .front
        } else {
            throw CameraError.invalidOperation
        }
    }
    
    private func switchToRearCamera() throws {
        
        guard
            let frontCameraInput = cameraComponents.frontCameraInput, cameraComponents.captureSession.inputs.contains(frontCameraInput),
            let rearCamera = cameraComponents.rearCamera else {
                throw CameraError.invalidOperation
        }
        
        cameraComponents.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
        
        guard let rearCameraInput = cameraComponents.rearCameraInput else {
            return
        }
        
        cameraComponents.captureSession.removeInput(frontCameraInput)
        
        if cameraComponents.captureSession.canAddInput(rearCameraInput) {
            cameraComponents.captureSession.addInput(rearCameraInput)
            
            cameraComponents.currentCameraPosition = .rear
        } else {
            throw CameraError.invalidOperation
        }
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
