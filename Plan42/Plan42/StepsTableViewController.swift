//
//  StepsTableViewController.swift
//  Plan42
//
//  Created by David BOU on 10/16/16.
//  Copyright © 2016 Lucas BELVALETTE. All rights reserved.
//

import UIKit
import MapKit

class StepsTableViewController: UITableViewController {
    
    var steps: [MKRouteStep] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return steps.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "stepCell", for: indexPath) as! StepTableViewCell

        cell.step = steps[indexPath.row]

        return cell
    }
}
