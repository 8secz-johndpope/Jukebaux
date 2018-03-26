//
//  AppDelegate.swift
//  JamSesh
//
//  Created by Adam Moffitt on 1/24/17.
//  Copyright © 2017 Adam's Apps. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import IQKeyboardManagerSwift
import AVFoundation
import MediaPlayer
import KYDrawerController
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    
    var window: UIWindow?
    var drawerController = KYDrawerController.init(drawerDirection: .left, drawerWidth: 300)
    
//    let mainViewController = PartiesTableViewController()
//    let drawerViewController = LeftDrawerTableViewController()
//    let storyboard = UIStoryboard(name: "Main", bundle: nil)
//    let drawerController = storyboard.instantiateViewController(withIdentifier: "KYDrawerControllerId") as! KYDrawerController
//    drawerController.mainViewController = UINavigationController(
//        rootViewController: mainViewController
//    )
//    drawerController.drawerViewController = drawerViewController
    
    override init() {
        super.init()
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = false
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        //GIDSignIn.sharedInstance().signOut()

        let partyMusicHandler = PlayMusicHandler.shared
        partyMusicHandler.stopSystemMusicPlayer()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        IQKeyboardManager.sharedManager().enable = true
//        do {
//            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
//            try AVAudioSession.sharedInstance().setActive(false)
//        } catch {
//            print(error)
//        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        let partyMusicHandler = PlayMusicHandler.shared
        UIApplication.shared.beginReceivingRemoteControlEvents()
        //partyMusicHandler.applicationMusicPlayer.pause()
        if JamSeshModel.shared.currentPartyIndex < JamSeshModel.shared.parties.count {
            let party = JamSeshModel.shared.parties[JamSeshModel.shared.currentPartyIndex]
            var trackIDsInPlaylist :[String] = []
            for song in party.songs {
                trackIDsInPlaylist.append(String(describing: song.songID))
            }
            print("did enter background: \(trackIDsInPlaylist)")
            partyMusicHandler.applicationMusicPlayer.setQueue(with: trackIDsInPlaylist)
            // partyMusicHandler.setupNowPlayingInfoCenter()
            print("bye bye")
        }
        
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        let partyMusicHandler = PlayMusicHandler.shared
        if partyMusicHandler.getPlaybackState() == MPMusicPlaybackState.paused {
            print("resuming upon entering foreground")
            partyMusicHandler.applicationMusicPlayer.play()
        }
        //partyMusicHandler.clearQueue()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        do {
            let partyMusicHandler = PlayMusicHandler.shared
            print("APP ENDING STOP PARTYMUSICHANDLER")
            partyMusicHandler.stop()
            partyMusicHandler.stopSystemMusicPlayer()
            
        } catch {
            print(error)
        }
    }
    
  
}

