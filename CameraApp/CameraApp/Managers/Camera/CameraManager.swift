//
//  CameraManager.swift
//  CameraApp
//
//  Created by Ilya Slipak on 17.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import AVFoundation

protocol CameraManagerDelegate: class {
    
    func didCaptureImage(imageData: Data)
    func didRecordVideo(recordedUrl: URL)
}

typealias CameraCompletion = (Result<Void, Error>) -> Void

class CameraManager: NSObject {
    
    static let shared = CameraManager()
    
    
    // MARK: - Private Properties
    
    private var sessionQueue = DispatchQueue(label: "label.session.queue")
    private var cameraActionManager: CameraActionManager!
    private var cameraConfigureManager: CameraConfigureManager!
    private var previewView: PreviewView?
    private weak var delegate: CameraManagerDelegate?
    

    // MARK: - Public Methods
            
    func prepareCaptureSession(_ completion: @escaping CameraCompletion) {
        
        let cameraComponents = CameraComponents()
        cameraActionManager = CameraActionManager(with: cameraComponents)
        cameraConfigureManager = CameraConfigureManager(with: cameraComponents)
        
        sessionQueue.async {
            self.checkAccess(for: .video) { [weak self] isGranted in
                if isGranted {
                    self?.cameraConfigureManager.createCaptureSession(completion: completion)
                } else {
                    //TODO: Send message to UI layer "Access for use camera didn't granted"
                }
            }
        }
    }
    
    func startCaptureSession(with previewView: PreviewView,
                             delegate: CameraManagerDelegate) {
        
        cameraConfigureManager.startCaptureSession(queue: sessionQueue) { [weak self] in
            previewView.session = self?.cameraConfigureManager.cameraComponents.captureSession
            self?.previewView = previewView
            self?.delegate = delegate
        }
    }
    
    func stopCaptureSession() {
        
        cameraConfigureManager.stopCaptureSession(queue: sessionQueue) { [weak self] in
            
            self?.previewView?.session = nil
            self?.previewView = nil
            self?.delegate = nil
        }
    }
    
    func captureImage() {
        
        cameraActionManager.captureImage(previewView: previewView, delegate: self)
    }
    
    func startRecording() {
        
        cameraActionManager.startRecording(previewView: previewView, delegate: self)
    }
    
    func stopRecoridng() {
        
        cameraActionManager.stopRecording()
    }
    
    func switchCameras() {
        
        do {
           try cameraActionManager.switchCameras()
        } catch {
            print("Failed to switch cameras:",error.localizedDescription)
        }
    }
    
    
    // MARK: - Private Methods
    
    private func checkAccess(for mediaType: AVMediaType,
                             completion: @escaping(_ isGranted: Bool) -> Void) {
         
         switch AVCaptureDevice.authorizationStatus(for: mediaType) {
         case .authorized:
             completion(true)
         case .notDetermined:
             AVCaptureDevice.requestAccess(for: mediaType, completionHandler: { granted in
                 completion(granted)
             })
         default:
             completion(false)
         }
     }
}


// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        
        guard let imageData = photo.fileDataRepresentation() else {
            return
        }
        delegate?.didCaptureImage(imageData: imageData)
    }
}


// MARK: - AVCaptureFileOutputRecordingDelegate

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        
        if error != nil {
            //TODO: Pass error to Controller
        } else {
            delegate?.didRecordVideo(recordedUrl: outputFileURL)
        }
    }
}
