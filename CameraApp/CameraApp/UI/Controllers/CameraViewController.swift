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
        
        CameraManager.shared.prepareCaptureSession { result in
            
            switch result {
            case .failure(let error):
                 print(error.localizedDescription)
            default:
                break
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        CameraManager.shared.startCaptureSession(with: previewView, delegate: self)
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

extension CameraViewController: CameraManagerDelegate {
    
    func didCaptureImage() {
        
    }
    
    func didRecordVideo() {
        
    }
}

