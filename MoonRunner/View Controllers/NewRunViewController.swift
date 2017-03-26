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

class NewRunViewController: UIViewController {

    @IBOutlet weak var launchPromptStackView: UIStackView!
    @IBOutlet weak var dataStackView: UIStackView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    var context: NSManagedObjectContext!
    private var run: Run?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func startTapped() {
        launchPromptStackView.isHidden = true
        dataStackView.isHidden = false
        startButton.isHidden = true
        stopButton.isHidden = false
    }

    @IBAction func stopTapped() {
        let alertController = UIAlertController(title: "End run?", message: "Do you wish to end your run?", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Save", style: .default) { (action) in
            self.stopRun()
            self.performSegue(withIdentifier: "RunDetailsViewController", sender: nil)
        })
        alertController.addAction(UIAlertAction(title: "Discard", style: .destructive) { (action) in
            self.stopRun()
            let _ = self.navigationController?.popToRootViewController(animated: true)
        })
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func stopRun() {
        launchPromptStackView.isHidden = false
        dataStackView.isHidden = true
        startButton.isHidden = false
        stopButton.isHidden = true
    }
    
}
