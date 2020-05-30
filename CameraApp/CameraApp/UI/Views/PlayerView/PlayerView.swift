//
//  PlayerView.swift
//  Looksee
//
//  Created by Ilya on 03.02.2020.
//  Copyright © 2020 Requestum. All rights reserved.
//

import UIKit
import AVFoundation

class PlayerView: UIView {
    
    @IBOutlet weak var actionButton: UIButton!
    
    private let avPlayer = AVPlayer()
    private var avPlayerLayer: AVPlayerLayer!
     
    override func awakeFromNib() {
        super.awakeFromNib()
        self.fromNib()
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if avPlayerLayer != nil {
            avPlayerLayer.frame = bounds
        }
    }
       
    func setup(with url: URL) {
        
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.frame = bounds
        avPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        layer.insertSublayer(avPlayerLayer, at: 0)
        
        layoutIfNeeded()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didFinishPlay), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        
        let playerItem = AVPlayerItem(url: url)
        avPlayer.replaceCurrentItem(with: playerItem)
        
        setupButton(isPlaying: false)
    }
    
    func startPlaying() {

        avPlayer.play()
        setupButton(isPlaying: true)
    }
    
    func stopPlaying() {
        
        avPlayer.pause()
        setupButton(isPlaying: false)
    }
        
    private func setupButton(isPlaying: Bool) {
        
        let playImage = UIImage(named: "playIcon")
        let pauseImage = UIImage(named: "pauseIcon")
        let image = isPlaying ? pauseImage : playImage
        actionButton.setImage(image, for: .normal)
    }
    
    @objc
    private func didFinishPlay() {
        
        avPlayer.seek(to: CMTime.zero)
        setupButton(isPlaying: false)
    }
    
    @IBAction func actionButton(_ sender: UIButton) {
        
        switch avPlayer.timeControlStatus {
            
        case .paused:
            startPlaying()
        case .playing:
            stopPlaying()
        default:
            return
        }
    }
}
