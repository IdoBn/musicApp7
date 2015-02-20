//
//  Party.swift
//  musicApp7
//
//  Created by Ido Ben-Natan on 2/17/15.
//  Copyright (c) 2015 Ido Ben-Natan. All rights reserved.
//

import Foundation

class Party {
    let id: Int
    let name: String
    let user: User?
    var requests: [Request] = []
    
    init(party: JSON) {
        self.id = party["id"].intValue
        self.name = party["name"].stringValue
        
        if party["user"] != nil {
            //self.user = User(tempUser)
            self.user = User(json: party["user"])
        }
        
        if let tempRequest = party["requests"].array {
            for request in tempRequest {
                self.requests.append(Request(json: request))
            }
        }
 
    }
}