//
//  ProfileTableViewCell.swift
//  musicApp7
//
//  Created by Ido Ben-Natan on 2/20/15.
//  Copyright (c) 2015 Ido Ben-Natan. All rights reserved.
//

import UIKit

class ProfileTableViewCell: UITableViewCell {


    @IBOutlet weak var userImage: UIImageView! {
        didSet {
            userImage.layer.cornerRadius = 25
            userImage.layer.masksToBounds = true
            userImage.frame = CGRectMake(userImage.frame.origin.x, userImage.frame.origin.y, 100, 100)
            
            // NSLayoutConstraint(item: new_view, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0)
            
            //let constraintX = NSLayoutConstraint(item: self.contentView, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: userImage, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
            //self.contentView.addConstraint(constraintX)
            
            //let constraintY = NSLayoutConstraint(item: self.contentView, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: userImage, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
            //self.contentView.addConstraint(constraintY)
        }
    }
    
    @IBOutlet weak var userName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
