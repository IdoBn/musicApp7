//
//  RequestTableViewController.swift
//  musicApp7
//
//  Created by Ido Ben-Natan on 2/20/15.
//  Copyright (c) 2015 Ido Ben-Natan. All rights reserved.
//

import UIKit

class RequestTableViewController: UITableViewController {

    var request: Request!
    var user: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        //let nib = UINib(nibName: "ProfileTableViewCell", bundle: nil)
        //tableView.registerNib(nib!, forCellReuseIdentifier: "profileCell")
        
        self.title = request.title
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 3
        } else {
            return self.request.likes.count
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Configure the cell...
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("profileCell", forIndexPath: indexPath) as UITableViewCell
            
            if indexPath.row == 1 {
                cell.textLabel?.text = "votes: \(request.likes.count)"
                return cell
            }
            
            if indexPath.row == 0 {
                cell.imageView?.image = request.user!.thumbnail
                cell.imageView?.layer.cornerRadius = 25
                cell.imageView?.layer.masksToBounds = true
                //cell.imageView?.frame = CGRectMake(cell.imageView?.frame.origin.x, cell.imageView?.frame.origin.y, 100, 100)
                
                cell.textLabel?.text = request.user!.name
                cell.backgroundColor = UIColor.groupTableViewBackgroundColor()
                
                return cell
            }
            
            cell.textLabel?.text = "Play: \(request.title)"
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("likeCell", forIndexPath: indexPath) as UITableViewCell
            cell.imageView?.image = request.likes[indexPath.row].user.thumbnail
            cell.imageView?.layer.cornerRadius = 20
            cell.imageView?.layer.masksToBounds = true
            cell.textLabel?.text = request.likes[indexPath.row].user.name
            return cell
        }
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                return 88
            } else {
                return 44
            }
        }
        return 44
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Uploaded By"
        case 1:
            if request.likes.count > 0 {
                return "Voted By"
            }
            return ""
        default:
            return ""
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && indexPath.row == 2 {
            self.performSegueWithIdentifier("showPlayer", sender: nil)
        }
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier {
            switch identifier {
            case "showPlayer":
                let previewPlayerVC = segue.destinationViewController as PreviewPlayerViewController
                previewPlayerVC.songUrl = request.url
                previewPlayerVC.title = request.title
            default:
                break
            }
        }
    }

}
