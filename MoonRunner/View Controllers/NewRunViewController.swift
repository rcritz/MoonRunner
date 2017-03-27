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
    
    private var context = CoreDataStack.context
    private var run: Run?
    private let locationManager = LocationManager.sharedManager
    
    private var seconds = 0
    private var distance = 0.0
    private var timer: Timer?
    private var locations: [CLLocation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        
    }
    
    private func startRun() {
        launchPromptStackView.isHidden = true
        dataStackView.isHidden = false
        startButton.isHidden = true
        stopButton.isHidden = false
    }
    
    private func stopRun() {
        launchPromptStackView.isHidden = false
        dataStackView.isHidden = true
        startButton.isHidden = false
        stopButton.isHidden = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .details:
            let destination = segue.destination as! RunDetailsViewController
            destination.run = run
        }
    }
    
}

extension NewRunViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case details = "RunDetailsViewController"
    }
}
