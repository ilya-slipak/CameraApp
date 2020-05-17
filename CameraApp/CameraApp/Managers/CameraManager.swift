//
//  CameraManager.swift
//  CameraApp
//
//  Created by Ilya Slipak on 17.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import UIKit
import AVFoundation


class CameraManager: NSObject {
    
    static let shared = CameraManager()
    
    
    // MARK: - Private Properties
    
    private var sessionQueue = DispatchQueue(label: "label.session.queue")
    private var captureSession: AVCaptureSession = AVCaptureSession()
    private var frontCamera: AVCaptureDevice?
    private var frontCameraInput: AVCaptureDeviceInput?
    private var rearCamera: AVCaptureDevice?
    private var rearCameraInput: AVCaptureDeviceInput?
    private var photoOutput: AVCapturePhotoOutput?
    private var movieOutput: AVCaptureMovieFileOutput?
    private var currentCameraPosition: CameraPosition?
    private var flashMode: AVCaptureDevice.FlashMode = .off
    private var previewView: PreviewView?
    

    // MARK: - Public Methods
            
    func prepareCaptureSession(_ completion: @escaping (Error?) -> Void) {
        
        sessionQueue.async {
            self.checkAccess(for: .video) { [weak self] isGranted in
                if isGranted {
                    self?.createCaptureSession(completion: completion)
                } else {
                    //TODO: Send message to UI layer "Access for use camera didn't granted"
                }
            }
        }
    }
    
