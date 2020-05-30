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
    
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet var previewView: PreviewView!
    
    
    // MARK: - Lifecyle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraButton.layer.cornerRadius = 40
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
    
    @IBAction func capturePhotoAction() {
        
        CameraManager.shared.captureImage()
    }
            
    @IBAction func recordAction(_ sender: UILongPressGestureRecognizer) {
        
        switch sender.state {
            
        case .began:
            let recordImage = UIImage(named: "recordVideoIcon")
            cameraButton.setImage(recordImage, for: .normal)
            CameraManager.shared.startRecording()
        case .ended:
            let captureImage = UIImage(named: "makePhotoIcon")
            cameraButton.setImage(captureImage, for: .normal)
            CameraManager.shared.stopRecoridng()
        default:
            break
        }
    }
    
    @IBAction func switchCameraAction() {
        
        CameraManager.shared.switchCameras()
    }
}

extension CameraViewController: CameraManagerDelegate {
    
    func didCaptureImage(imageData: Data) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "PreviewPhotoViewController") as! PreviewPhotoViewController
        controller.setup(imageData: imageData)
        present(controller, animated: false, completion: nil)
    }
    
    func didRecordVideo(recordedUrl: URL) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "PreviewVideoViewController") as! PreviewVideoViewController
        controller.setup(videoURL: recordedUrl)
        present(controller, animated: false, completion: nil)
    }
}

