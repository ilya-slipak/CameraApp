//
//  PreviewPhotoViewController.swift
//  CameraApp
//
//  Created by Ilya Slipak on 30.05.2020.
//  Copyright © 2020 Ilya Slipak. All rights reserved.
//

import UIKit

class PreviewPhotoViewController: UIViewController {

    @IBOutlet weak var previewImageView: UIImageView!
    
    private var imageData: Data!
    
    func setup(imageData: Data) {
        
        self.imageData = imageData
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let image = UIImage(data: imageData)
        previewImageView.image = image
    }
    
    @IBAction func closeButtonAction(_ sender: UIButton) {
        
        dismiss(animated: false)
    }
}
