//
//  PreviewVideoViewController.swift
//  CameraApp
//
//  Created by Ilya Slipak on 30.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import UIKit

class PreviewVideoViewController: UIViewController {
    
    @IBOutlet weak var playerView: PlayerView!
    private var videoURL: URL!
    
    func setup(videoURL: URL) {
        
        self.videoURL = videoURL
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        playerView.setup(with: videoURL)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        playerView.startPlaying()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        playerView.stopPlaying()
    }
    
    @IBAction func closeAction(_ sender: UIButton) {
        
        dismiss(animated: false)
    }
    
}
