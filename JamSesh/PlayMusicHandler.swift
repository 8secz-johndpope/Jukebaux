//
//  PlayMusicHandler.swift
//  JamSesh
//
//  Created by Adam Moffitt on 5/17/17.
//  Copyright © 2017 Adam's Apps. All rights reserved.
//

import UIKit
import StoreKit
import MediaPlayer

class PlayMusicHandler: NSObject {

    let applicationMusicPlayer = MPMusicPlayerController.applicationMusicPlayer
    
    let serviceController = SKCloudServiceController()
    var storefrontID : String
    //singleton
    static var shared = PlayMusicHandler()
    
    override init(){
        storefrontID = "0"
        applicationMusicPlayer.beginGeneratingPlaybackNotifications()
    }
    
    //*******************************PLAY MUSIC METHODS ***********************************
    
    // Check if the device is capable of playback
    func appleMusicCheckIfDeviceCanPlayback() {
        serviceController.requestCapabilities { (capability:SKCloudServiceCapability, err:Error?) -> Void in
                if capability.contains(SKCloudServiceCapability.musicCatalogPlayback) {
                    print("The user has an Apple Music subscription and can playback music!")
                    
                } else if  capability.contains(SKCloudServiceCapability.addToCloudMusicLibrary) {
                    print("The user has an Apple Music subscription, can playback music AND can add to the Cloud Music Library")
                    
                } else {
                    print("The user doesn't have an Apple Music subscription available. Now would be a good time to prompt them to buy one?")
                    // TOOO hunget got this error but he pays for apple music ...
                }  
            }
    }
    
    // Request permission from the user to access the Apple Music library
    func appleMusicRequestPermission() {
        
        switch SKCloudServiceController.authorizationStatus() {
            
        case .authorized:
            
            print("The user's already authorized - we don't need to do anything more here, so we'll exit early.")
            return
            
        case .denied:
            
            print("The user has selected 'Don't Allow' in the past - so we're going to show them a different dialog to push them through to their Settings page and change their mind, and exit the function early.")
            
            // Show an alert to guide users into the Settings
            
            return
            
        case .notDetermined:
            
            print("The user hasn't decided yet - so we'll break out of the switch and ask them.")
            break
            
        case .restricted:
            
            print("User may be restricted; for example, if the device is in Education mode, it limits external Apple Music usage. This is similar behaviour to Denied.")
            return
            
        }
        
        SKCloudServiceController.requestAuthorization { (status:SKCloudServiceAuthorizationStatus) in
            
            switch status {
                
            case .authorized:
                
                print("All good - the user tapped 'OK', so you're clear to move forward and start playing.")
                
            case .denied:
                
                print("The user tapped 'Don't allow'. Read on about that below...")
                
            case .notDetermined:
                
                print("The user hasn't decided or it's not clear whether they've confirmed or denied.")
                
            default: break
                
            }
            
        }
        
    }
    
    // Fetch the user's storefront ID
    func appleMusicFetchStorefrontRegion() {
    
        serviceController.requestStorefrontIdentifier { (storefrontId:String?, err:Error?) -> Void in
            
            guard err == nil else {
                
                print("An error occured. Handle it here.")
                return
                
            }
            
            guard let storefrontId = storefrontId else {
                
                print("Handle the error - the callback didn't contain a storefront ID.")
                return
                
            }
        
        let startIndex = storefrontId.index(storefrontId.startIndex, offsetBy: 0)
        let fifthLetterIndex = storefrontId.index(storefrontId.startIndex, offsetBy: 4)
        let indexRange = startIndex..<fifthLetterIndex
        self.storefrontID = storefrontId.substring(with: indexRange)
        
        print("Success! The user's storefront ID is: \(self.storefrontID)")
        
        }
    }
    
    func getPlaybackState() -> MPMusicPlaybackState {
        return applicationMusicPlayer.playbackState
    }
    
    func getCurrentPlaybackTime() -> TimeInterval {
        return applicationMusicPlayer.currentPlaybackTime
    }
    
    func setCurrentPlaybackTime(time: TimeInterval) {
        applicationMusicPlayer.currentPlaybackTime = time
    }
    
    func appleMusicPlayTrackId(ids:[String]) {
        applicationMusicPlayer.setQueue(with: ids)
        applicationMusicPlayer.play()
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    func clearQueue() {
        applicationMusicPlayer.setQueue(with: [""])
    }
    
    func nextSong() {
        applicationMusicPlayer.currentPlaybackTime = 0
        applicationMusicPlayer.skipToNextItem()
    }
    
    func prevSong() {
        applicationMusicPlayer.skipToPreviousItem()
    }
    
    func skipToBeginning() {
        applicationMusicPlayer.skipToBeginning()
    }
    
    func playPause() {
        if(applicationMusicPlayer.playbackState==MPMusicPlaybackState.paused){
            applicationMusicPlayer.play()
        } else if(applicationMusicPlayer.playbackState==MPMusicPlaybackState.playing){
            applicationMusicPlayer.pause()
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    func stop() {
        applicationMusicPlayer.stop()
    }
    
    func playCloser() {
        applicationMusicPlayer.setQueue(with: ["1170699703"])
        applicationMusicPlayer.play()
    }
    
     func setupNowPlayingInfoCenter() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        self.updateNowPlayingInfoCenter(artwork: UIImage())
        MPRemoteCommandCenter.shared().playCommand.addTarget {event in
            self.applicationMusicPlayer.play()
            self.updateNowPlayingInfoCenter()
            return .success
        }
        MPRemoteCommandCenter.shared().pauseCommand.addTarget {event in
            self.applicationMusicPlayer.pause()
            return .success
        }
        MPRemoteCommandCenter.shared().nextTrackCommand.addTarget {event in
            print("party music handler skip")
            self.nextSong()
            return .success
        }
        MPRemoteCommandCenter.shared().previousTrackCommand.addTarget {event in
            self.prevSong()
            return .success
        }
    }
    
     func updateNowPlayingInfoCenter(artwork: UIImage? = nil) {
        guard let file = applicationMusicPlayer.nowPlayingItem else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [String: AnyObject]()
            return
        }
        print("file: \(file.title)")
        
            if let imageURL = URL(string: JamSeshModel.shared.parties[JamSeshModel.shared.currentPartyIndex].currentSong.songImageURL) {
                URLSession.shared.dataTask(with: imageURL, completionHandler: { (data, response, error) in
                        //ran into some download error
                        if error != nil {
                            return
                        }
                    print("hi")
                    MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: UIImage(data: data!)!)
                })
            }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: file.title ?? "Test",
//            MPMediaItemPropertyAlbumTitle: file.albumTitle ?? "",
//            MPMediaItemPropertyArtist: file.artist ?? "",
//            MPMediaItemPropertyPlaybackDuration: applicationMusicPlayer.nowPlayingItem?.playbackDuration,
//            MPNowPlayingInfoPropertyElapsedPlaybackTime: applicationMusicPlayer.currentPlaybackTime
        ]
    }
    func stopSystemMusicPlayer() {
        MPMusicPlayerController.systemMusicPlayer.stop()
    }
}
