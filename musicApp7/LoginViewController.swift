//
//  ViewController.swift
//  musicApp7
//
//  Created by Ido Ben-Natan on 2/16/15.
//  Copyright (c) 2015 Ido Ben-Natan. All rights reserved.
//

import UIKit
import Alamofire
//import SwiftyJson

class LoginViewController: UIViewController, FBLoginViewDelegate {

    @IBOutlet var fbLoginView : FBLoginView!
    var count = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.fbLoginView.delegate = self
        self.fbLoginView.readPermissions = ["public_profile", "email", "user_friends"]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Facebook
    
    // Facebook Delegate methods
    
    func loginViewShowingLoggedInUser(loginView: FBLoginView!) {
        //println("Logged In User")
        //println("Performe Segue here!")
    }
    
    func loginViewFetchedUserInfo(loginView: FBLoginView!, user: FBGraphUser!) {
        if count < 1 {
            Alamofire.request(.POST, "\(URLS.music.rawValue)/sessions", parameters: [
                "access_token": FBSession.activeSession().accessTokenData.accessToken,
                "expires_in": FBSession.activeSession().accessTokenData.expirationDate
                ]).responseJSON { (request, response, json, error) in
                    if json != nil {
                        let userJSON = JSON(json!)
                        //println(userJSON)
                        let userObj = User(json: userJSON)
                        self.performSegueWithIdentifier("showMyParties", sender: userObj)
                        //println(userJSON["name"])
                    }
            }
            count++
        }
    }
    
    func loginViewShowingLoggedOutUser(loginView: FBLoginView!) {
        //println("Logged Out User")
    }
    
    func loginView(loginView: FBLoginView!, handleError error: NSError!) {
        println("Error: \(error.localizedDescription)")
    }

    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "showMyParties":
                let tabController : UITabBarController = segue.destinationViewController as UITabBarController
                let navController : UINavigationController = tabController.viewControllers?.first as UINavigationController
                let partiesTVC = navController.viewControllers[0] as MyPartiesTableViewController
                partiesTVC.user = sender as User
            default:
                break
            }
        }
    }

}

