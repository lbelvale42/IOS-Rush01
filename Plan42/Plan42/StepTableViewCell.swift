//
//  StepTableViewCell.swift
//  Plan42
//
//  Created by David BOU on 10/16/16.
//  Copyright © 2016 Lucas BELVALETTE. All rights reserved.
//

import UIKit
import MapKit

class StepTableViewCell: UITableViewCell {

    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!

    var step: MKRouteStep? {
        didSet {
            if let s = step {
                instructionLabel.text = s.instructions
                distanceLabel.text = String(Int(s.distance)) + " m"
            }
        }
    }

}
