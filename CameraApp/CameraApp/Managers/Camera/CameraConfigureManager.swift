//
//  CameraConfigureManager.swift
//  CameraApp
//
//  Created by Ilya Slipak on 30.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import AVFoundation

typealias SessionCameraCompletion = (SessionSetupResult)

protocol CameraConfigureManagerProtocol {
    
    func createCaptureSession(position: AVCaptureDevice.Position)
    func startCaptureSession(completion: @escaping CameraCompletion)
    func stopCaptureSession(completion: @escaping () -> Void)
    func getCurrenFlashMode() -> AVCaptureDevice.FlashMode
    func getCurrentCameraPosition() -> AVCaptureDevice.Position
    func focus(with focusMode: AVCaptureDevice.FocusMode,
               exposureMode: AVCaptureDevice.ExposureMode,
               at devicePoint: CGPoint,
               monitorSubjectAreaChange: Bool)
}

final class CameraConfigureManager: CameraRecivable {
    
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
            let camera =  try configureCaptureDevice(position: position)
            try configureDeviceInput(cameraDevice: camera)
            try configurePhotoOutput()
            try configureMovieOutput()
            if cameraComponents.captureSession.canSetSessionPreset(.hd1280x720) {
                cameraComponents.captureSession.sessionPreset = .hd1280x720
            }
        } catch {
            debugPrint("Error:", error)
            self.cameraComponents.sessionStatus = .configurationFailed
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
    
    private func configureCaptureDevice(position: AVCaptureDevice.Position) throws -> AVCaptureDevice {
        
        cameraComponents.position = position
        return try getCamera(position: position)
    }
    
    private func configureDeviceInput(cameraDevice: AVCaptureDevice) throws {
        
        cameraComponents.cameraInput = try AVCaptureDeviceInput(device: cameraDevice)
        
        guard
            let cameraInput = cameraComponents.cameraInput,
            cameraComponents.captureSession.canAddInput(cameraInput) else {
            return
        }
        cameraComponents.captureSession.addInput(cameraInput)
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

// MARK: - CameraConfigureManagerProtocol

extension CameraConfigureManager: CameraConfigureManagerProtocol {
    
    func createCaptureSession(position: AVCaptureDevice.Position) {
        
        checkAccess(for: .video)
        sessionQueue.async {
            self.setupCaptureSession(position: position)
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
    
    func getCurrenFlashMode() -> AVCaptureDevice.FlashMode {
        
        return cameraComponents.flashMode
    }
    
    func getCurrentCameraPosition() -> AVCaptureDevice.Position {
        
        return cameraComponents.position
    }
    
    func focus(with focusMode: AVCaptureDevice.FocusMode,
               exposureMode: AVCaptureDevice.ExposureMode,
               at devicePoint: CGPoint,
               monitorSubjectAreaChange: Bool) {
        
        guard let videoDevice = cameraComponents.cameraInput?.device
        else {
            return
        }
        
        sessionQueue.async {
            
            do {
                try videoDevice.lockForConfiguration()
                if videoDevice.isFocusPointOfInterestSupported && videoDevice.isFocusModeSupported(focusMode) {
                    videoDevice.focusPointOfInterest = devicePoint
                    videoDevice.focusMode = focusMode
                }
                
                if videoDevice.isExposurePointOfInterestSupported && videoDevice.isExposureModeSupported(exposureMode) {
                    videoDevice.exposurePointOfInterest = devicePoint
                    videoDevice.exposureMode = exposureMode
                }
                
                videoDevice.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                videoDevice.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
}
