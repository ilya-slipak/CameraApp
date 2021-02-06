//
//  CameraComponents.swift
//  CameraApp
//
//  Created by Ilya Slipak on 30.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import AVFoundation

final class CameraComponents {
    
    var captureSession: AVCaptureSession = AVCaptureSession()
    var cameraInput: AVCaptureDeviceInput?
    var audioInput: AVCaptureDeviceInput?
    var photoOutput: AVCapturePhotoOutput?
    var movieOutput: AVCaptureMovieFileOutput?
    var cameraFlashMode: AVCaptureDevice.FlashMode = .off
    var position: AVCaptureDevice.Position = .unspecified
    var sessionStatus: SessionSetupResult = .notAuthorized
}
