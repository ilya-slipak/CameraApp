//
//  CameraConfigureManager.swift
//  CameraApp
//
//  Created by Ilya Slipak on 30.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import AVFoundation

typealias ConfigureCameraCompletion = (SessionSetupResult)

final class CameraConfigureManager {
    
    private var sessionQueue = DispatchQueue(label: "label.session.queue")
    var cameraComponents: CameraComponents
    
    init(with components: CameraComponents) {
        
        cameraComponents = components
        setupErrorObserver()
    }
    
    
    // MARK: - Public Methods
    
    func createCaptureSession() {
        
        checkAccess(for: .video)
        
        sessionQueue.async {
            self.performCaptureSessionSetup()
        }
    }
    
    func startCaptureSession(completion: @escaping CameraCompletion) {
        
        sessionQueue.async {
            
            guard self.cameraComponents.sessionStatus == .authorized else {
                DispatchQueue.main.async {
                    completion(self.cameraComponents.sessionStatus)
                }
                return
            }
            
            self.cameraComponents.captureSession.startRunning()
            DispatchQueue.main.async {
                completion(self.cameraComponents.sessionStatus)
            }
            
        }
    }
    
    func stopCaptureSession(completion: @escaping () -> Void) {
        
        sessionQueue.async {
            self.cameraComponents.captureSession.stopRunning()
            DispatchQueue.main.async {
                completion()
            }
        }
    }
        
    func getCurrentCaptureDevice() -> AVCaptureDevice? {
        
        switch cameraComponents.currentCameraPosition {
        case .front:
            guard let frontCamera = cameraComponents.frontCamera else {
                return nil
            }
            
            return frontCamera
        case .rear:
            guard let rearCamera = cameraComponents.rearCamera else {
                return nil
            }
            
            return rearCamera
        default:
            return nil
        }
    }
    
    func getCurrenFlashMode() -> AVCaptureDevice.FlashMode {
        
        return cameraComponents.flashMode
    }
    
    
    // MARK: - Private Methods
    
    private func performCaptureSessionSetup() {
        
        guard cameraComponents.sessionStatus == .authorized else {
            return
        }
        
        do {
            cameraComponents.captureSession.beginConfiguration()
            try configureCaptureDevices()
            try configureDeviceInputs()
            try configurePhotoOutput()
            try configureMovieOutput()
            if cameraComponents.captureSession.canSetSessionPreset(.hd1280x720) {
                cameraComponents.captureSession.sessionPreset = .hd1280x720
            }
        } catch {
            self.cameraComponents.sessionStatus = .configurationFailed
        }
        cameraComponents.captureSession.commitConfiguration()
    }
        
    private func checkAccess(for mediaType: AVMediaType) {
        
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { [weak self] isGranted in
                if !isGranted {
                    self?.cameraComponents.sessionStatus = .notAuthorized
                }
                self?.sessionQueue.resume()
            }
        case .authorized:
            return
        default:
            cameraComponents.sessionStatus = .notAuthorized
        }
    }
    
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
    
    private func setupErrorObserver() {
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionRuntimeError),
                                               name: .AVCaptureSessionRuntimeError,
                                               object: cameraComponents.captureSession)
    }
    
    @objc
    private func sessionRuntimeError(notification: Notification) {
        
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else {
            return
        }
        
        print("Capture session runtime error: \(error)")
        // If media services were reset, and the last start succeeded, restart the session.
        if error.code == .mediaServicesWereReset {
            sessionQueue.async {
                
                if !self.cameraComponents.captureSession.isRunning {
                    self.cameraComponents.captureSession.startRunning()
                }
            }
        }
    }
}
