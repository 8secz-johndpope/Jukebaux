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
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        IQKeyboardManager.sharedManager().enable = true
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print(error)
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        do {
           // try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
            //try AVAudioSession.sharedInstance().setActive(false)
            let applicationMusicPlayer = MPMusicPlayerController.applicationMusicPlayer()
            applicationMusicPlayer.pause()
            
        } catch {
            print(error)
        }
    }

    /*
    private var _drawerViewController: KGDrawerViewController?
    var drawerViewController: KGDrawerViewController {
        get {
            if let viewController = _drawerViewController {
                return viewController
            }
            return prepareDrawerViewController()
        }
    }
    
    func prepareDrawerViewController() -> KGDrawerViewController {
        let drawerViewController = KGDrawerViewController()
        
        drawerViewController.centerViewController = drawerSettingsViewController()
        drawerViewController.leftViewController = leftViewController()
        // drawerViewController.rightViewController = rightViewController()
        drawerViewController.backgroundImage = UIImage(named: "purpleBackground")
        
        _drawerViewController = drawerViewController
        
        return drawerViewController
    }
    
    private func drawerStoryboard() -> UIStoryboard {
        let storyboard = UIStoryboard(name: kKGDrawersStoryboardName, bundle: nil)
        return storyboard
    }
    
    private func viewControllerForStoryboardId(storyboardId: String) -> UIViewController {
        let viewController: UIViewController = drawerStoryboard().instantiateViewControllerWithIdentifier(storyboardId)
        return viewController
    }
    
    func drawerSettingsViewController() -> UIViewController {
        let viewController = viewControllerForStoryboardId(kKGDrawerSettingsViewControllerStoryboardId)
        return viewController
    }
    
    func sourcePageViewController() -> UIViewController {
        let viewController = viewControllerForStoryboardId(kKGDrawerWebViewViewControllerStoryboardId)
        return viewController
    }
    
    private func leftViewController() -> UIViewController {
        let viewController = viewControllerForStoryboardId(kKGLeftDrawerStoryboardId)
        return viewController
    }
    
    private func rightViewController() -> UIViewController {
        let viewController = viewControllerForStoryboardId(kKGRightDrawerStoryboardId)
        return viewController
    }
    
    func toggleLeftDrawer(sender:AnyObject, animated:Bool) {
        _drawerViewController?.toggleDrawer(.Left, animated: true, complete: { (finished) -> Void in
            // do nothing
        })
    }
    
    func toggleRightDrawer(sender:AnyObject, animated:Bool) {
        _drawerViewController?.toggleDrawer(.Right, animated: true, complete: { (finished) -> Void in
            // do nothing
        })
    }
    
    private var _centerViewController: UIViewController?
    var centerViewController: UIViewController {
        get {
            if let viewController = _centerViewController {
                return viewController
            }
            return drawerSettingsViewController()
        }
        set {
            if let drawerViewController = _drawerViewController {
                drawerViewController.closeDrawer(drawerViewController.currentlyOpenedSide, animated: true) { finished in }
                if drawerViewController.centerViewController != newValue {
                    drawerViewController.centerViewController = newValue
                }
            }
            _centerViewController = newValue
        }
    }
    */

}

