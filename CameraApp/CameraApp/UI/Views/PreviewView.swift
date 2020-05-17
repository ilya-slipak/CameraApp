//
//  PreviewView.swift
//  CameraApp
//
//  Created by Ilya Slipak on 17.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import UIKit
import AVFoundation

protocol PreviewViewDelegate: class {
    
    func didCapturedPhoto(imageData: Data)
    func didRecordedVideo()
}

class PreviewView: UIView {
    
    
    // MARK: - Properties
    
    weak var delegate: PreviewViewDelegate?
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        return layer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = .portrait
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension PreviewView: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard let imageData = photo.fileDataRepresentation() else {
            return
        }
        
        delegate?.didCapturedPhoto(imageData: imageData)
    }
}


// MARK: - AVCaptureFileOutputRecordingDelegate

extension PreviewView: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        if error != nil {
            //TODO: Pass error to Controller
        } else {
            //TODO: Perfrom something with recorded video
        }
    }
}
