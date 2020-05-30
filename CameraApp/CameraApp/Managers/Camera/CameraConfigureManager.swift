//
//  CameraConfigureManager.swift
//  CameraApp
//
//  Created by Ilya Slipak on 30.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import AVFoundation

class CameraConfigureManager {
    
    var cameraComponents: CameraComponents
    
    init(with components: CameraComponents) {
        
        cameraComponents = components
    }
    
    
    // MARK: - Public Methods
    
    func startCaptureSession(queue: DispatchQueue, completion: @escaping () -> Void) {
        
        queue.async {
            self.cameraComponents.captureSession.startRunning()
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    func stopCaptureSession(queue: DispatchQueue, completion: @escaping () -> Void) {
        
        queue.async {
            self.cameraComponents.captureSession.stopRunning()
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    func createCaptureSession(completion: @escaping CameraCompletion) {
        
        do {
            cameraComponents.captureSession.beginConfiguration()
            try configureCaptureDevices()
            try configureDeviceInputs()
            try configurePhotoOutput()
            try configureMovieOutput()
            cameraComponents.captureSession.commitConfiguration()
            if cameraComponents.captureSession.canSetSessionPreset(.hd1280x720) {
                cameraComponents.captureSession.sessionPreset = .hd1280x720
            }
            DispatchQueue.main.async {
                completion(.success(()))
            }
        } catch {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        }
    }
    
    
    // MARK: - Private Methods
    
    private func configureCaptureDevices() throws {
        
        let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
        
        let cameras = session.devices.compactMap { $0 }
        guard !cameras.isEmpty else { throw CameraError.noCamerasAvailable }
        
        for camera in cameras {
            if camera.position == .front {
                cameraComponents.frontCamera = camera
            }
            
            if camera.position == .back {
                cameraComponents.rearCamera = camera
                
                try camera.lockForConfiguration()
                camera.focusMode = .continuousAutoFocus
                camera.unlockForConfiguration()
            }
        }
    }
    
    private func configureDeviceInputs() throws {
        
        if let rearCamera = cameraComponents.rearCamera {
            cameraComponents.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
            guard let rearCameraInput = cameraComponents.rearCameraInput else {
                return
            }
            
            if cameraComponents.captureSession.canAddInput(rearCameraInput) {
                cameraComponents.captureSession.addInput(rearCameraInput)
            }
            
            cameraComponents.currentCameraPosition = .rear
        } else if let frontCamera = cameraComponents.frontCamera {
            cameraComponents.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
            guard let frontCameraInput = cameraComponents.frontCameraInput else {
                return
            }
            if cameraComponents.captureSession.canAddInput(frontCameraInput) {
                cameraComponents.captureSession.addInput(frontCameraInput)
            } else {
                throw CameraError.inputsAreInvalid
            }
            cameraComponents.currentCameraPosition = .front
        } else {
            throw CameraError.noCamerasAvailable
        }
    }
    
    private func configurePhotoOutput() throws {
        
        cameraComponents.photoOutput = AVCapturePhotoOutput()
        guard let photoOutput = cameraComponents.photoOutput else {
            return
        }
        photoOutput.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
        
        if cameraComponents.captureSession.canAddOutput(photoOutput) {
            cameraComponents.captureSession.addOutput(photoOutput)
        }
    }
    
    private func configureMovieOutput() throws {
        
        cameraComponents.movieOutput = AVCaptureMovieFileOutput()
        
        if let microphone = AVCaptureDevice.default(for: .audio) {
            do {
                let micInput = try AVCaptureDeviceInput(device: microphone)
                if cameraComponents.captureSession.canAddInput(micInput) {
                    cameraComponents.captureSession.addInput(micInput)
                }
            } catch {
                print("Error setting device audio input: \(error)")
            }
        }
        
        guard let movieOutput = cameraComponents.movieOutput else {
            return
        }
        
        if cameraComponents.captureSession.canAddOutput(movieOutput) {
            cameraComponents.captureSession.addOutput(movieOutput)
        }
    }
}
