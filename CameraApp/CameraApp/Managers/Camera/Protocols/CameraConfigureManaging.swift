//
//  CameraConfigureManagerProtocol.swift
//  CameraApp
//
//  Created by Ilya Slipak on 28.01.2021.
//  Copyright © 2021 Ilya Slipak. All rights reserved.
//

import AVFoundation

protocol CameraConfigureManaging {
    
    func createCaptureSession(position: AVCaptureDevice.Position)
    func startCaptureSession(completion: @escaping CameraSessionStatusCompletion)
    func stopCaptureSession(completion: @escaping () -> Void)
    func getCurrenFlashMode() -> AVCaptureDevice.FlashMode
    func getCurrentCameraPosition() -> AVCaptureDevice.Position
    func configureCameraDevice(at position: AVCaptureDevice.Position) throws -> AVCaptureDevice
}
