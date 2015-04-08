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
                    
                    // AVAudio Session
                    
                    var activeError: NSError? = nil
                    AVAudioSession.sharedInstance().setActive(true, error: &activeError)
                    if let actError = activeError {
                        NSLog("Error setting audio active: \(actError.code)")
                    }
                    
                    var categoryError: NSError? = nil
                    AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, error: &categoryError)
                    if let catError = categoryError {
                        NSLog("Error setting audio category: \(catError.code)")
                    }
                    
                    NSNotificationCenter.defaultCenter().addObserver(self, selector: "remoteControlEventNotification:", name:"RemoteControlEventReceived", object: nil)
                }
            }
        }
    }
    
    func onStop() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "AVPlayerItemDidPlayToEndTimeNotification", object: nil)
        delegate?.onStop()
    }
    
//    func exit() {
//        self.playerController.player?.pause()
//        self.playerController.view.removeFromSuperview()
//        
//        var activeError: NSError? = nil
//        AVAudioSession.sharedInstance().setActive(false, error: &activeError)
//        if let actError = activeError {
//            NSLog("Error setting audio active: \(actError.code)")
//        }
//        
//        var categoryError: NSError? = nil
//        AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient, error: &categoryError)
//        if let catError = categoryError {
//            NSLog("Error setting audio category: \(catError.code)")
//        }
//        
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: "AVPlayerItemDidPlayToEndTimeNotification", object: nil)
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: "RemoteControlEventReceived", object: nil)
//    }
    
    func reDraw() {
        self.setNeedsDisplay()
    }
    
    func remoteControlEventNotification(note: NSNotification) {
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "RemoteControlEventReceived", object: nil)
        
        let event: UIEvent = note.object as! UIEvent
        println("remote control event")
        if event.type == UIEventType.RemoteControl {
            println("event.type = \(event.type.rawValue)")
            println("event.subtype = \(event.subtype.rawValue)")
            switch event.subtype {
            case UIEventSubtype.RemoteControlPause:
                // Toggle play pause
                println("pause")
                //self.playerLayer.player.pause()
                self.playerController.player?.pause()
            case UIEventSubtype.RemoteControlPlay:
                println("play")
                //self.playerLayer.player.play()
                self.playerController.player?.play()
            case UIEventSubtype.RemoteControlNextTrack:
                println("skip")
            default:
                println("default \(event)")
                break
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "remoteControlEventNotification:", name:"RemoteControlEventReceived", object: nil)
    }

}
