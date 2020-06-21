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

final class CameraManager: NSObject {
    

    // MARK: - Public Properties
    
    var captureSession: AVCaptureSession {
        
        return cameraConfigureManager.cameraComponents.captureSession
    }
        
    // MARK: - Private Properties
    
    private var cameraActionManager: CameraActionManager!
    private var cameraConfigureManager: CameraConfigureManager!
    private var photoCompletion: PhotoCompletion?
    private var videoCompletion: VideoCompletion?
    
    
    // MARK: - Public Methods
    
    func prepareCaptureSession() {
        
        let cameraComponents = CameraComponents()
        cameraActionManager = CameraActionManager(with: cameraComponents)
        cameraConfigureManager = CameraConfigureManager(with: cameraComponents)
        cameraConfigureManager.createCaptureSession()
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
    
    func switchCameras() {
        
        do {
            try cameraActionManager.switchCameras()
        } catch {
            print("Failed to switch cameras:", error.localizedDescription)
        }
    }
    
    func flashAction() -> AVCaptureDevice.FlashMode {
        
        return cameraActionManager.flashAction()
    }
}


// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
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
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        if let error = error {
            videoCompletion?(.failure(error))
        } else {
            videoCompletion?(.success(outputFileURL))
        }
        
        videoCompletion = nil
    }
}
