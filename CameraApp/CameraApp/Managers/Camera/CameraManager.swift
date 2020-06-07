//
//  CameraManager.swift
//  CameraApp
//
//  Created by Ilya Slipak on 17.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import AVFoundation
import UIKit


typealias CameraCompletion = (SessionSetupResult) -> Void
typealias PhotoCompletion = (Result<Data, Error>) -> Void
typealias VideoCompletion = (Result<URL, Error>) -> Void


class CameraManager: NSObject {
    
    static let shared = CameraManager()
    
    var photoCompletion: PhotoCompletion?
    var videoCompletion: VideoCompletion?
    
    // MARK: - Private Properties
    
    private var cameraActionManager: CameraActionManager!
    private var cameraConfigureManager: CameraConfigureManager!
    private var previewView: PreviewView?
    
    
    // MARK: - Public Methods
    
    func prepareCaptureSession() {
        
        let cameraComponents = CameraComponents()
        cameraActionManager = CameraActionManager(with: cameraComponents)
        cameraConfigureManager = CameraConfigureManager(with: cameraComponents)
        cameraConfigureManager.createCaptureSession()
    }
    
    func startCaptureSession(with previewView: PreviewView,
                             _ completion: @escaping CameraCompletion) {
        
        cameraConfigureManager.startCaptureSession { [weak self] sessionStatus in
            
            switch sessionStatus {
            case .authorized:
                previewView.session = self?.cameraConfigureManager.cameraComponents.captureSession
                self?.previewView = previewView
            default:
                completion(sessionStatus)
            }
        }
    }
    
    func stopCaptureSession() {
        
        cameraConfigureManager.stopCaptureSession { [weak self] in
            
            self?.previewView?.session = nil
            self?.previewView = nil
        }
    }
    
    func getCurrentCaptureDevice() -> AVCaptureDevice? {
        
        return cameraConfigureManager.getCurrentCaptureDevice()
    }
    
    func getCurrentFlashMode() -> AVCaptureDevice.FlashMode {
        
        return cameraConfigureManager.getCurrenFlashMode()
    }
    
    func captureImage(photoCompletion: @escaping PhotoCompletion) {
        
        cameraActionManager.captureImage(previewView: previewView, delegate: self)
        self.photoCompletion = photoCompletion
    }
    
    func startRecording(videoCompletion: @escaping VideoCompletion) {
        
        cameraActionManager.startRecording(previewView: previewView, delegate: self)
        self.videoCompletion = videoCompletion
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
