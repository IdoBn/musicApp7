//
//  PreviewPlayerViewController.swift
//  musicApp7
//
//  Created by Ido Ben-Natan on 2/23/15.
//  Copyright (c) 2015 Ido Ben-Natan. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJson

class PreviewPlayerViewController: UIViewController, PlayerViewDelegate {


    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var playerView: PlayerView!
    
    var songUrl: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        spinner.startAnimating()
        spinner.color = UIColor.blackColor()
        
        playerView.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        playerView?.playerController.player?.pause()
        playerView?.removeFromSuperview()
        playerView = nil
    }
    
    func nextPlayerUrl(completionHandler: (String?) -> Void) {
        let words = songUrl!.componentsSeparatedByString("&feature")
        let requestUrl = words[0]
        
        Alamofire.request(.GET, "\(URLS.download.rawValue)\(requestUrl)").responseJSON {
            (request, response, json, error) in
            let jsonValue = JSON(json!)
            let str = jsonValue["direct_url"].stringValue
            completionHandler(str)
            self.spinner.stopAnimating()
        }
    }
    
    func onStop() {
        self.navigationController?.popViewControllerAnimated(true)
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
