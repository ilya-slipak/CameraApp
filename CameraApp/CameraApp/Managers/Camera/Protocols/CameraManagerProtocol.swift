//
//  CameraConfigureManagerProtocol.swift
//  CameraApp
//
//  Created by Ilya Slipak on 28.01.2021.
//  Copyright © 2021 Ilya Slipak. All rights reserved.
//

import AVFoundation

protocol CameraManagerProtocol {
    
    // MARK: - Properties
    
    var captureSession: AVCaptureSession { get }
    
    // MARK: - Configure Methods
    
    func prepareCaptureSession(position: AVCaptureDevice.Position)
    func startCaptureSession(completion: @escaping CameraSessionStatusCompletion)
    func stopCaptureSession(completion: @escaping () -> Void)
    func getCurrentFlashMode() -> AVCaptureDevice.FlashMode
    
    // MARK: - Action Methods
    
    func captureImage(photoCompletion: @escaping PhotoCompletion)
    func startRecording(videoCompletion: @escaping VideoCompletion)
    func stopRecording()
    func switchCamera()
    func switchFlashMode() -> AVCaptureDevice.FlashMode
    func startZoom(scale: CGFloat)
    func finishZoom(scale: CGFloat)
    func focus(with focusMode: AVCaptureDevice.FocusMode,
               exposureMode: AVCaptureDevice.ExposureMode,
               at texturePoint: CGPoint,
               monitorSubjectAreaChange: Bool)
}
