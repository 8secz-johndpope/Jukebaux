//
//  LeftDrawerTableViewController.swift
//  JamSesh
//
//  Created by Adam Moffitt on 1/17/18.
//  Copyright © 2018 Adam's Apps. All rights reserved.
//

import UIKit
import KYDrawerController

class LeftDrawerTableViewController: UITableViewController {
    
    let backgroundImage = UIImage(named: "purpleBackground")
    let menu = ["Parties", "Party", "Logout"]
    
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
        
        cell.textLabel?.text = menu[indexPath.row] as! String
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // let elDrawer : KYDrawerController = self.navigationController!.parent as! KYDrawerController;
        // let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewController") as UIViewController
        // self.present(viewController, animated: false, completion: nil)
        
        // let navController = viewController.navigationController
        
        let appDel = UIApplication.shared.delegate as! AppDelegate
        
        switch (indexPath.row) {
        case 0:do {
            let partiesVC = self.storyboard?.instantiateViewController(withIdentifier: "partiesNavVC")
            appDel.drawerController.mainViewController = partiesVC
            break;
            }
        case 1:do{
            let partyVC = self.storyboard?.instantiateViewController(withIdentifier: "partyVC") as! PartyViewController
            appDel.drawerController.mainViewController = partyVC
            break;
            }
        case 2:do{ //logout
            let userDefaults = UserDefaults.standard
            userDefaults.removeObject(forKey: "email")
            userDefaults.removeObject(forKey: "password")
            let signInVC = self.storyboard?.instantiateViewController(withIdentifier: "signInVC") as! LogInViewController
            appDel.drawerController.mainViewController = signInVC
            break;
            }
        default:do {
            let partiesVC = self.storyboard?.instantiateViewController(withIdentifier: "partiesNavVC") as! PartiesTableViewController
            appDel.drawerController.mainViewController = partiesVC
            break;
            }
        }
        // elDrawer.mainViewController=navController;
        // (elDrawer as KYDrawerController).setDrawerState(KYDrawerController.DrawerState.closed, animated: true)
    }
    
}

