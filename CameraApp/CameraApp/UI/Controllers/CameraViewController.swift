//
//  ViewController.swift
//  CameraApp
//
//  Created by Ilya Slipak on 17.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    
    
    // MARK: - Outlets
    
    @IBOutlet var previewView: PreviewView!
    
    
    // MARK: - Lifecyle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        previewView.delegate = self
        CameraManager.shared.prepareCaptureSession { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        CameraManager.shared.startCaptureSession(with: previewView)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        CameraManager.shared.stopCaptureSession()
        super.viewWillDisappear(animated)
    }
    
    
    // MARK: Action
    
    @IBAction func capturePhoto() {
        
        CameraManager.shared.captureImage()
    }
}

extension CameraViewController: PreviewViewDelegate {
    
    func didCapturedPhoto(imageData: Data) {
        
    }
    
    func didRecordedVideo() {
        
    }
}

