//
//  Request.swift
//  musicApp7
//
//  Created by Ido Ben-Natan on 2/17/15.
//  Copyright (c) 2015 Ido Ben-Natan. All rights reserved.
//

import Foundation
import SwiftyJSON

class Request {
    
    // properties
    
    var id: Int
    var author: String
    var partyId: Int
    var thumbnail: UIImage!
    var thumbnailString: String!
    var url: String!
    var createdAt: NSDate
    var title: String
    var user: User?
    var likes = [Like]()
    
    // constructors
    
    init(id: Int, author: String, partyId: Int, thumbnail: String, url: String, createdAt: String, title: String, user: User?, likes: [Like]) {
        self.id = id
        self.author = author
        self.partyId = partyId
        self.title = title
        self.user = user
        self.likes = likes
        self.thumbnailString = thumbnail
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        self.createdAt = dateFormatter.dateFromString(createdAt)!
        
        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.value), 0)) { () -> Void in
            let url1 = NSURL(string: thumbnail)
            let data = NSData(contentsOfURL: url1!) //make sure your image in this url does exist, otherwise unwrap in a if let check
            self.thumbnail = UIImage(data: data!)!
        }
        
        self.url = url
    }
    
    init(json: JSON) {
        self.id = json["id"].intValue
        self.author = json["author"].stringValue
        self.partyId = json["party_id"].intValue
        self.title = json["title"].stringValue
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        self.createdAt = dateFormatter.dateFromString(json["created_at"].stringValue)!
        
//        self.thumbnailString = json["thumbnail"].stringValue
//        let url = NSURL(string: json["thumbnail"].stringValue)
//        let data = NSData(contentsOfURL: url!)
//        self.thumbnail = UIImage(data: data!)!
        
        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.value), 0)) { () -> Void in
            self.thumbnailString = json["thumbnail"].stringValue
            let url = NSURL(string: json["thumbnail"].stringValue)
            println("waiting for image")
            let data = NSData(contentsOfURL: url!)
            self.thumbnail = UIImage(data: data!)!
        }
        
        
//        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.value), 0)) { () -> Void in
//            self.thumbnailString = json["thumbnail"].stringValue
//            let url = NSURL(string: json["thumbnail"].stringValue)
//            let data = NSData(contentsOfURL: url!)
//            self.thumbnail = UIImage(data: data!)!
//        }
        
        
        if json["user"] != nil {
            self.user = User(json: json["user"])
        }
        
        //self.likes = request.objectForKey("likes") as? Array
        if let tempLikes = json["likes"].array {
            for like in tempLikes {
                self.likes.append(Like(json: like))
            }
        }
        
        self.url = json["url"].stringValue
    }
}