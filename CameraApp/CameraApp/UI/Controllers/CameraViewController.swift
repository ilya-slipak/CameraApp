//
//  ViewController.swift
//  CameraApp
//
//  Created by Ilya Slipak on 17.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import UIKit
import AVFoundation

final class CameraViewController: UIViewController, AlertShowable {
    
    // MARK: - IBOutlet Properties
    
    @IBOutlet private weak var flashButton: UIButton!
    @IBOutlet private weak var cameraButton: UIButton!
    @IBOutlet private weak var previewView: PreviewView!
    
    // MARK: - Private Properties
    
    private var zoomFactor: CGFloat = 1.0
    private let cameraManager: CameraManagerProtocol = CameraManager()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        startCaptureSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopCaptureSession()
    }
    
    // MARK: - Private Methods
    
    private func setupView() {
        
        flashButton.tintColor = .white
        cameraButton.layer.cornerRadius = 40
        setupPinchGesture()
        setupTapGesture()
        cameraManager.prepareCaptureSession(position: .front)
    }
        
    private func setupPinchGesture() {
        
        let pinchRecognizer = UIPinchGestureRecognizer(target: self,
                                                       action: #selector(pinchToZoom(_:)))
        view.addGestureRecognizer(pinchRecognizer)
    }
    
    private func setupTapGesture() {
        
        let pinchRecognizer = UITapGestureRecognizer(target: self,
                                                     action: #selector(focusAction(_:)))
        view.addGestureRecognizer(pinchRecognizer)
    }
    
    private func setupFlashButton(with flashMode: AVCaptureDevice.FlashMode) {
        
        switch flashMode {
        case .auto:
            flashButton.setTitle("Auto", for: .normal)
        case .on:
            flashButton.setTitle("On", for: .normal)
        case .off:
            flashButton.setTitle("Off", for: .normal)
        default:
            return
        }
    }
    
    func setupObservers() {
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(subjectAreaDidChange),
            name: .AVCaptureDeviceSubjectAreaDidChange,
            object: nil)
    }
    
    private func startCaptureSession() {
        
        cameraManager.startCaptureSession() { [weak self] sessionStatus in
            
            switch sessionStatus {
            case .notAuthorized:
                self?.showSettingsAlert(with: .cameraAccess)
            case .configurationFailed:
                self?.showMessage(with: "Failed to configure camera")
            case .authorized:
                self?.previewView.session = self?.cameraManager.captureSession
            }
        }
    }
    
    private func stopCaptureSession() {
        
        cameraManager.stopCaptureSession { [weak self] in
            
            self?.previewView.session = nil
        }
    }
        
    private func showPhotoPreview(with imageData: Data) {
        
        let controller = ScreenFactory.makePhotoPreviewScreen(with: imageData)
        present(controller, animated: false, completion: nil)
    }
    
    private func showVideoPreview(with videoURL: URL) {
        
        let controller = ScreenFactory.makeVideoPreviewScreen(with: videoURL)
        present(controller, animated: false, completion: nil)
    }
    
    @objc
    private func subjectAreaDidChange(notification: NSNotification) {
        
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        cameraManager.focus(with: .continuousAutoFocus,
                            exposureMode: .continuousAutoExposure,
                            at: devicePoint,
                            monitorSubjectAreaChange: false)
    }
    
    @objc
    private func didBecomeActive() {
        
        startCaptureSession()
    }
    
    @objc
    private func didEnterBackground() {
        
        stopCaptureSession()
    }
    
    // MARK: - Action Methods
    
    @IBAction func flashAction(_ sender: UIButton) {
        
        let flashMode = cameraManager.switchFlashMode()
        setupFlashButton(with: flashMode)
    }
        
    @objc
    func focusAction(_ sender: UITapGestureRecognizer) {
        
        let devicePoint = previewView.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: sender.location(in: sender.view))
        
        previewView.addFocusSquare(point: sender.location(in: previewView))
        cameraManager.focus(with: .autoFocus,
                            exposureMode: .autoExpose,
                            at: devicePoint,
                            monitorSubjectAreaChange: true)
    }
            
    @objc
    func pinchToZoom(_ pinch: UIPinchGestureRecognizer) {
        
        guard let device = cameraManager.getCurrentCaptureDevice() else {
            return
        }
        
        func minMaxZoom(_ factor: CGFloat) -> CGFloat { return min(max(factor, 1.0), device.activeFormat.videoMaxZoomFactor) }
        
        func update(scale factor: CGFloat) {
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                device.videoZoomFactor = factor
            } catch {
                debugPrint(error)
            }
        }
        
        let newScaleFactor = minMaxZoom(pinch.scale * zoomFactor)
        
        switch pinch.state {
        case .began:
            fallthrough
        case .changed:
            update(scale: newScaleFactor)
        case .ended:
            zoomFactor = minMaxZoom(newScaleFactor)
            update(scale: zoomFactor)
        default:
            break
        }
    }
    
    @IBAction func capturePhotoAction() {
        
        cameraManager.captureImage { [weak self] result in
            
            switch result {
            case .success(let imageData):
                self?.showPhotoPreview(with: imageData)
            case .failure(let error):
                let message = "Failed to capture image:" + error.localizedDescription
                self?.showMessage(with: message)
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
                    let message = "Failed to record video:" + error.localizedDescription
                    self?.showMessage(with: message)
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
