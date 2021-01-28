//
//  CameraConfigureManagerProtocol.swift
//  CameraApp
//
//  Created by Ilya Slipak on 28.01.2021.
//  Copyright © 2021 Ilya Slipak. All rights reserved.
//

import Foundation
import AVFoundation

protocol CameraManagerProtocol {
    
    // MARK: - Properties
    
    var captureSession: AVCaptureSession { get }
    
    // MARK: - Methods
    
    func prepareCaptureSession(position: AVCaptureDevice.Position)
    func startCaptureSession(completion: @escaping CameraCompletion)
    func stopCaptureSession(completion: @escaping () -> Void)
    func getCurrentCaptureDevice() -> AVCaptureDevice?
    func getCurrentFlashMode() -> AVCaptureDevice.FlashMode
    func captureImage(photoCompletion: @escaping PhotoCompletion)
    func startRecording(videoCompletion: @escaping VideoCompletion)
    func stopRecording()
    func switchCamera()
    func switchFlashMode() -> AVCaptureDevice.FlashMode
    func focus(with focusMode: AVCaptureDevice.FocusMode,
               exposureMode: AVCaptureDevice.ExposureMode,
               at texturePoint: CGPoint,
               monitorSubjectAreaChange: Bool)
}
