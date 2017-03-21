//
//  RunDetailsViewController.swift
//  MoonRunner
//
//  Created by Richard Critz on 3/20/17.
//  Copyright © 2017 Richard Critz. All rights reserved.
//

import UIKit
import MapKit

class RunDetailsViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var paceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }


}
