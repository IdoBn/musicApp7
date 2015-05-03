//
//  User.swift
//  musicApp7
//
//  Created by Ido Ben-Natan on 2/16/15.
//  Copyright (c) 2015 Ido Ben-Natan. All rights reserved.
//


extension UIImage {
    // Loads image asynchronously
    class func loadFromURL(url: String, callback: (UIImage)->Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
            let nsUrl = NSURL(string: url)
            if nsUrl != nil {
                let imageData = NSData(contentsOfURL: nsUrl!)
                if let data = imageData {
                    dispatch_async(dispatch_get_main_queue(), {
                        if let image = UIImage(data: data) {
                            callback(image)
                        }
                    })
                }
            }
        })
    }
}

import Foundation
import SwiftyJSON

class User {
    // properties
    var id: Int
    var name: String
    var email: String?
    var thumbnail: UIImage?
    var largeThumbnail: UIImage?
    var accessToken: String?
    
    // constructor
    
    init(id: Int, name: String, email: String?, thumbnail: String, accessToken: String?) {
        self.id = id
        self.name = name
        
        if email != nil {
            self.email = email
        }
        
        let url = NSURL(string: thumbnail)
        let data = NSData(contentsOfURL: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check
        self.thumbnail = UIImage(data: data!)!
        
        let largeUrl = NSURL(string: thumbnail + "?type=large")
        let largeData = NSData(contentsOfURL: largeUrl!)
        self.largeThumbnail = UIImage(data: largeData!)!
        
        if accessToken != nil {
            self.accessToken = accessToken
        }
    }
    
    init(json: JSON) {
        self.id = json["id"].intValue
        self.name = json["name"].stringValue
        
        if let email = json["email"].string {
            self.email = email
        }
        
        if let thumbnail = json["thumbnail"].string {
            //let largeUrl = NSURL(string: thumbnail + "?type=large")
            UIImage.loadFromURL(thumbnail) { (image) -> Void in
                self.largeThumbnail = image
            }
        }
        
        if let accessToken = json["access_token"].string {
            self.accessToken = accessToken
        }
    }
    
    func likes(request: Request) -> Bool {
        for like in request.likes {
            if like.user.id == self.id {
                return true;
            }
        }
        return false;
    }
    
}
