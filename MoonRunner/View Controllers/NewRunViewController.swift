//
//  NewRunViewController.swift
//  MoonRunner
//
//  Created by Richard Critz on 3/20/17.
//  Copyright © 2017 Richard Critz. All rights reserved.
//

import UIKit

class NewRunViewController: UIViewController {

    @IBOutlet weak var launchPromptStackView: UIStackView!
    @IBOutlet weak var dataStackView: UIStackView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func startTapped() {
        launchPromptStackView.isHidden = true
        dataStackView.isHidden = false
        startButton.isHidden = true
        stopButton.isHidden = false
    }

    @IBAction func stopTapped() {
        launchPromptStackView.isHidden = false
        dataStackView.isHidden = true
        startButton.isHidden = false
        stopButton.isHidden = true
    }
    
}
