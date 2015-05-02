//
//  PartyViewController.swift
//  musicApp7
//
//  Created by Ido Ben-Natan on 2/18/15.
//  Copyright (c) 2015 Ido Ben-Natan. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import AVFoundation
import AVKit
import PusherSwift

class PartyViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, PlayerViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var playerView: PlayerView!
    @IBOutlet weak var activityMonitor: UIActivityIndicatorView!
    
    var count = 0
    weak var refreshControl: UIRefreshControl?
    
    var party: Party?
    var user: User?
    var pusherClient: Pusher!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = self.party?.name
        
        // pusher
        
        pusherClient = Pusher(key: "27aa526da1424bb735a4", encrypted: false, authEndpoint: nil)
        var pusherChannel = pusherClient.subscribe("\(self.party!.id)") as PusherChannel
        
        pusherChannel.bind("request_liked", callback: { (json) -> Void in
            println("request_liked")
            println(json)
            self.tableView.beginUpdates()
            self.setUp()
            let indexSet = NSIndexSet(index: 0)
            self.tableView.reloadSections(indexSet, withRowAnimation: .Fade)
            self.tableView.endUpdates()

        })
        
        pusherChannel.bind("request_unliked", callback: { (json) -> Void in
            println("request_unliked")
            println(json)
            
            self.tableView.beginUpdates()
            self.setUp()
            let indexSet = NSIndexSet(index: 0)
            self.tableView.reloadSections(indexSet, withRowAnimation: .Fade)
            self.tableView.endUpdates()
        })
        
        pusherChannel.bind("request_created", callback: { (json) -> Void in
            println("request_created")
            println(json)
            
            self.tableView.beginUpdates()
            self.party?.requests.append(Request(json: json))
            if self.party?.requests.count == 1 {
                self.playerView.reDraw()
            }
            let indexSet = NSIndexSet(index: 0)
            self.tableView.reloadSections(indexSet, withRowAnimation: .Fade)
            self.tableView.endUpdates()
        })
        
        pusherChannel.bind("request_played", callback: { (json) -> Void in
            println("request_played")
            println(json)
        })
        
        pusherChannel.bind("request_destroyed", callback: { (json) -> Void in
            println("request_destroyed")
            println(json)
            
            self.tableView.beginUpdates()
            let request = Request(json: json)
            
            var index: Int? = nil
            
            if self.party?.requests != nil {
                for (i, r) in enumerate(self.party!.requests) {
                    if r.id == request.id {
                        index = i
                    }
                }
            }
            
            if let indexC = index {
                if self.party?.requests[indexC].id == request.id {
                    self.party?.requests.removeAtIndex(indexC)
                }
            }
            
            let indexSet = NSIndexSet(index: 0)
            self.tableView.reloadSections(indexSet, withRowAnimation: .Fade)
            self.tableView.endUpdates()
            
//            if self.party?.requests.count > 0 {
//                self.playerView.reDraw()
//            }
        })
        
        self.pusherClient.connect()
        
        // setup player delegate
        self.playerView.delegate = self
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Search, target: self, action: "searchItem:")
        
        // refresh
        var refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: Selector("setUp"), forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
        self.refreshControl = refreshControl
        
        // activity monitor
        activityMonitor.color = UIColor.blackColor()
        activityMonitor.startAnimating()
        
        // av audio player
        
        setUp()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        playerView?.playerController.player?.pause()
    }
    
    func setUp() {
        if let partyId = self.party?.id {
            self.refreshControl?.beginRefreshing()
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
        let currentTime = playerView.playerController.player.currentTime() as CMTime
        let duration = playerView.playerController.player.currentItem.duration as CMTime
        if currentTime.timescale == duration.timescale {
            if let request = self.party?.requests.first {
                Alamofire.request(.PATCH, "\(URLS.music.rawValue)/requests/\(request.id)/played", parameters: ["user_access_token": user!.accessToken!]).responseJSON {
                    (request, response, json, error) in
                    if json != nil {
                        let jsonValue = JSON(json!)
                        //println("on stop nil value = \(jsonValue)")
                    }
                    
                    if self.party?.requests.first != nil {
                        let indexPath = NSIndexPath(forItem: 0, inSection: 0)
                        self.party?.requests.removeAtIndex(indexPath.row)
                        self.tableView?.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    }
                    
                    if self.party?.requests.first != nil {
                        self.playerView.reDraw()
                    }
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
                if let jsonUn: AnyObject = json {
                    let jsonValue = JSON(jsonUn)
                    let str = jsonValue["direct_url"].stringValue
                    println(str)
                    completionHandler(str)
                }
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
        let cell = tableView.dequeueReusableCellWithIdentifier("requestCell", forIndexPath: indexPath) as! UITableViewCell
        
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
                    if self.party?.requests.count > indexPath.row {
                        self.party?.requests.removeAtIndex(indexPath.row)
                        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                    }
                    
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
                let searchVC = segue.destinationViewController as!SearchTableViewController
                searchVC.user = self.user
                searchVC.party = self.party
            case "showRequest":
                let requestVC = segue.destinationViewController  as! RequestTableViewController
                let selectedIndex = self.tableView.indexPathForCell(sender as! UITableViewCell)
                if let index = selectedIndex?.row {
                    requestVC.user = self.user
                    requestVC.request = self.party!.requests[index]
                }
            default:
                break
            }
        }
    }

}
