//
//  CameraActionManager.swift
//  CameraApp
//
//  Created by Ilya Slipak on 30.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import AVFoundation

final class CameraActionManager {
    
    // MARK: - Private Properties
    
    private var sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var cameraComponents: CameraComponents
    private var newScaleFactor: CGFloat = 0
    private var zoomFactor: CGFloat = 1.0
    
    // MARK: - Lifecycle Methods
    
    init(with components: CameraComponents) {
        
        cameraComponents = components
    }
    
    private func minMaxZoom(factor: CGFloat, device: AVCaptureDevice) -> CGFloat {
        return min(max(factor, 1.0), device.activeFormat.videoMaxZoomFactor)
    }
    
    private func performZoom(factor: CGFloat, camera: AVCaptureDevice) {
        
        do {
            try camera.lockForConfiguration()
            camera.videoZoomFactor = factor
            camera.unlockForConfiguration()
        } catch {
            debugPrint(error)
        }
    }
}

// MARK: - CameraActionManagerProtocol

extension CameraActionManager: CameraActionManagerProtocol {
    
    func captureImage(delegate: AVCapturePhotoCaptureDelegate) {
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = cameraComponents.cameraFlashMode
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
            
            guard let cameraInput = cameraComponents.cameraInput else {
                return
            }
            
            let device = cameraInput.device
            
            if device.isSmoothAutoFocusSupported {
                do {
                    try device.lockForConfiguration()
                    device.isSmoothAutoFocusEnabled = false
                    device.unlockForConfiguration()
                } catch {
                    print("Error during setup device configuration: \(error)")
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
    
    func switchCamera(to camera: AVCaptureDevice) throws {
        
        guard let oldCameraInput = cameraComponents.cameraInput else {
            throw CameraError.invalidOperation
        }
        
        let newCameraInput = try AVCaptureDeviceInput(device: camera)
        cameraComponents.captureSession.beginConfiguration()
        cameraComponents.captureSession.removeInput(oldCameraInput)
        
        guard cameraComponents.captureSession.canAddInput(newCameraInput) else {
            cameraComponents.captureSession.commitConfiguration()
            throw CameraError.failedToAddCameraInput
        }
        
        zoomFactor = 1
        newScaleFactor = 0
        cameraComponents.position = camera.position
        cameraComponents.cameraInput = newCameraInput
        cameraComponents.captureSession.addInput(newCameraInput)
        cameraComponents.captureSession.commitConfiguration()
    }
    
    func startZoom(scale: CGFloat) {
        
        guard let camera = cameraComponents.cameraInput?.device else {
            return
        }
 
        newScaleFactor = minMaxZoom(factor: scale * zoomFactor, device: camera)
        performZoom(factor: newScaleFactor, camera: camera)
    }
    func finishZoom(scale: CGFloat) {
        
        guard let camera = cameraComponents.cameraInput?.device else {
            return
        }

        zoomFactor = minMaxZoom(factor: newScaleFactor, device: camera)
        performZoom(factor: zoomFactor, camera: camera)
    }
    
    func focus(with focusMode: AVCaptureDevice.FocusMode,
               exposureMode: AVCaptureDevice.ExposureMode,
               at devicePoint: CGPoint,
               monitorSubjectAreaChange: Bool) {
        
        guard
            let camera = cameraComponents.cameraInput?.device else {
            return
        }
        
        sessionQueue.async {
            
            do {
                try camera.lockForConfiguration()
                if camera.isFocusPointOfInterestSupported && camera.isFocusModeSupported(focusMode) {
                    camera.focusPointOfInterest = devicePoint
                    camera.focusMode = focusMode
                }
                
                if camera.isExposurePointOfInterestSupported && camera.isExposureModeSupported(exposureMode) {
                    camera.exposurePointOfInterest = devicePoint
                    camera.exposureMode = exposureMode
                }
                
                camera.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                camera.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
    
    func switchFlashMode() -> AVCaptureDevice.FlashMode {
        
        switch cameraComponents.cameraFlashMode {
        
        case .auto:
            cameraComponents.cameraFlashMode = .on
        case .on:
            cameraComponents.cameraFlashMode = .off
        case .off:
            cameraComponents.cameraFlashMode = .auto
        default:
            break
        }
        
        return cameraComponents.cameraFlashMode
    }
}
