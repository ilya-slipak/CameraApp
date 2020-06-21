//
//  ViewController.swift
//  CameraApp
//
//  Created by Ilya Slipak on 17.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import UIKit
import AVFoundation

final class CameraViewController: UIViewController {
    
    
    // MARK: - Outlets
    
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet var previewView: PreviewView!
    
    
    // MARK: - Private Properties
    
    private let cameraManager: CameraManager = CameraManager()
    
    
    // MARK: - Lifecyle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraButton.layer.cornerRadius = 40
        cameraManager.prepareCaptureSession()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        cameraManager.startCaptureSession() { [weak self] sessionStatus in
            
            switch sessionStatus {
            case .notAuthorized:
                print("Please go to setting and enable access to camera")
            case .configurationFailed:
                print("Failed to configure camera")
            case .authorized:
                self?.previewView.session = self?.cameraManager.captureSession
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        cameraManager.stopCaptureSession { [weak self] in
            
            self?.previewView.session = nil
        }
        
        super.viewWillDisappear(animated)
    }
    
    private func showPhotoPreview(with imageData: Data) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "PreviewPhotoViewController") as! PreviewPhotoViewController
        controller.setup(imageData: imageData)
        present(controller, animated: false, completion: nil)
    }
    
    private func showVideoPreview(with videoURL: URL) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "PreviewVideoViewController") as! PreviewVideoViewController
        controller.setup(videoURL: videoURL)
        present(controller, animated: false, completion: nil)
    }
    
    
    // MARK: Action
    
    @IBAction func capturePhotoAction() {
        
        cameraManager.captureImage { [weak self] result in
            
            switch result {
            case .success(let imageData):
                self?.showPhotoPreview(with: imageData)
            case .failure(let error):
                print("Failed to capture image:", error)
            }
            
        }
    }
    
    @IBAction func recordAction(_ sender: UILongPressGestureRecognizer) {
        
        switch sender.state {
            
        case .began:
            let recordImage = UIImage(named: "recordVideoIcon")
            cameraButton.setImage(recordImage, for: .normal)
            cameraManager.startRecording { [weak self] result in
                switch result {
                case .success(let videoURL):
                    self?.showVideoPreview(with: videoURL)
                case .failure(let error):
                    print("Failed to record video:", error)
                }
            }
        case .ended:
            let captureImage = UIImage(named: "makePhotoIcon")
            cameraButton.setImage(captureImage, for: .normal)
            cameraManager.stopRecording()
        default:
            break
        }
    }
    
    @IBAction func switchCameraAction() {
        
        cameraManager.switchCamera()
    }
}

