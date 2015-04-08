//
//  PartyTableViewController.swift
//  musicApp7
//
//  Created by Ido Ben-Natan on 2/18/15.
//  Copyright (c) 2015 Ido Ben-Natan. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class PartyTableViewController: UITableViewController {

    var party: Party?
    var user: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.party?.name
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        //setUp()
        
        // search
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Search, target: self, action: "searchItem:")
        
        // refresh
        var refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: Selector("setUp"), forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl = refreshControl

    }
    
    func setUp() {
        if let partyId = self.party?.id {
            Alamofire.request(.GET, "\(URLS.music.rawValue)/parties/\(partyId)").responseJSON {
                (request, response, json, error) in
                let jsonValue = JSON(json!)
                self.party = Party(party: jsonValue["party"])
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            }
        
        }
    }
    
    func searchItem(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("showSearch", sender: self)
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        if let count = self.party?.requests.count {
            return count
        }
        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("requestCell", forIndexPath: indexPath) as! UITableViewCell
        
        if let request = self.party?.requests[indexPath.row] {
            // Configure the cell...
            cell.imageView?.image = request.thumbnail
            // title
            cell.textLabel!.text = request.title
            // subtitle
            cell.detailTextLabel?.text = request.user?.name
        }
        
        return cell
    }

    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return NO if you do not want the specified item to be editable.
    return true
    }
    */
    
    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
    // Delete the row from the data source
    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    } else if editingStyle == .Insert {
    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
    }
    */
    
    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
    
    }
    */
    
    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return NO if you do not want the item to be re-orderable.
    return true
    }
    */
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
        if let identifier = segue.identifier {
            switch identifier {
            case "showRequest":
                let selectedIndex = self.tableView.indexPathForCell(sender as! UITableViewCell)
                if let index = selectedIndex?.row {
                    let requestVC = segue.destinationViewController as! RequestTableViewController
                    requestVC.user = self.user
                    requestVC.request = self.party!.requests[index]
                }
            case "showSearch":
                let searchVC = segue.destinationViewController as! SearchTableViewController
                searchVC.user = self.user
                searchVC.party = self.party
            default:
                break
            }
        }
    }
}