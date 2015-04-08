//
//  MyPartiesTableViewController.swift
//  musicApp7
//
//  Created by Ido Ben-Natan on 2/16/15.
//  Copyright (c) 2015 Ido Ben-Natan. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class MyPartiesTableViewController: UITableViewController {
    
    var user: User!
    var parties = [Party]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "\(user.name) Parties"
        
        // edit button
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // insert button
        let insertButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "addItem:")
        self.navigationItem.leftBarButtonItem = insertButton
        
        // refresh
        var refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: Selector("setUp"), forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl = refreshControl
        
        // setup table view
        setUp()
    }
    
    func setUp() {
        Alamofire.request(.GET, "\(URLS.music.rawValue)/users/\(self.user.id)").responseJSON {
            (request, response, json, error) in
            let jsonValue = JSON(json!)
            let partiesJson = jsonValue["user"]["parties"]
            
            self.parties = []
            
            if let partiesArray = partiesJson.array {
                for party in partiesArray {
                    self.parties.append(Party(party: party))
                }
            }
            
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.parties.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("myPartyCell", forIndexPath: indexPath) as! UITableViewCell
        
        cell.textLabel!.text = self.parties[indexPath.row].name as String
        
        return cell
    }

    // MARK: - Updating Cells
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    
    func addItem(sender: UIBarButtonItem) {
        var alert = UIAlertController(title: "New Party", message: "What would you like to name your party?", preferredStyle: .Alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        alert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
            textField.attributedPlaceholder = NSAttributedString(string:"name...", attributes:[NSForegroundColorAttributeName: UIColor.grayColor()])
        })
        
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            let textField = alert.textFields![0] as! UITextField
            
            if textField.text != "" {
                Alamofire.request(Alamofire.Method.POST, "\(URLS.music.rawValue)/parties", parameters: [
                    "party": [ "name": textField.text ],
                    "user_access_token": self.user.accessToken!
                    ]).responseJSON {
                        (request, response, json, error) in
                        let jsonValue = JSON(json!)
                        
                        let indexPath = NSIndexPath(forRow: self.parties.count, inSection: 0)
                        
                        self.parties.insert(Party(party: jsonValue["party"]), atIndex: indexPath.row)
                        
                }
            }
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            let party = self.parties[indexPath.row]
            Alamofire.request(.DELETE, "\(URLS.music.rawValue)/parties/\(party.id)", parameters: ["user_access_token": self.user.accessToken!]).responseJSON {
                (request, response, json, error) in
                let jsonValue = JSON(json!)
                println(jsonValue)
                self.parties.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
        }
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier {
            switch identifier {
            case "showParty":
                let selectedIndex = self.tableView.indexPathForCell(sender as! UITableViewCell)
                if let indexPath = selectedIndex {
                    let partyTVC = segue.destinationViewController as! PartyViewController
                    partyTVC.party = self.parties[indexPath.row]
                    partyTVC.user = self.user
                }
            default:
                break
            }
        }
    }

}
