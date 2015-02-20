//
//  PartyViewController.swift
//  musicApp7
//
//  Created by Ido Ben-Natan on 2/18/15.
//  Copyright (c) 2015 Ido Ben-Natan. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJson

protocol SetUpAble {
    func setUp()
}

class PartyViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, PlayerViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var playerView: PlayerView!
    @IBOutlet weak var activityMonitor: UIActivityIndicatorView!
    
    var count = 0
    weak var refreshControl: UIRefreshControl?
    
    var party: Party?
    var user: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = self.party?.name
        
        // setup player delegate
        self.playerView.delegate = self
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Search, target: self, action: "searchItem:")
        
        // refresh
        var refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: Selector("setUp"), forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
        self.refreshControl = refreshControl
        
        // activity monitor
        activityMonitor.startAnimating()
        
        setUp()
    }
    
    func setUp() {
        if let partyId = self.party?.id {
            Alamofire.request(.GET, "\(URLS.music.rawValue)/parties/\(partyId)").responseJSON {
                (request, response, json, error) in
                let jsonValue = JSON(json!)
                let requestsJson = jsonValue["party"]["requests"]
                self.party?.requests = []
                if let requestsArray = requestsJson.array {
                    for request in requestsArray {
                        self.party?.requests.append(Request(json: request))
                    }
                }
                
                if self.count == 0 {
                    self.count++
                    self.playerView.reDraw()
                }
                
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            }
            
        }
    }
    
    func searchItem(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("showSearch", sender: self)
    }
    
    
    // MARK: - PlayerVew
    
    func onStop() {
        if let request = self.party?.requests.first {
            Alamofire.request(.PATCH, "\(URLS.music.rawValue)/requests/\(request.id)/played", parameters: ["user_access_token": user!.accessToken!]).responseJSON {
                (request, response, json, error) in
                    if json != nil {
                        let jsonValue = JSON(json!)
                        println("on stop nil value = \(jsonValue)")
                    }
                
                    if self.party?.requests.first != nil {
                        let indexPath = NSIndexPath(forItem: 0, inSection: 0)
                        self.party?.requests.removeAtIndex(indexPath.row)
                        self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    }
                
                    if self.party?.requests.first != nil {
                        self.playerView.reDraw()
                    }
            }
        }
    }
    
    func nextPlayerUrl(completionHandler: (String?) -> Void) {
        if let request = self.party?.requests.first {
            let words = request.url.componentsSeparatedByString("&feature")
            let requestUrl = words[0]
            
            Alamofire.request(.GET, "\(URLS.download.rawValue)\(requestUrl)").responseJSON {
                (request, response, json, error) in
                let jsonValue = JSON(json!)
                let str = jsonValue["direct_url"].stringValue
                completionHandler(str)
            }
        }
    }
    
    // MARK: - TableView
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = self.party?.requests.count {
            return count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("requestCell", forIndexPath: indexPath) as UITableViewCell
        
        if let request = self.party?.requests[indexPath.row] {
            // Configure the cell...
            cell.imageView?.image = request.thumbnail
            // title
            cell.textLabel!.text = request.title
            // by user name
            cell.detailTextLabel?.text = request.user?.name
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            if let request = self.party?.requests[indexPath.row] {
                Alamofire.request(.DELETE, "\(URLS.music.rawValue)/requests/\(request.id)", parameters: ["user_access_token": self.user!.accessToken!]).responseJSON {
                    (request, response, json, error) in
                    let jsonValue = JSON(json!)
                    println("removeing table view cell")
                    self.party?.requests.removeAtIndex(indexPath.row)
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                    
                    if indexPath.row == 0 {
                        self.playerView.reDraw()
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "showSearch":
                let searchVC = segue.destinationViewController as SearchTableViewController
                searchVC.user = self.user
                searchVC.party = self.party
            default:
                break
            }
        }
    }

}
