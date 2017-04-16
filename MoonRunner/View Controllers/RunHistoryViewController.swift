//
//  RunHistoryViewController.swift
//  MoonRunner
//
//  Created by Richard Critz on 4/16/17.
//  Copyright © 2017 Richard Critz. All rights reserved.
//

import UIKit
import CoreData

class RunHistoryViewController: CoreDataTableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFetchedResultsController()
    }
    
    override func setupFetchedResultsController() {
        let request: NSFetchRequest<Run> = Run.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: #keyPath(Run.timestamp), ascending: false)
        ]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult>, managedObjectContext: CoreDataStack.context, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let match = fetchedResultsController?.object(at: indexPath) as! Run
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .long
        cell.textLabel?.text = formatter.string(from: match.timestamp! as Date)
        cell.detailTextLabel?.text = FormatDisplay.distance(match.distance)
        return cell
    }
}

// MARK: - navigation

extension RunHistoryViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case details = "RunDetails"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .details:
            let destination = segue.destination as! RunDetailsViewController
            let indexPath = tableView.indexPath(for: sender as! UITableViewCell)!
            let run = fetchedResultsController?.object(at: indexPath) as! Run
            destination.run = run
        }
    }
}
