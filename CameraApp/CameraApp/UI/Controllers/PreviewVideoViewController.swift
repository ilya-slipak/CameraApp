//
//  PreviewVideoViewController.swift
//  CameraApp
//
//  Created by Ilya Slipak on 30.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import UIKit

final class PreviewVideoViewController: UIViewController {
    
    @IBOutlet private weak var playerView: PlayerView!
    private var videoURL: URL!
    
    func setup(videoURL: URL) {
        
        self.videoURL = videoURL
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        playerView.setup(with: videoURL)
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
         playerView.startPlaying()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        playerView.stopPlaying()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func closeAction(_ sender: UIButton) {
        
        dismiss(animated: false)
    }
}
