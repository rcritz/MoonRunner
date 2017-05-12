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
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
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
import MapKit
import CoreData

class RunDetailsViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var paceLabel: UILabel!
    @IBOutlet weak var badgeImageView: UIImageView!
    @IBOutlet weak var badgeInfoButton: UIButton!
    
    var run: Run!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    @IBAction func displayModeToggled(_ sender: UISwitch) {
        UIView.animate(withDuration: 0.2) {
            self.badgeImageView.alpha = sender.isOn ? 1 : 0
            self.badgeInfoButton.alpha = sender.isOn ? 1 : 0
            self.mapView.alpha = sender.isOn ? 0 : 1
        }
    }
    
    @IBAction func infoButtonTapped() {
        let badge = Badge.best(for: run.distance)
        let alert = UIAlertController(title: badge.name,
                                      message: badge.information,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func configureView() {
        let distance = Measurement(value: run.distance, unit: UnitLength.meters)
        let seconds = Int(run.duration)
        let formattedDistance = FormatDisplay.distance(distance)
        let formattedDate = FormatDisplay.date(run.timestamp)
        let formattedTime = FormatDisplay.time(seconds)
        let formattedPace = FormatDisplay.pace(distance: distance,
                                               seconds: seconds,
                                               outputUnit: UnitSpeed.minutesPerMile)
        
        distanceLabel.text = "Distance:  \(formattedDistance)"
        dateLabel.text = formattedDate
        timeLabel.text = "Time:  \(formattedTime)"
        paceLabel.text = "Pace:  \(formattedPace)"
        loadMap()
        let badge = Badge.best(for: run.distance)
        badgeImageView.image = UIImage(named: badge.imageName)
    }
    
    private func mapRegion() -> MKCoordinateRegion {
        let initialLocation = run.locations?.firstObject as! Location
        var minLat = initialLocation.latitude
        var maxLat = initialLocation.latitude
        var minLong = initialLocation.longitude
        var maxLong = initialLocation.longitude
        
        run.locations?.enumerateObjects( { (location, _, _) in
            let location = location as! Location
            minLat = min(minLat, location.latitude)
            maxLat = max(maxLat, location.latitude)
            minLong = min(minLong, location.longitude)
            maxLong = max(maxLong, location.longitude)
        })
        
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2,
                                            longitude: (minLong + maxLong) / 2)
        let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * 1.3,
                                    longitudeDelta: (maxLong - minLong) * 1.3)
        return MKCoordinateRegion(center: center, span: span)
    }
    
    /* NOTE TO REVIEWERS: This won't appear in the final project but is an intermediate step needed in the article. I've kept it
     * here so that I don't have to recreate it when I'm writing the article.
    private func polyLine() -> MKPolyline {
        var coords: [CLLocationCoordinate2D] = []
        run.locations?.enumerateObjects({ (location, _, _) in
            let location = location as! Location
            coords.append(CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
        })
        return MKPolyline(coordinates: coords, count: coords.count)
    }
 */
    
    private func polyLine() -> [MulticolorPolyline] {
        let locations = run.locations?.array as! [Location]
        var coordinates: [(CLLocation, CLLocation)] = []
        var speeds: [Double] = []
        var minSpeed = Double.greatestFiniteMagnitude
        var maxSpeed = 0.0
        for (first, second) in zip(locations, locations.dropFirst()) {
            let start = CLLocation(latitude: first.latitude, longitude: first.longitude)
            let end = CLLocation(latitude: second.latitude, longitude: second.longitude)
            coordinates.append((start, end))
            let distance = end.distance(from: start)
            let time = second.timestamp!.timeIntervalSince(first.timestamp! as Date)
            let speed = time > 0 ? distance / time : 0
            speeds.append(speed)
            minSpeed = min(minSpeed, speed)
            maxSpeed = max(maxSpeed, speed)
        }
        var segments: [MulticolorPolyline] = []
        let midSpeed = speeds.reduce(0, +) / Double(speeds.count)
        for ((start, end), speed) in zip(coordinates, speeds) {
            let coords = [start.coordinate, end.coordinate]
            let segment = MulticolorPolyline(coordinates: coords, count: 2)
            segment.color = segmentColor(speed: speed, midSpeed: midSpeed, slowestSpeed: minSpeed, fastestSpeed: maxSpeed)
            segments.append(segment)
        }
        return segments
    }
    
    private func segmentColor(speed: Double, midSpeed: Double, slowestSpeed: Double, fastestSpeed: Double) -> UIColor {
        enum baseColors {
            static let r_red: CGFloat = 1
            static let r_green: CGFloat = 20 / 255
            static let r_blue: CGFloat = 44 / 255
            
            static let y_red: CGFloat = 1
            static let y_green: CGFloat = 215 / 255
            static let y_blue: CGFloat = 0
            
            static let g_red: CGFloat = 0
            static let g_green: CGFloat = 146 / 255
            static let g_blue: CGFloat = 78 / 255
        }
        
        let red, green, blue: CGFloat
        if speed < midSpeed {
            let ratio = CGFloat((speed - slowestSpeed) / (midSpeed - slowestSpeed))
            red = baseColors.r_red + ratio * (baseColors.y_red - baseColors.r_red)
            green = baseColors.r_green + ratio * (baseColors.y_green - baseColors.r_green)
            blue = baseColors.r_blue + ratio * (baseColors.y_blue - baseColors.r_blue)
        } else {
            let ratio = CGFloat((speed - midSpeed) / (fastestSpeed - midSpeed))
            red = baseColors.y_red + ratio * (baseColors.g_red - baseColors.y_red)
            green = baseColors.y_green + ratio * (baseColors.g_green - baseColors.y_green)
            blue = baseColors.y_blue + ratio * (baseColors.g_blue - baseColors.y_blue)
        }
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
    
    private func loadMap() {
        guard
            let locations = run.locations,
            locations.count > 0
        else {
            let alert = UIAlertController(title: "Error",
                                          message: "Sorry, this run has no locations saved",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        mapView.setRegion(mapRegion(), animated: true)
        mapView.addOverlays(polyLine())
        mapView.addAnnotations(annotations())
    }
    
    private func annotations() -> [BadgeAnnotation] {
        var annotations: [BadgeAnnotation] = []
        let badgesEarned = Badge.allBadges.filter { $0.distance < run.distance }
        var badgeIterator = badgesEarned.makeIterator()
        var nextBadge = badgeIterator.next()
        let locations = run.locations?.array as! [Location]
        var distance = 0.0
        
        for (first, second) in zip(locations, locations.dropFirst()) {
            guard let badge = nextBadge else { break }
            let start = CLLocation(latitude: first.latitude, longitude: first.longitude)
            let end = CLLocation(latitude: second.latitude, longitude: second.longitude)
            distance += end.distance(from: start)
            if distance >= badge.distance {
                let badgeAnnotation = BadgeAnnotation(imageName: badge.imageName)
                badgeAnnotation.coordinate = end.coordinate
                badgeAnnotation.title = badge.name
                badgeAnnotation.subtitle = FormatDisplay.distance(badge.distance)
                annotations.append(badgeAnnotation)
                nextBadge = badgeIterator.next()
            }
        }
        
        return annotations
    }
    
}

// MARK: - MapView Delegate

extension RunDetailsViewController: MKMapViewDelegate {
    
/* NOTE TO REVIEWERS: See the other note above. Same deal.
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard overlay is MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = .black
        renderer.lineWidth = 3
        return renderer
    }
 */
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard overlay is MulticolorPolyline else { return MKOverlayRenderer(overlay: overlay) }
        let overlay = overlay as! MulticolorPolyline
        let renderer = MKPolylineRenderer(polyline: overlay)
        renderer.strokeColor = overlay.color
        renderer.lineWidth = 3
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is BadgeAnnotation else { return nil }
        let annotation = annotation as! BadgeAnnotation
        let reuseID = "checkpoint"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID)
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            annotationView?.image = #imageLiteral(resourceName: "mapPin")
            annotationView?.canShowCallout = true
        }
        annotationView?.annotation = annotation
        
        let badgeImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        badgeImageView.image = UIImage(named: annotation.imageName)
        badgeImageView.contentMode = .scaleAspectFit
        annotationView?.leftCalloutAccessoryView = badgeImageView
        
        return annotationView
    }

}
