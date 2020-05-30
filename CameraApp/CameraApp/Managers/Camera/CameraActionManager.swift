//
//  CameraActionManager.swift
//  CameraApp
//
//  Created by Ilya Slipak on 30.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import UIKit
import AVFoundation

class CameraActionManager {
    
    
    // MARK: - Properties

    var cameraComponets: CameraComponents
    
    // MARK: - Public Methods
    
    init(with components: CameraComponents) {
        
        cameraComponets = components
    }
    
    func captureImage(previewView: PreviewView?,
                      delegate: AVCapturePhotoCaptureDelegate) {
        
        guard previewView != nil else {
            return
        }
        
        var settings: AVCapturePhotoSettings
        switch cameraComponets.currentCameraPosition {
        case .rear:
            settings = AVCapturePhotoSettings()
            settings.flashMode = cameraComponets.flashMode
        default:
            settings = AVCapturePhotoSettings()
        }
        
        cameraComponets.photoOutput?.capturePhoto(with: settings, delegate: delegate)
    }
    
    func startRecording(previewView: PreviewView?,
                        delegate: AVCaptureFileOutputRecordingDelegate) {

        guard let movieOutput = cameraComponets.movieOutput, previewView != nil else {
            return
        }
        
        if movieOutput.isRecording == false {
            
            guard let connection = movieOutput.connection(with: .video) else {
                return
            }
            
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = currentVideoOrientation()
            }
            
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .auto
            }
            
            var device: AVCaptureDevice
            
            switch cameraComponets.currentCameraPosition {
            case .front:
                guard  let frontCameraInput = cameraComponets.frontCameraInput else {
                    return
                }
                
                device = frontCameraInput.device
            case .rear:
                guard  let rearCameraInput = cameraComponets.rearCameraInput else {
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
            
            guard let outputURL = StorageManager.shared.getURL(for: .video) else {
                return
            }
            
            movieOutput.startRecording(to: outputURL, recordingDelegate: delegate)
        } else {
            stopRecording()
        }
    }
    
    func stopRecording() {
        
        guard let movieOutput = cameraComponets.movieOutput else {
            return
        }
        
        if movieOutput.isRecording == true {
            movieOutput.stopRecording()
        }
    }
        
    func switchCameras() throws {
        
        cameraComponets.captureSession.beginConfiguration()
        
        switch cameraComponets.currentCameraPosition {
        case .front:
            try switchToRearCamera()
        case .rear:
            try switchToFrontCamera()
        case .none:
            throw CameraError.noCamerasAvailable
        }
        
        cameraComponets.captureSession.commitConfiguration()
    }
    
    
    // MARK: Private Methods
    
    private func switchToFrontCamera() throws {
        
        guard
            let rearCameraInput = cameraComponets.rearCameraInput, cameraComponets.captureSession.inputs.contains(rearCameraInput),
            let frontCamera = cameraComponets.frontCamera else { throw CameraError.invalidOperation }
        
        cameraComponets.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
        
        guard let frontCameraInput = cameraComponets.frontCameraInput else {
            return
        }
        
        cameraComponets.captureSession.removeInput(rearCameraInput)
        
        if cameraComponets.captureSession.canAddInput(frontCameraInput) {
            cameraComponets.captureSession.addInput(frontCameraInput)
            
            cameraComponets.currentCameraPosition = .front
        } else {
            throw CameraError.invalidOperation
        }
    }
    
    private func switchToRearCamera() throws {
        
        guard
            let frontCameraInput = cameraComponets.frontCameraInput, cameraComponets.captureSession.inputs.contains(frontCameraInput),
            let rearCamera = cameraComponets.rearCamera else {
                throw CameraError.invalidOperation
        }
        
        cameraComponets.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
        
        guard let rearCameraInput = cameraComponets.rearCameraInput else {
            return
        }
        
        cameraComponets.captureSession.removeInput(frontCameraInput)
        
        if cameraComponets.captureSession.canAddInput(rearCameraInput) {
            cameraComponets.captureSession.addInput(rearCameraInput)
            
            cameraComponets.currentCameraPosition = .rear
        } else {
            throw CameraError.invalidOperation
        }
    }
    
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
