//
//  PartiesTableViewController.swift
//  JamSesh
//
//  Created by Adam Moffitt on 1/24/17.
//  Copyright © 2017 Adam's Apps. All rights reserved.
//

import UIKit
import FirebaseDatabase
import NVActivityIndicatorView
import AMWaveTransition
import KYDrawerController
import SCLAlertView

class PartiesTableViewController: UITableViewController, UINavigationControllerDelegate {
    
    let SharedJamSeshModel = JamSeshModel.shared
    var parties : [Party] = []
    var handle : DatabaseHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        let storyboard = UIStoryboard(name: "main", bundle: nil)
//        self.leftViewController = storyboard().instantiateViewControllerWithIdentifier(storyboardId)
//        return viewController
        self.navigationController?.delegate = self
        self.navigationController?.navigationBar.barTintColor = UIColor.purple
        self.refreshControl?.addTarget(self, action: #selector(PartiesTableViewController.handleRefresh(refreshControl:)), for: UIControlEvents.valueChanged)
        
        loadPartiesFromFirebase()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    deinit {
        if let refHandle = handle {
            SharedJamSeshModel.ref.removeObserver(withHandle: refHandle)
        }
    }
    
    @IBAction func leftDrawerButtonPressed(_ sender: Any) {
        print("left drawer pressed")
        
        let appDel = UIApplication.shared.delegate as! AppDelegate
        appDel.drawerController.setDrawerState(.opened, animated: true)
        
        // let elDrawer = self.navigationController?.parent;
        // (elDrawer as! KYDrawerController).setDrawerState(KYDrawerController.DrawerState.opened, animated: true);
    }
    
    func loadPartiesFromFirebase() {
        handle = SharedJamSeshModel.ref.child("parties").observe(DataEventType.value, with: { (snapshot) in
            if !snapshot.exists() {
                return
            }
            
            var newParties : [Party] = []
            for child in (snapshot.children.allObjects as? [DataSnapshot])! {
                //*************************
                let party = Party(snapshot: child)
                newParties.append(party)
                //*************************
            }
            
            self.SharedJamSeshModel.parties = newParties
            
            for (index, party) in self.SharedJamSeshModel.parties.enumerated() {
                let FBSavedImageURL = party.savedImageURL
                if  let url = URL(string: FBSavedImageURL){
                    URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                        
                        //ran into some download error
                        if error != nil {
                            return
                        }
                        if let data1 = data {
                            DispatchQueue.main.async {
                                self.SharedJamSeshModel.parties[index].image = UIImage(data: data1)!
                                let rowToReload = IndexPath.init(row: index, section: 0)
                                let rowsToReload = Array.init(arrayLiteral: rowToReload)
                                self.tableView.reloadRows(at: rowsToReload, with: .automatic)
                                print("reload row: \(index)")
                            }
                        }
                    }).resume()
                }
            }
            
            self.tableView.reloadData()
        })
    }
    
    func loadData() {
        let activityIndicatorView = NVActivityIndicatorView(frame: self.view.frame, type: .lineScalePulseOut, color: UIColor.purple, padding: CGFloat(0))
        
        activityIndicatorView.startAnimating()
        SharedJamSeshModel.loadFromFirebase(completionHandler: {_ in
        self.parties = self.SharedJamSeshModel.parties
        self.parties.sort() { $0.numberJoined > $1.numberJoined }
        self.tableView.reloadData()
        activityIndicatorView.stopAnimating()
        })
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        loadData()
        refreshControl.endRefreshing()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return SharedJamSeshModel.parties.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PartyCell", for: indexPath) as! PartyTableViewCell
        
        let party = SharedJamSeshModel.parties[indexPath.row]
        
        let partyImage = party.image
        let partyName = party.partyName
        let hostName = party.hostName //TODO add host functionality
        let numberJoined = party.numberJoined
        
        cell.hostName.text = hostName
        cell.partyName.text = partyName
        cell.numberJoined.text = String(describing: numberJoined)
        cell.partyImage.image = partyImage
        cell.partyImage.contentMode = UIViewContentMode.scaleAspectFill
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ShowPartySegue") {
            let cell = sender as! UITableViewCell
            let indexPath = tableView.indexPath(for: cell)
            SharedJamSeshModel.currentPartyIndex = indexPath!.row
            
            
            //add user to joined in party
            SharedJamSeshModel.ref.child("parties").child(SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].partyID).child("users").child(SharedJamSeshModel.myUser.username).setValue(SharedJamSeshModel.myUser.username)
            
            //increase the number joined in the party in transaction block to avoid concurrency issues
            SharedJamSeshModel.ref.child("parties").child(SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].partyID).runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                if var post = currentData.value as? [String : AnyObject] {
                    //increment the number joined by 1
                    let numberJoined = post["numberJoined"] as? Int ?? 0
                    post["numberJoined"] = numberJoined + 1 as AnyObject?
                    // Set value and report transaction success
                    currentData.value = post
                    return TransactionResult.success(withValue: currentData)
                }
                return TransactionResult.success(withValue: currentData)
            }) { (error, committed, snapshot) in
                if let error = error {
                    print(error.localizedDescription)
                }
            }
            
            //remove the parties observer so that observer is not duplicated in each individual party view controller
            SharedJamSeshModel.ref.child("parties").removeObserver(withHandle: handle!)
            
            let party = SharedJamSeshModel.parties[indexPath!.row]
            
            let partyViewController = segue.destination as! PartyViewController
        }
    }
    
    func warnHostOfLeavingParty() {
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton: true
        )
        let alertView = SCLAlertView(appearance: appearance)
        alertView.addButton("Join Party") {
            
        }
        alertView.showInfo("Cancel your current Party?", subTitle: "You are currently hosting a party, and joining a different party will cause your current party to be canceled. Are you sure you want to leave your party?")
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if (operation != UINavigationControllerOperation.none) {
            // Return your preferred transition operation
            return AMWaveTransition(operation: operation)
        }
        return nil
    }
    
    func visibleCells() -> (NSArray) {
        return self.tableView.visibleCells as (NSArray)
    }
}
