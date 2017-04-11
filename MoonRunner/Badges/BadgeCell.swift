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

class BadgeCell: UITableViewCell {

    @IBOutlet weak var badgeImageView: UIImageView!
    @IBOutlet weak var silverImageView: UIImageView!
    @IBOutlet weak var goldImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var earnedLabel: UILabel!
    
    var status: BadgeStatus! {
        didSet {
            configure()
        }
    }
    
    private let redLabel = #colorLiteral(red: 1, green: 0.07843137255, blue: 0.1725490196, alpha: 1) // 255, 20, 44
    private let greenLabel = #colorLiteral(red: 0, green: 0.5725490196, blue: 0.3058823529, alpha: 1) // 0, 146, 78
    private let badgeRotation = CGAffineTransform(rotationAngle: .pi / 8)
    
    func configure() {
        silverImageView.isHidden = status.silver == nil
        goldImageView.isHidden = status.gold == nil
        if let earned = status.earned {
            nameLabel.text = status.badge.name
            nameLabel.textColor = greenLabel
            let dateEarned = FormatDisplay.date(earned.timestamp)
            earnedLabel.text = "Earned: \(dateEarned)"
            earnedLabel.textColor = greenLabel
            badgeImageView.image = UIImage(named: status.badge.imageName)
            silverImageView.transform = badgeRotation
            goldImageView.transform = badgeRotation
        } else {
            nameLabel.text = "?????"
            nameLabel.textColor = redLabel
            let distance = Measurement(value: status.badge.distance, unit: UnitLength.meters)
            let formattedDistance = FormatDisplay.distance(distance)
            earnedLabel.text = "Run \(formattedDistance) to earn"
            earnedLabel.textColor = redLabel
            badgeImageView.image = nil
        }
    }

}
