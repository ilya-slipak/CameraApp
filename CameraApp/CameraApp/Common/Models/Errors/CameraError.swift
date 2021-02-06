//
//  CameraError.swift
//  CameraApp
//
//  Created by Ilya Slipak on 17.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import Foundation

enum CameraError: Error {
    
    case captureSessionAlreadyRunning
    case captureSessionIsMissing
    case inputsAreInvalid
    case invalidOperation
    case emptyCameraInput
    case failedToAddCameraInput
    case failedToAddAudioInput
    case failedToAddPhotoOutput
    case failedToAddMovieOutput
    case noCamerasAvailable
    case unknown
}
