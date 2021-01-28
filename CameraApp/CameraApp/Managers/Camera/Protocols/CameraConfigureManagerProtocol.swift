//
//  CameraConfigureManagerProtocol.swift
//  CameraApp
//
//  Created by Ilya Slipak on 28.01.2021.
//  Copyright © 2021 Ilya Slipak. All rights reserved.
//

import Foundation
import AVFoundation

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
