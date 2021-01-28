//
//  CameraActionProtocol.swift
//  CameraApp
//
//  Created by Ilya Slipak on 28.01.2021.
//  Copyright © 2021 Ilya Slipak. All rights reserved.
//

import Foundation
import AVFoundation

protocol CameraActionManagerProtocol {
    
    func captureImage(delegate: AVCapturePhotoCaptureDelegate)
    func startRecording(delegate: AVCaptureFileOutputRecordingDelegate)
    func stopRecording()
    func switchFlashMode() -> AVCaptureDevice.FlashMode
    func switchCamera() -> CameraOrientation
}
