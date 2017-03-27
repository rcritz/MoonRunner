/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import CoreData
import CoreLocation

class NewRunViewController: UIViewController {

    @IBOutlet weak var launchPromptStackView: UIStackView!
    @IBOutlet weak var dataStackView: UIStackView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var paceLabel: UILabel!
    
    private var context = CoreDataStack.context
    private var run: Run?
    private let locationManager = LocationManager.sharedManager
    private let measurementFormatter = MeasurementFormatter()
    private let dateFormatter = DateComponentsFormatter()
    
    private var seconds = 0
    private var timer: Timer?
    fileprivate var distance = Measurement(value: 0, unit: UnitLength.meters)
    fileprivate var locationList: [CLLocation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormatter.allowedUnits = [.hour, .minute, .second]
        dateFormatter.unitsStyle = .positional
        dateFormatter.zeroFormattingBehavior = .pad
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
    }

    @IBAction func startTapped() {
        startRun()
    }

    @IBAction func stopTapped() {
        let alertController = UIAlertController(title: "End run?", message: "Do you wish to end your run?", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Save", style: .default) { (action) in
            self.stopRun()
            self.performSegue(withIdentifier: .details, sender: nil)
        })
        alertController.addAction(UIAlertAction(title: "Discard", style: .destructive) { (action) in
            self.stopRun()
            let _ = self.navigationController?.popToRootViewController(animated: true)
        })
        
        present(alertController, animated: true, completion: nil)
    }
    
    func eachSecond() {
        seconds += 1
        
        measurementFormatter.unitOptions = []
        let formattedDistance = measurementFormatter.string(from: distance)
        let formattedTime = dateFormatter.string(from: TimeInterval(seconds))!
        let speed = Measurement(value: distance.value / Double(seconds), unit: UnitSpeed.metersPerSecond)
        measurementFormatter.unitOptions = [.providedUnit]
        let formattedPace = measurementFormatter.string(from: speed.converted(to: UnitSpeed.minutesPerMile))
        
        distanceLabel.text = "Distance:  \(formattedDistance)"
        timeLabel.text = "Time:  \(formattedTime)"
        paceLabel.text = "Pace:  \(formattedPace)"
    }
    
    private func startRun() {
        launchPromptStackView.isHidden = true
        dataStackView.isHidden = false
        startButton.isHidden = true
        stopButton.isHidden = false
        
        seconds = 0
        distance = Measurement(value: 0, unit: UnitLength.meters)
        locationList.removeAll()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.eachSecond()
        }
        startLocationUpdates()
    }
    
    private func stopRun() {
        launchPromptStackView.isHidden = false
        dataStackView.isHidden = true
        startButton.isHidden = false
        stopButton.isHidden = true
        
        locationManager.stopUpdatingLocation()
    }
    
    private func startLocationUpdates() {
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.distanceFilter = 10
        locationManager.startUpdatingLocation()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .details:
            let destination = segue.destination as! RunDetailsViewController
            destination.run = run
        }
    }
    
}

extension NewRunViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for newLocation in locations {
            guard newLocation.horizontalAccuracy < 20 else { continue }
            if locationList.count > 0 {
                let delta = newLocation.distance(from: locationList.last!)
                distance = distance + Measurement(value: delta, unit: UnitLength.meters)
            }
            locationList.append(newLocation)
        }
    }
}

extension NewRunViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case details = "RunDetailsViewController"
    }
}
