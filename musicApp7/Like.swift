//
//  Like.swift
//  musicApp7
//
//  Created by Ido Ben-Natan on 2/17/15.
//  Copyright (c) 2015 Ido Ben-Natan. All rights reserved.
//

import Foundation
import SwiftyJSON

class Like {
    var id: Int
    var user: User
    
//    init(like: NSDictionary) {
//        self.id = like.objectForKey("id") as Int
//        self.user = User(user: like.objectForKey("user") as NSDictionary)
//    }
    
    init(json: JSON) {
        self.id = json["id"].intValue
        self.user = User(json: json["user"])
    }
    
}