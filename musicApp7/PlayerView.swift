//
//  PlayerView.swift
//  musicApp7
//
//  Created by Ido Ben-Natan on 2/18/15.
//  Copyright (c) 2015 Ido Ben-Natan. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

protocol PlayerViewDelegate {
    func nextPlayerUrl(completionHandler: (String?) -> Void)
    func onStop()
}

class PlayerView: UIView {
    
    var delegate: PlayerViewDelegate?
    var playerController = AVPlayerViewController()
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        delegate?.nextPlayerUrl {
            urlStr in
            if urlStr != nil {
                if let url = NSURL(string: urlStr!) {
                    let playerItem = AVPlayerItem(URL: url)
                    
                    if let moviePlayer = self.playerController.player {
                        moviePlayer.replaceCurrentItemWithPlayerItem(playerItem)
                    } else {
                        self.playerController.view.frame = rect
                        self.addSubview(self.playerController.view)
                        self.playerController.player = AVPlayer(playerItem: playerItem)
                    }
                    
                    self.playerController.player.play()
                
                    
                    NSNotificationCenter.defaultCenter().addObserver(self, selector: "onStop", name: "AVPlayerItemDidPlayToEndTimeNotification", object: nil)
                }
            }
        }
    }
    
    func onStop() {
        delegate?.onStop()
    }
    
    func reDraw() {
        self.setNeedsDisplay()
    }

}
