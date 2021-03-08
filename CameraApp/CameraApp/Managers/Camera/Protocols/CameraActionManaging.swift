//
//  CameraActionProtocol.swift
//  CameraApp
//
//  Created by Ilya Slipak on 28.01.2021.
//  Copyright © 2021 Ilya Slipak. All rights reserved.
//

import AVFoundation

protocol CameraActionManaging {
    
    func captureImage(delegate: AVCapturePhotoCaptureDelegate)
    func startRecording(delegate: AVCaptureFileOutputRecordingDelegate)
    func stopRecording()
    func switchFlashMode() -> AVCaptureDevice.FlashMode
    func switchCamera(to camera: AVCaptureDevice) throws
    func startZoom(scale: CGFloat)
    func finishZoom(scale: CGFloat)
    func focus(with focusMode: AVCaptureDevice.FocusMode,
               exposureMode: AVCaptureDevice.ExposureMode,
               at devicePoint: CGPoint,
               monitorSubjectAreaChange: Bool)
}
