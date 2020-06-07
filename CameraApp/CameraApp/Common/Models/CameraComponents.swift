//
//  CameraComponents.swift
//  CameraApp
//
//  Created by Ilya Slipak on 30.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import Foundation
import AVFoundation

class CameraComponents {
    
    var captureSession: AVCaptureSession = AVCaptureSession()
    var frontCamera: AVCaptureDevice?
    var frontCameraInput: AVCaptureDeviceInput?
    var rearCamera: AVCaptureDevice?
    var rearCameraInput: AVCaptureDeviceInput?
    var photoOutput: AVCapturePhotoOutput?
    var movieOutput: AVCaptureMovieFileOutput?
    var currentCameraPosition: CameraPosition?
    var flashMode: AVCaptureDevice.FlashMode = .off
    var sessionStatus: SessionSetupResult = .authorized
}
