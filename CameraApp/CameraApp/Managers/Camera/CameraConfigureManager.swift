//
//  CameraConfigureManager.swift
//  CameraApp
//
//  Created by Ilya Slipak on 30.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import AVFoundation

typealias SessionCameraCompletion = (SessionSetupResult)

final class CameraConfigureManager {
    
    // MARK: - Private Properties
    
    private var sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var cameraComponents: CameraComponents
    
    init(with components: CameraComponents) {
        
        cameraComponents = components
        setupErrorObserver()
    }
    
    // MARK: - Private Methods
    
    private func setupCaptureSession(position: AVCaptureDevice.Position) {
        
        guard cameraComponents.sessionStatus == .authorized else {
            return
        }
        
        do {
            cameraComponents.captureSession.beginConfiguration()
            try configureCameraInput(at: position)
            try configurePhotoOutput()
            try configureMovieOutput()
            if cameraComponents.captureSession.canSetSessionPreset(.hd1280x720) {
                cameraComponents.captureSession.sessionPreset = .hd1280x720
            }
        } catch {
            debugPrint("Error:", error)
            cameraComponents.sessionStatus = .configurationFailed
        }
        cameraComponents.captureSession.commitConfiguration()
    }
    
    private func checkAccess(for mediaType: AVMediaType) {
        
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { [weak self] isGranted in
                if isGranted {
                    self?.cameraComponents.sessionStatus = .authorized
                } else {
                    self?.cameraComponents.sessionStatus = .notAuthorized
                }
                self?.sessionQueue.resume()
            }
        case .authorized:
            cameraComponents.sessionStatus = .authorized
        default:
            cameraComponents.sessionStatus = .notAuthorized
        }
    }
    
    private func configureCameraInput(at position: AVCaptureDevice.Position) throws {
        
        let cameraDevice = try configureCameraDevice(at: position)
        let cameraInput = try AVCaptureDeviceInput(device: cameraDevice)
        
        guard cameraComponents.captureSession.canAddInput(cameraInput) else {
            throw CameraError.failedToAddCameraInput
        }
        
        cameraComponents.position = position
        cameraComponents.cameraInput = cameraInput
        cameraComponents.captureSession.addInput(cameraInput)
    }
            
    private func configurePhotoOutput() throws {
        
        let photoOutput = AVCapturePhotoOutput()
        let format = [AVVideoCodecKey: AVVideoCodecType.jpeg]
        let settings = [AVCapturePhotoSettings(format: format)]
        photoOutput.setPreparedPhotoSettingsArray(settings, completionHandler: nil)
        
        guard cameraComponents.captureSession.canAddOutput(photoOutput) else {
            throw CameraError.failedToAddPhotoOutput
        }
        
        cameraComponents.photoOutput = photoOutput
        cameraComponents.captureSession.addOutput(photoOutput)
    }
    
    private func configureMovieOutput() throws {
        
        let movieOutput = AVCaptureMovieFileOutput()
        
        if let microphone = AVCaptureDevice.default(for: .audio) {
            
            let micInput = try AVCaptureDeviceInput(device: microphone)
            
            guard cameraComponents.captureSession.canAddInput(micInput) else {
                throw CameraError.failedToAddAudioInput
            }
            
            cameraComponents.audioInput = micInput
            cameraComponents.captureSession.addInput(micInput)
        }
        
        guard cameraComponents.captureSession.canAddOutput(movieOutput) else {
            throw CameraError.failedToAddMovieOutput
        }
        
        cameraComponents.movieOutput = movieOutput
        cameraComponents.captureSession.addOutput(movieOutput)
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

// MARK: - CameraConfigureManagerProtocol

extension CameraConfigureManager: CameraConfigureManagerProtocol {

    func createCaptureSession(position: AVCaptureDevice.Position) {
        
        checkAccess(for: .video)
        sessionQueue.async {
            self.setupCaptureSession(position: position)
        }
    }
    
    func startCaptureSession(completion: @escaping CameraSessionStatusCompletion) {
        
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
    
    func getCurrenFlashMode() -> AVCaptureDevice.FlashMode {
        
        return cameraComponents.cameraFlashMode
    }
    
    func getCurrentCameraPosition() -> AVCaptureDevice.Position {
        
        return cameraComponents.position
    }
        
    func configureCameraDevice(at position: AVCaptureDevice.Position) throws -> AVCaptureDevice {
        
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
}
