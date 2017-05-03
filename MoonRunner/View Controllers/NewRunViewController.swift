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
import CoreLocation
import MapKit
import AVFoundation

class NewRunViewController: UIViewController {
    @IBOutlet weak var launchPromptStackView: UIStackView!
    @IBOutlet weak var dataStackView: UIStackView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var paceLabel: UILabel!
    @IBOutlet weak var mapContainerView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var badgeStackView: UIStackView!
    @IBOutlet weak var badgeImageView: UIImageView!
    @IBOutlet weak var badgeInfoLabel: UILabel!
    
    fileprivate var run: Run?
    private let locationManager = LocationManager.shared
    
    private var seconds = 0
    private var timer: Timer?
    private var upcomingBadge: Badge!
    fileprivate var distance = Measurement(value: 0, unit: UnitLength.meters)
    fileprivate var locationList: [CLLocation] = []
    private let successSound: AVAudioPlayer = {
        if let successSound = NSDataAsset(name: "success") {
            return try! AVAudioPlayer(data: successSound.data)
        }
        return AVAudioPlayer()
    }()
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        locationManager.stopUpdatingLocation()
    }

    @IBAction func startTapped() {
        startRun()
    }

    @IBAction func stopTapped() {
        let alertController = UIAlertController(title: "End run?", message: "Do you wish to end your run?", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            self.stopRun()
            self.saveRun()
            self.performSegue(withIdentifier: .details, sender: nil)
        })
        alertController.addAction(UIAlertAction(title: "Discard", style: .destructive) { _ in
            self.stopRun()
            _ = self.navigationController?.popToRootViewController(animated: true)
        })
        
        present(alertController, animated: true, completion: nil)
    }
    
    func eachSecond() {
        seconds += 1
        checkNextBadge()
        updateDisplay()
    }
    
    private func updateDisplay() {
        let formattedDistance = FormatDisplay.distance(distance)
        let formattedTime = FormatDisplay.time(seconds)
        let formattedPace = FormatDisplay.pace(distance: distance, seconds: seconds, outputUnit: UnitSpeed.minutesPerMile)
        let distanceRemaining = upcomingBadge.distance - distance.value
        let formattedDistanceRemaining = FormatDisplay.distance(distanceRemaining)
        
        distanceLabel.text = "Distance:  \(formattedDistance)"
        timeLabel.text = "Time:  \(formattedTime)"
        paceLabel.text = "Pace:  \(formattedPace)"
        badgeInfoLabel.text = "\(formattedDistanceRemaining) until \(upcomingBadge.name)"
    }
    
    private func checkNextBadge() {
        let nextBadge = Badge.next(for: distance.value)
        if upcomingBadge != nextBadge {
            badgeImageView.image = UIImage(named: nextBadge.imageName)
            upcomingBadge = nextBadge
            successSound.play()
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }
    
    private func startRun() {
        launchPromptStackView.isHidden = true
        dataStackView.isHidden = false
        mapContainerView.isHidden = false
        startButton.isHidden = true
        stopButton.isHidden = false
        badgeStackView.isHidden = false
        
        seconds = 0
        distance = Measurement(value: 0, unit: UnitLength.meters)
        locationList.removeAll()
        mapView.removeOverlays(mapView.overlays)
        upcomingBadge = Badge.next(for: 0)
        badgeImageView.image = UIImage(named: upcomingBadge.imageName)
        updateDisplay()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.eachSecond()
        }
        startLocationUpdates()
    }
    
    private func stopRun() {
        launchPromptStackView.isHidden = false
        dataStackView.isHidden = true
        mapContainerView.isHidden = true
        startButton.isHidden = false
        stopButton.isHidden = true
        badgeStackView.isHidden = true
        
        locationManager.stopUpdatingLocation()
    }
    
    private func startLocationUpdates() {
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.distanceFilter = 10
        locationManager.startUpdatingLocation()
    }
    
    private func saveRun() {
        let newRun = Run(context: CoreDataStack.context)
        newRun.distance = distance.value
        newRun.duration = Int16(seconds)
        newRun.timestamp = NSDate()
        
        for location in locationList {
            let locationObject = Location(context: CoreDataStack.context)
            locationObject.timestamp = location.timestamp as NSDate?
            locationObject.latitude = location.coordinate.latitude
            locationObject.longitude = location.coordinate.longitude
            newRun.addToLocations(locationObject)
        }
        
        CoreDataStack.saveContext()
        
        run = newRun
    }
}

// MARK: - Location manager delegate

extension NewRunViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for newLocation in locations {
            let howRecent = newLocation.timestamp.timeIntervalSinceNow
            guard newLocation.horizontalAccuracy < 20 && abs(howRecent) < 10 else { continue }
            if let lastLocation = locationList.last {
                let delta = newLocation.distance(from: lastLocation)
                distance = distance + Measurement(value: delta, unit: UnitLength.meters)
                let coordinates = [lastLocation.coordinate, newLocation.coordinate]
                mapView.add(MKPolyline(coordinates: coordinates, count: 2))
                let region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 500, 500)
                mapView.setRegion(region, animated: true)
            }
            locationList.append(newLocation)
        }
    }
}

// MARK: - Map view delegate

extension NewRunViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard overlay is MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        renderer.lineWidth = 3
        return renderer
    }
}

// MARK: - navigation

extension NewRunViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case details = "RunDetailsViewController"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .details:
            let destination = segue.destination as! RunDetailsViewController
            destination.run = run
        }
    }
}
