//
//  CameraManager.swift
//  CameraApp
//
//  Created by Ilya Slipak on 17.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import AVFoundation

// MARK: - Typealias

typealias CameraSessionStatusCompletion = (SessionSetupResult) -> Void
typealias PhotoCompletion = (Result<Data, Error>) -> Void
typealias VideoCompletion = (Result<URL, Error>) -> Void

final class CameraManager: NSObject {
    
    // MARK: - Private Properties
    
    private var cameraComponents: CameraComponents = CameraComponents()
    private var cameraActionManager: CameraActionManagerProtocol!
    private var cameraConfigureManager: CameraConfigureManagerProtocol!
    private var photoCompletion: PhotoCompletion?
    private var videoCompletion: VideoCompletion?
    
    // MARK: - Private Methods
    
    private func switchCamera(to position: AVCaptureDevice.Position) {
        
        do {
            let camera = try cameraConfigureManager.configureCameraDevice(at: position)
            try cameraActionManager.switchCamera(to: camera)
        } catch let error as CameraError {
            print("Failed to get camera:", error)
        } catch { return }
    }
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
    
    // MARK: - Properties
    
    var captureSession: AVCaptureSession {
        
        return cameraComponents.captureSession
    }
    
    // MARK: - Configure Methods
    
    func prepareCaptureSession(position: AVCaptureDevice.Position) {
        
        cameraActionManager = CameraActionManager(with: cameraComponents)
        cameraConfigureManager = CameraConfigureManager(with: cameraComponents)
        cameraConfigureManager.createCaptureSession(position: position)
    }
    
    func startCaptureSession(completion: @escaping CameraSessionStatusCompletion) {
        
        cameraConfigureManager.startCaptureSession(completion: completion)
    }
    
    func stopCaptureSession(completion: @escaping () -> Void) {
        
        cameraConfigureManager.stopCaptureSession(completion: completion)
    }
        
    func getCurrentFlashMode() -> AVCaptureDevice.FlashMode {
        
        return cameraConfigureManager.getCurrenFlashMode()
    }
    
    // MARK: - Action Methods
    
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
        
        switch cameraComponents.position {
        case .front:
            switchCamera(to: .back)
        case .back:
            switchCamera(to: .front)
        default:
            break
        }
    }
    
    func switchFlashMode() -> AVCaptureDevice.FlashMode {
        
        return cameraActionManager.switchFlashMode()
    }
    
    func startZoom(scale: CGFloat) {
        
        cameraActionManager.startZoom(scale: scale)
    }
    
    func finishZoom(scale: CGFloat) {
        
        cameraActionManager.finishZoom(scale: scale)
    }
    
    func focus(with focusMode: AVCaptureDevice.FocusMode,
               exposureMode: AVCaptureDevice.ExposureMode,
               at texturePoint: CGPoint,
               monitorSubjectAreaChange: Bool) {
        
        cameraActionManager.focus(with: focusMode,
                                  exposureMode: exposureMode,
                                  at: texturePoint,
                                  monitorSubjectAreaChange: monitorSubjectAreaChange)
    }
}
