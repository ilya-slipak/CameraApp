//
//  CameraComponents.swift
//  CameraApp
//
//  Created by Ilya Slipak on 30.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import Foundation
import AVFoundation

final class CameraComponents {
    
    var captureSession: AVCaptureSession = AVCaptureSession()
    var camera: AVCaptureDevice?
    var cameraInput: AVCaptureDeviceInput?
    var microphone: AVCaptureDevice?
    var audioInput: AVCaptureDeviceInput?
    var photoOutput: AVCapturePhotoOutput?
    var movieOutput: AVCaptureMovieFileOutput?
    var currentCameraPosition: CameraPosition?
    var flashMode: AVCaptureDevice.FlashMode = .off
    var position: AVCaptureDevice.Position = .unspecified
    var sessionStatus: SessionSetupResult = .notAuthorized
}

struct CameraOrientation {
    
    var orientation: AVCaptureVideoOrientation
    var position: AVCaptureDevice.Position
}
