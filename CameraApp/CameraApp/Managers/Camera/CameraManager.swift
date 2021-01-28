//
//  CameraManager.swift
//  CameraApp
//
//  Created by Ilya Slipak on 17.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import AVFoundation

typealias CameraCompletion = (SessionSetupResult) -> Void
typealias PhotoCompletion = (Result<Data, Error>) -> Void
typealias VideoCompletion = (Result<URL, Error>) -> Void

protocol CameraManagerProtocol {
    
    // MARK: - Properties
    
    var captureSession: AVCaptureSession { get }
    
    // MARK: - Methods
    
    func prepareCaptureSession(position: AVCaptureDevice.Position)
    func startCaptureSession(completion: @escaping CameraCompletion)
    func stopCaptureSession(completion: @escaping () -> Void)
    func getCurrentCaptureDevice() -> AVCaptureDevice?
    func getCurrentFlashMode() -> AVCaptureDevice.FlashMode
    func captureImage(photoCompletion: @escaping PhotoCompletion)
    func startRecording(videoCompletion: @escaping VideoCompletion)
    func stopRecording()
    func switchCamera()
    func switchFlashMode() -> AVCaptureDevice.FlashMode
    func focus(with focusMode: AVCaptureDevice.FocusMode,
               exposureMode: AVCaptureDevice.ExposureMode,
               at texturePoint: CGPoint,
               monitorSubjectAreaChange: Bool)
}

final class CameraManager: NSObject {

    // MARK: - Private Properties
    
    private var cameraComponents: CameraComponents = CameraComponents()
    private var cameraActionManager: CameraActionManagerProtocol!
    private var cameraConfigureManager: CameraConfigureManagerProtocol!
    private var photoCompletion: PhotoCompletion?
    private var videoCompletion: VideoCompletion?
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        
        if let error = error {
            photoCompletion?(.failure(error))
        } else if let imageData = photo.fileDataRepresentation() {
            photoCompletion?(.success(imageData))
        }
        
        photoCompletion = nil
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        
        if let error = error {
            videoCompletion?(.failure(error))
        } else {
            videoCompletion?(.success(outputFileURL))
        }
        
        videoCompletion = nil
    }
}

// MARK: - CameraManagerProtocol

extension CameraManager: CameraManagerProtocol {
    
    var captureSession: AVCaptureSession {
        
        return cameraComponents.captureSession
    }
    
    func prepareCaptureSession(position: AVCaptureDevice.Position) {
        
        cameraActionManager = CameraActionManager(with: cameraComponents)
        cameraConfigureManager = CameraConfigureManager(with: cameraComponents)
        cameraConfigureManager.createCaptureSession(position: position)
    }
    
    func startCaptureSession(completion: @escaping CameraCompletion) {
        
        cameraConfigureManager.startCaptureSession(completion: completion)
    }
    
    func stopCaptureSession(completion: @escaping () -> Void) {
        
        cameraConfigureManager.stopCaptureSession(completion: completion)
    }
    
    func getCurrentCaptureDevice() -> AVCaptureDevice? {
        
        return cameraConfigureManager.getCurrentCaptureDevice()
    }
    
    func getCurrentFlashMode() -> AVCaptureDevice.FlashMode {
        
        return cameraConfigureManager.getCurrenFlashMode()
    }
    
    func captureImage(photoCompletion: @escaping PhotoCompletion) {
        
        self.photoCompletion = photoCompletion
        cameraActionManager.captureImage(delegate: self)
    }
    
    func startRecording(videoCompletion: @escaping VideoCompletion) {
        
        self.videoCompletion = videoCompletion
        cameraActionManager.startRecording(delegate: self)
    }
    
    func stopRecording() {
        
        cameraActionManager.stopRecording()
    }
    
    func switchCamera() {
        
        _ = cameraActionManager.switchCamera()
    }
    
    func switchFlashMode() -> AVCaptureDevice.FlashMode {
        
        return cameraActionManager.switchFlashMode()
    }
    
    func focus(with focusMode: AVCaptureDevice.FocusMode,
               exposureMode: AVCaptureDevice.ExposureMode,
               at texturePoint: CGPoint,
               monitorSubjectAreaChange: Bool) {
        
        cameraConfigureManager.focus(with: focusMode,
                                     exposureMode: exposureMode,
                                     at: texturePoint,
                                     monitorSubjectAreaChange: monitorSubjectAreaChange)
    }
}
