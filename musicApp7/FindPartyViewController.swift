//
//  FindPartyViewController.swift
//  musicApp7
//
//  Created by Ido Ben-Natan on 2/24/15.
//  Copyright (c) 2015 Ido Ben-Natan. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class FindPartyViewController: UIViewController {

    @IBOutlet weak var inputField: UITextField!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Find Party"
        
        spinner.color = UIColor.blackColor()
        
        inputField.placeholder = "Party code"
    }
    
    @IBAction func searchPressed(sender: UIButton) {
        // called when 'return' key pressed. return NO to ignore.
        inputField.resignFirstResponder()
        spinner.startAnimating()
        
        Alamofire.request(.GET, "\(URLS.music.rawValue)/parties/\(inputField.text)").responseJSON { (request, response, json, error) -> Void in
            if json != nil {
                let jsonValue = JSON(json!)
                
                //println(jsonValue)
                
                let party = Party(party: jsonValue["party"])
                self.performSegueWithIdentifier("showParty", sender: party)
            }
            self.spinner.stopAnimating()
        }
        
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier {
            switch identifier {
            case "showParty":
                if let party = sender as? Party {
                    let partyTVC = segue.destinationViewController as! PartyTableViewController
                    partyTVC.party = party
                    
                    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                    partyTVC.user = appDelegate.user
                    
                }
            default:
                break
            }
        }
    }

}
