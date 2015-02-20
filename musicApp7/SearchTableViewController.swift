//
//  SearchViewController.swift
//  musicApp7
//
//  Created by Ido Ben-Natan on 2/19/15.
//  Copyright (c) 2015 Ido Ben-Natan. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJson

class SearchTableViewController: UITableViewController, UISearchDisplayDelegate, UISearchBarDelegate {

    var user: User!
    var party: Party!
    var searchResults = [Request]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Search"
        
        // Do any additional setup after loading the view.
        setUp("vevo")
    }
    
    func setUp(text: String) {
        Alamofire.request(.GET, "\(URLS.music.rawValue)/parties/\(self.party.id)/search", parameters: ["songpull": text]).responseJSON {
            (request, response, json, error) in
            let jsonValue = JSON(json!)
            
            if let jsonArray = jsonValue["videos"].array {
                
                self.searchResults = []
                
                for jsonReq in jsonArray {
                    let author = jsonReq["author"]["name"].stringValue
                    let thumbnail = jsonReq["thumbnails"][0]["url"].stringValue
                    let title = jsonReq["title"].stringValue
                    let url = jsonReq["player_url"].stringValue
                    
                    self.searchResults.append(Request(id: 0, author: author, partyId: self.party.id, thumbnail: thumbnail, url: url, createdAt: "2015-01-24T19:00:05.875Z", title: title, user: nil, likes: [Like]()))
                }
                
                //println(jsonValue)
                self.tableView.reloadData()
                self.searchDisplayController!.searchResultsTableView.reloadData()
            }
            
        }

    }

    // MARK: - TableView
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchResults.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("searchCell") as? UITableViewCell
        
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "searchCell")
        }
        
        let request = self.searchResults[indexPath.row]
        // Configure the cell...
        cell!.imageView?.image = request.thumbnail
        // title
        cell!.textLabel!.text = request.title
        // by user name
        cell!.detailTextLabel?.text = request.author
        
        return cell!
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selected = self.searchResults[indexPath.row] as Request
        
        let params = [
            "request": [
                "title" : selected.title,
                "author": selected.author,
                "url": selected.url,
                "party_id": selected.partyId,
                "thumbnail": selected.thumbnailString
            ],
            "user_access_token": self.user.accessToken!
        ]
        
        Alamofire.request(.POST, "\(URLS.music.rawValue)/requests", parameters: params).responseJSON {
            (request, response, json, error) in
        
            let jsonValue = JSON(json!)
            self.party.requests.append(Request(json: jsonValue["request"]))
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    // MARK: - Search
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.setUp(searchBar.text)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}