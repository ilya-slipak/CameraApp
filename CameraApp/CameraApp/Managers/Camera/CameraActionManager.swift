//
//  CameraActionManager.swift
//  CameraApp
//
//  Created by Ilya Slipak on 30.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import UIKit
import AVFoundation

protocol CameraActionManagerProtocol {
    
    func captureImage(delegate: AVCapturePhotoCaptureDelegate)
    func startRecording(delegate: AVCaptureFileOutputRecordingDelegate)
    func stopRecording()
    func switchFlashMode() -> AVCaptureDevice.FlashMode
    func switchCamera() -> CameraOrientation
}

final class CameraActionManager {
    
    // MARK: - Private Properties

    private var cameraComponents: CameraComponents
    
    // MARK: - Lifecycle Methods
    
    init(with components: CameraComponents) {
        
        cameraComponents = components
    }
        
    // MARK: Private Methods
        
    private func switchCamera(to position: AVCaptureDevice.Position) throws {
        
        guard let cameraInput = cameraComponents.cameraInput else {
            throw CameraError.invalidOperation
        }
        
        cameraComponents.captureSession.beginConfiguration()
        cameraComponents.captureSession.removeInput(cameraInput)
        
        let newCamera = try getCamera(position: position)
        let newCameraInput = try AVCaptureDeviceInput(device: newCamera)
        if cameraComponents.captureSession.canAddInput(newCameraInput) {
            cameraComponents.captureSession.addInput(newCameraInput)
            cameraComponents.position = position
            cameraComponents.cameraInput = cameraInput
            cameraComponents.camera = newCamera
        }
        cameraComponents.captureSession.commitConfiguration()
    }
    //TODO: Refactor me
    private func getCamera(position: AVCaptureDevice.Position) throws -> AVCaptureDevice {
        
        let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                       mediaType: .video,
                                                       position: position)
        
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
        
        cameraComponents.captureSession.beginConfiguration()
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
        cameraComponents.captureSession.commitConfiguration()
        
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
