//
//  LeftDrawerTableViewController.swift
//  JamSesh
//
//  Created by Adam Moffitt on 1/17/18.
//  Copyright © 2018 Adam's Apps. All rights reserved.
//

import UIKit
import KYDrawerController
import FirebaseAuth
import FirebaseInvites
import GoogleSignIn

class LeftDrawerTableViewController: UITableViewController, InviteDelegate {
    
    let backgroundImage = UIImage(named: "purpleBackground")
    let menu = ["Parties", "Invite Friends", "Logout"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LabelCell")
        
        let backgroundImage = UIImage(named: "purpleBackground")
        let imageView = UIImageView(image: backgroundImage)
        // center and scale background image
        imageView.contentMode = .scaleAspectFill
        self.tableView.backgroundView = imageView
        
        /* to blur background image
         let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
         let blurView = UIVisualEffectView(effect: blurEffect)
         blurView.frame = imageView.bounds
         imageView.addSubview(blurView)
         */
        
        // no lines where there aren't cells
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = .clear
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menu.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LabelCell", for: indexPath)
        cell.backgroundColor = .clear
        cell.textLabel?.text = menu[indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let appDel = UIApplication.shared.delegate as! AppDelegate
        
        switch (indexPath.row) {
        case 0: // show parties
            let partiesVC = self.storyboard?.instantiateViewController(withIdentifier: "partiesNavVC")
            appDel.drawerController.mainViewController = partiesVC
            appDel.drawerController.setDrawerState(.closed, animated: true)
        case 1: // invite
            self.sendInvite()
        case 2: // logout
            let userDefaults = UserDefaults.standard
            userDefaults.removeObject(forKey: "email")
            userDefaults.removeObject(forKey: "password")
            let firebaseAuth = Auth.auth()
            do {
                try firebaseAuth.signOut()
            } catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
            }
            GIDSignIn.sharedInstance().signOut()
            let signInVC = self.storyboard?.instantiateViewController(withIdentifier: "signInVC") as! LogInViewController
            appDel.drawerController.mainViewController = signInVC
            appDel.drawerController.setDrawerState(.closed, animated: true)
            break;
        default:
            break
        }
        
        appDel.drawerController.setDrawerState(.closed, animated: true)
        
    }
    
    func sendInvite() {
        if let invite = Invites.inviteDialog() {
            invite.setInviteDelegate(self)
            
            // NOTE: You must have the App Store ID set in your developer console project
            // in order for invitations to successfully be sent.
            
            // A message hint for the dialog. Note this manifests differently depending on the
            // received invitation type. For example, in an email invite this appears as the subject.
            invite.setMessage("Hey, come join the party and control the music with Jukebaux!\n -\(JamSeshModel.shared.myUser.username)")
            // Title for the dialog, this is what the user sees before sending the invites.
            invite.setTitle("Control the music with Jukebaux!")
            //invite.setDeepLink(SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].partyID)
            invite.setCallToActionText("Install!")
            invite.setCustomImage("http://adammoffitt.me/images/jukebauxLogo.png")
            invite.open()
        }
    }
    func inviteFinished(withInvitations invitationIds: [String], error: Error?) {
        if let error = error {
            print("Failed: " + error.localizedDescription)
        } else {
            print("\(invitationIds.count) invites sent")
        }
    }
}

