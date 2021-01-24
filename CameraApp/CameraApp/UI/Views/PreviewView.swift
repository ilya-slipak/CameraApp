//
//  PreviewView.swift
//  CameraApp
//
//  Created by Ilya Slipak on 17.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import UIKit
import AVFoundation

final class PreviewView: UIView {
    
    // MARK: - Properties
    
    private var focusSquareView: FocusSquareView?
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
        
        focusSquareView = FocusSquareView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = .portrait
    }
    
    func addFocusSquare(point: CGPoint) {
        
        let isContain = subviews.contains(where: { $0 is FocusSquareView })
        
        if isContain {
            removeFocusSquare()
        }
        
        guard let focusSquareView = focusSquareView else {
            return
        }
        addSubview(focusSquareView)
        focusSquareView.center = point
        focusSquareView.animate { [weak self] in
            self?.removeFocusSquare()
        }
    }
    
    func removeFocusSquare() {
        
        focusSquareView?.stopAnimation()
    }
}