    func startCaptureSession(with previewView: PreviewView) {
        
        sessionQueue.async {
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                previewView.session = self.captureSession
                self.previewView = previewView
            }
        }
    }
    
    func stopCaptureSession() {
        
        sessionQueue.async {
            self.captureSession.stopRunning()
            DispatchQueue.main.async {
                self.previewView?.session = nil
                self.previewView = nil
            }
        }
    }
    
    // MARK: - Action
    
    func captureImage() {
        
        guard let previewView = previewView else {
            return
        }
        
        var settings: AVCapturePhotoSettings
        switch currentCameraPosition {
        case .rear:
            settings = AVCapturePhotoSettings()
            settings.flashMode = flashMode
        default:
            settings = AVCapturePhotoSettings()
        }
        
        
        photoOutput?.capturePhoto(with: settings, delegate: previewView)
    }
    
    func startRecording() {
        
        guard let movieOutput = movieOutput, let previewView = previewView else {
            return
        }
        
        if movieOutput.isRecording == false {
            
            guard let connection = movieOutput.connection(with: .video) else {
                return
            }
            
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = currentVideoOrientation()
            }
            
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .auto
            }
            
            var device: AVCaptureDevice
            
            switch currentCameraPosition {
            case .front:
                guard  let frontCameraInput = frontCameraInput else {
                    return
                }
                
                device = frontCameraInput.device
            case .rear:
                guard  let rearCameraInput = rearCameraInput else {
                    return
                }
                
                device = rearCameraInput.device
            default:
                return
            }
            
            if device.isSmoothAutoFocusSupported {
                do {
                    try device.lockForConfiguration()
                    device.isSmoothAutoFocusEnabled = false
                    device.unlockForConfiguration()
                } catch {
                    print("Error setiing configuration: \(error)")
                }
            }
            
            guard let outputURL = videoURL() else {
                return
            }
            
            movieOutput.startRecording(to: outputURL, recordingDelegate: previewView)
        } else {
            stopRecording()
        }
    }
    
    func stopRecording() {
        
        guard let movieOutput = movieOutput else {
            return
        }
        
        if movieOutput.isRecording == true {
            movieOutput.stopRecording()
        }
    }
        
    func switchCameras() throws {
        
        captureSession.beginConfiguration()
        
        switch currentCameraPosition {
        case .front:
            try switchToRearCamera()
        case .rear:
            try switchToFrontCamera()
        case .none:
            throw CameraError.noCamerasAvailable
        }
        
        captureSession.commitConfiguration()
    }
    
    
    // MARK: - Private Methods
    
    private func checkAccess(for mediaType: AVMediaType, completion: @escaping(_ isGranted: Bool) -> Void) {
         
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
    
    private func createCaptureSession(completion: @escaping (Error?) -> Void) {
        
        do {
            captureSession.beginConfiguration()
            try configureCaptureDevices()
            try configureDeviceInputs()
            try configurePhotoOutput()
            try configureMovieOutput()
            captureSession.commitConfiguration()
            if captureSession.canSetSessionPreset(.hd1280x720) {
                captureSession.sessionPreset = .hd1280x720
            }
            DispatchQueue.main.async {
                completion(nil)
            }
        } catch {
            DispatchQueue.main.async {
                completion(error)
            }
        }
    }
    
    private func configureCaptureDevices() throws {
        
        let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
        
        let cameras = session.devices.compactMap { $0 }
        guard !cameras.isEmpty else { throw CameraError.noCamerasAvailable }
        
        for camera in cameras {
            if camera.position == .front {
                frontCamera = camera
            }
            
            if camera.position == .back {
                rearCamera = camera
                
                try camera.lockForConfiguration()
                camera.focusMode = .continuousAutoFocus
                camera.unlockForConfiguration()
            }
        }
    }
    
    private func configureDeviceInputs() throws {
        
        if let rearCamera = rearCamera {
            rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
            guard let rearCameraInput = rearCameraInput else {
                return
            }
            
            if captureSession.canAddInput(rearCameraInput) {
                captureSession.addInput(rearCameraInput)
            }
            
            currentCameraPosition = .rear
        } else if let frontCamera = frontCamera {
            frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
            guard let frontCameraInput = frontCameraInput else {
                return
            }
            if captureSession.canAddInput(frontCameraInput) {
                captureSession.addInput(frontCameraInput)
            } else {
                throw CameraError.inputsAreInvalid
            }
            currentCameraPosition = .front
        } else {
            throw CameraError.noCamerasAvailable
        }
    }
    
    private func configurePhotoOutput() throws {
        
        photoOutput = AVCapturePhotoOutput()
        guard let photoOutput = photoOutput else {
            return
        }
        photoOutput.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
    }
    
    private func configureMovieOutput() throws {
        
        movieOutput = AVCaptureMovieFileOutput()
                
        if let microphone = AVCaptureDevice.default(for: .audio) {
            do {
                let micInput = try AVCaptureDeviceInput(device: microphone)
                if captureSession.canAddInput(micInput) {
                    captureSession.addInput(micInput)
                }
            } catch {
                print("Error setting device audio input: \(error)")
            }
        }
        
        guard let movieOutput = movieOutput else {
            return
        }
        
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
        }
    }
    
    private func switchToFrontCamera() throws {
        
        guard let rearCameraInput = rearCameraInput, captureSession.inputs.contains(rearCameraInput),
            let frontCamera = frontCamera else { throw CameraError.invalidOperation }
        
        frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
        
        guard let frontCameraInput = frontCameraInput else {
            return
        }
        
        captureSession.removeInput(rearCameraInput)
        
        if captureSession.canAddInput(frontCameraInput) {
            captureSession.addInput(frontCameraInput)
            
            currentCameraPosition = .front
        } else {
            throw CameraError.invalidOperation
        }
    }
    
    private func switchToRearCamera() throws {
        
        guard let frontCameraInput = frontCameraInput, captureSession.inputs.contains(frontCameraInput),
            let rearCamera = rearCamera else {
                throw CameraError.invalidOperation
        }
        
        rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
        
        guard let rearCameraInput = rearCameraInput else {
            return
        }
        
        captureSession.removeInput(frontCameraInput)
        
        if captureSession.canAddInput(rearCameraInput) {
            captureSession.addInput(rearCameraInput)
            
            currentCameraPosition = .rear
        } else {
            throw CameraError.invalidOperation
        }
    }
    
    private func currentVideoOrientation() -> AVCaptureVideoOrientation {
        
        var orientation: AVCaptureVideoOrientation
        
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = AVCaptureVideoOrientation.portrait
        case .landscapeRight:
            orientation = AVCaptureVideoOrientation.landscapeLeft
        case .portraitUpsideDown:
            orientation = AVCaptureVideoOrientation.portraitUpsideDown
        default:
            orientation = AVCaptureVideoOrientation.landscapeRight
        }
        
        return orientation
    }
    
    private func videoURL() -> URL? {
        
        let paths = FileManager.default.temporaryDirectory
        
        let fileName = UUID().uuidString + ".mp4"
        let dataPath = paths.appendingPathComponent(fileName)
        
        return dataPath
    }
}
