//
//  CameraManagerrr.swift
//  CameraApp
//
//  Created by Ilya Slipak on 28.01.2021.
//  Copyright © 2021 Ilya Slipak. All rights reserved.
//

//import AVFoundation
//import UIKit
//
//typealias ConfigureCameraCompletion = (SessionSetupResult)
//
//final class CameraConfigureManager: NSObject {
//    
//    
//    // MARK: - Public Properties
//    
//    var cameraComponents: CameraComponents
//    
//    
//    // MARK: - Private Properties
//    
//    private var sessionQueue = DispatchQueue(label: "label.session.queue", qos: .userInteractive)
//    private weak var delegate: (AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate)?
//    
//    init(with components: CameraComponents,
//         captureOutputDelegate: AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate) {
//        
//        cameraComponents = components
//        delegate = captureOutputDelegate
//        super.init()
//        setupErrorObserver()
//    }
//    
//    
//    // MARK: - Public Methods
//    
//    func createCaptureSession(position: AVCaptureDevice.Position) {
//        
//        checkAccess(for: .video)
//        
//        sessionQueue.async {
//            self.performCaptureSessionSetup(position: position)
//        }
//    }
//    
//    func startCaptureSession(completion: @escaping CameraCompletion) {
//        
//        if self.cameraComponents.captureSession.isRunning {
//            completion(self.cameraComponents.sessionStatus)
//        } else {
//            
//            sessionQueue.async {
//                
//                guard self.cameraComponents.sessionStatus == .authorized else {
//                    DispatchQueue.main.async {
//                        completion(self.cameraComponents.sessionStatus)
//                    }
//                    return
//                }
//                
//                self.cameraComponents.captureSession.startRunning()
//                DispatchQueue.main.async {
//                    completion(self.cameraComponents.sessionStatus)
//                }
//            }
//        }
//    }
//    
//    func stopCaptureSession(completion: @escaping () -> Void) {
//        
//        sessionQueue.async {
//            
//            self.cameraComponents.captureSession.stopRunning()
//            DispatchQueue.main.async {
//                completion()
//            }
//        }
//    }
//        
//    func getCurrentCaptureDevice() -> AVCaptureDevice? {
//        
//        return cameraComponents.camera
//    }
//    
//    func getCurrenFlashMode() -> AVCaptureDevice.FlashMode {
//        
//        return cameraComponents.flashMode
//    }
//    
//    func getCurrentCameraPosition() -> AVCaptureDevice.Position {
//        
//        return cameraComponents.position
//    }
//    
//    
//    // MARK: - Action Methods
//    
//    func focus(with focusMode: AVCaptureDevice.FocusMode,
//               exposureMode: AVCaptureDevice.ExposureMode,
//               at devicePoint: CGPoint,
//               monitorSubjectAreaChange: Bool) {
//        
//        guard let videoDevice = getCurrentCaptureDevice()
//            else {
//                return
//        }
//        
//        sessionQueue.async {
//            
//            do {
//                try videoDevice.lockForConfiguration()
//                if videoDevice.isFocusPointOfInterestSupported && videoDevice.isFocusModeSupported(focusMode) {
//                    videoDevice.focusPointOfInterest = devicePoint
//                    videoDevice.focusMode = focusMode
//                }
//                
//                if videoDevice.isExposurePointOfInterestSupported && videoDevice.isExposureModeSupported(exposureMode) {
//                    videoDevice.exposurePointOfInterest = devicePoint
//                    videoDevice.exposureMode = exposureMode
//                }
//
//                videoDevice.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
//                videoDevice.unlockForConfiguration()
//            } catch {
//                print("Could not lock device for configuration: \(error)")
//            }
//        }
//    }
//        
//    func captureImage(delegate: AVCapturePhotoCaptureDelegate) {
//                
//        let photoSettings = AVCapturePhotoSettings(format: [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)])
//        
//        if cameraComponents.photoOutput?.supportedFlashModes.contains(cameraComponents.flashMode) == true {
//            
//            photoSettings.flashMode = cameraComponents.flashMode
//        }
//        cameraComponents.photoOutput?.capturePhoto(with: photoSettings, delegate: delegate)
//    }
//            
//    func switchCamera() -> CameraOrientation {
//        
//        var cameraOrientation = CameraOrientation(orientation: .portrait, position: .unspecified)
//        
//        cameraComponents.captureSession.beginConfiguration()
//        
//        do {
//            
//            switch cameraComponents.position {
//            case .front:
//                try switchCamera(position: .back)
//            case .back:
//                try switchCamera(position: .front)
//            default:
//                break
//            }
//        } catch {
//            print("Failed to switch camera:", error.localizedDescription)
//        }
//        
//        cameraOrientation.position = cameraComponents.position
//        cameraComponents.captureSession.commitConfiguration()
//        
//        return cameraOrientation
//    }
//    
//    func flashAction() -> AVCaptureDevice.FlashMode {
//        
//        switch cameraComponents.flashMode {
//        case .auto:
//            cameraComponents.flashMode = .on
//        case .on:
//            cameraComponents.flashMode = .off
//        case .off:
//            cameraComponents.flashMode = .auto
//        @unknown default:
//            break
//        }
//        
//        return cameraComponents.flashMode
//    }
//    
//
//    // MARK: - Private Methods
//    
//    private func performCaptureSessionSetup(position: AVCaptureDevice.Position) {
//        
//        guard cameraComponents.sessionStatus == .authorized else {
//            return
//        }
//        
//        do {
//            cameraComponents.captureSession.beginConfiguration()
//            try configureCaptureDevices(position: position)
//            try configureDeviceInputs()
//            try configurePhotoOutput()
//            configureVideoDataOutput()
//            configureAudioDataOutput()
//            if cameraComponents.captureSession.canSetSessionPreset(.hd1280x720) {
//                cameraComponents.captureSession.sessionPreset = .hd1280x720
//            } else {
//                cameraComponents.captureSession.sessionPreset = .photo
//            }
//        } catch {
//            self.cameraComponents.sessionStatus = .configurationFailed
//        }
//        cameraComponents.captureSession.commitConfiguration()
//    }
//        
//    private func checkAccess(for mediaType: AVMediaType) {
//        
//        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
//        case .notDetermined:
//            sessionQueue.suspend()
//            AVCaptureDevice.requestAccess(for: .video) { [weak self] isGranted in
//                if !isGranted {
//                    self?.cameraComponents.sessionStatus = .notAuthorized
//                }
//                self?.sessionQueue.resume()
//            }
//        case .authorized:
//            return
//        default:
//            cameraComponents.sessionStatus = .notAuthorized
//        }
//    }
//    
//    private func configureCaptureDevices(position: AVCaptureDevice.Position) throws {
//        
//        let camera = try getCamera(position: position)
//        
//        if let camera = camera {
//            
//            cameraComponents.camera = camera
//            cameraComponents.position = position
//        }
//    }
//        
//    private func configureDeviceInputs() throws {
//        
//        if let camera = cameraComponents.camera {
//            cameraComponents.cameraInput = try AVCaptureDeviceInput(device: camera)
//            
//            guard
//                let cameraInput = cameraComponents.cameraInput,
//                cameraComponents.captureSession.canAddInput(cameraInput) else {
//                return
//            }
//            cameraComponents.captureSession.addInput(cameraInput)
//        }
//    }
//        
//    private func configurePhotoOutput() throws {
//        
//        cameraComponents.photoOutput = AVCapturePhotoOutput()
//        guard let photoOutput = cameraComponents.photoOutput else {
//            return
//        }
//        
//        if cameraComponents.captureSession.canAddOutput(photoOutput) {
//            cameraComponents.captureSession.addOutput(photoOutput)
//        }
//    }
//        
//    private func configureAudioDataOutput() {
//        
//        cameraComponents.microphone = AVCaptureDevice.default(.builtInMicrophone, for: .audio, position: .unspecified)
//        
//        guard let microphone = cameraComponents.microphone,
//            let audioInput = try? AVCaptureDeviceInput(device: microphone) else {
//                return
//        }
//        
//        if cameraComponents.captureSession.canAddInput(audioInput) {
//            cameraComponents.captureSession.addInput(audioInput)
//            cameraComponents.audioInput = audioInput
//        }
//    }
//    
//    private func configureVideoDataOutput() {
//                
//        cameraComponents.videoDataOutput = AVCaptureVideoDataOutput()
//
//        if cameraComponents.captureSession.canAddOutput(cameraComponents.videoDataOutput!) {
//            cameraComponents.videoDataOutput!.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
//            
//            cameraComponents.videoDataOutput?.setSampleBufferDelegate(delegate, queue: captureQueue)
//            cameraComponents.captureSession.addOutput(cameraComponents.videoDataOutput!)
//        }
//    }
//    
//    private func setupErrorObserver() {
//        
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(sessionRuntimeError),
//                                               name: .AVCaptureSessionRuntimeError,
//                                               object: cameraComponents.captureSession)
//    }
//    
//    @objc
//    private func sessionRuntimeError(notification: Notification) {
//        
//        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else {
//            return
//        }
//        
//        print("Capture session runtime error: \(error)")
//        // If media services were reset, and the last start succeeded, restart the session.
//        if error.code == .mediaServicesWereReset {
//            sessionQueue.async {
//                
//                if !self.cameraComponents.captureSession.isRunning {
//                    self.cameraComponents.captureSession.startRunning()
//                }
//            }
//        }
//    }
//    
//    
//    // MARK: - Private Action Methods
//    
//    private func getCamera(position: AVCaptureDevice.Position) throws -> AVCaptureDevice? {
//        
//        let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: position)
//        
//        let cameras = session.devices.compactMap { $0 }
//        guard !cameras.isEmpty else { throw CameraError.noCamerasAvailable }
//        
//        let camera = cameras.first { $0.position == position }
//        
//        guard let unwrappedCamera = camera else {
//            return nil
//        }
//        
//       try unwrappedCamera.lockForConfiguration()
//        if unwrappedCamera.isFocusModeSupported(.continuousAutoFocus) {
//            unwrappedCamera.focusMode = .continuousAutoFocus
//        }
//        
//        if unwrappedCamera.isExposureModeSupported(.continuousAutoExposure) {
//            unwrappedCamera.exposureMode = .continuousAutoExposure
//        }
//        
//        if unwrappedCamera.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
//            unwrappedCamera.whiteBalanceMode = .continuousAutoWhiteBalance
//        }
//        
//        unwrappedCamera.unlockForConfiguration()
//        
//        return unwrappedCamera
//    }
//        
//    private func switchCamera(position: AVCaptureDevice.Position) throws {
//        
//        guard let cameraInput = cameraComponents.cameraInput else {
//            throw CameraError.invalidOperation
//        }
//        
//        cameraComponents.captureSession.removeInput(cameraInput)
//
//        if let camera = try getCamera(position: position) {
//            let cameraInput = try AVCaptureDeviceInput(device: camera)
//            if cameraComponents.captureSession.canAddInput(cameraInput) {
//                cameraComponents.captureSession.addInput(cameraInput)
//                cameraComponents.position = position
//                cameraComponents.cameraInput = cameraInput
//                cameraComponents.camera = camera
//            }
//        }
//    }
//}
