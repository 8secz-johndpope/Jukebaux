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

class PartiesTableViewController: UITableViewController, UINavigationControllerDelegate {
    
    let SharedJamSeshModel = JamSeshModel.shared
    var parties : [Party] = []
    var handle : FIRDatabaseHandle = FIRDatabaseHandle()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("1 PartiesViewController did load")
        self.navigationController?.delegate = self
        self.navigationController?.navigationBar.barTintColor = UIColor.purple
        self.refreshControl?.addTarget(self, action: #selector(PartiesTableViewController.handleRefresh(refreshControl:)), for: UIControlEvents.valueChanged)
        
        loadPartiesFromFirebase()
        //loadData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("2 PartiesViewController will appear")
        //loadPartiesFromFirebase()
        self.tableView.reloadData()
    }
    
    func loadPartiesFromFirebase() {
        print("****************************1")
        handle = SharedJamSeshModel.ref.child("parties").observe(FIRDataEventType.value, with: { (snapshot) in
            if !snapshot.exists() {
                print("snapshot of parties doesnt exist")
                return
            }
            var i = 0
            var newParties : [Party] = []
            for child in (snapshot.children.allObjects as? [FIRDataSnapshot])! {
                
                //*************************
                print("LOADPARTIESFROMFIREBASE: \(i) - \((child.value as? NSDictionary)?["partyName"]!)")
                i += 1
                let party = Party(snapshot: child as! FIRDataSnapshot)
                newParties.append(party)
                //*************************
            }
            self.SharedJamSeshModel.parties = newParties
            self.tableView.reloadData()
        })
        print("Handle: \(handle)")
        print("***************************2")
    }
    
    func loadData() {
        var activityIndicatorView = NVActivityIndicatorView(frame: self.view.frame, type: .lineScalePulseOut, color: UIColor.purple, padding: CGFloat(0))
        print("****************refresh***************")
        
        activityIndicatorView.startAnimating()
        SharedJamSeshModel.loadFromFirebase(completionHandler: {_ in
        print("completion handler")
        self.parties = self.SharedJamSeshModel.parties
        self.parties.sort() { $0.numberJoined > $1.numberJoined }
        self.tableView.reloadData()
        print("****************refreshEnding***************")
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
        if( SharedJamSeshModel.parties.count == nil) {
            return 0
        }
        else {
            return SharedJamSeshModel.parties.count
        }
        
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PartyCell", for: indexPath) as! PartyTableViewCell
        
        let party = SharedJamSeshModel.parties[indexPath.row]
        
        var partyImage = party.image
        let partyName = party.partyName
        let hostName = party.hostName //TODO add host functionality
        let numberJoined = party.numberJoined
        print("tableview party name: \(partyName) \(hostName) \(numberJoined)")
        
        cell.hostName.text = hostName
        cell.partyName.text = partyName
        cell.numberJoined.text = String(describing: numberJoined)
        cell.partyImage.image = partyImage
        cell.partyImage.contentMode = UIViewContentMode.scaleAspectFill
        
        //get party image from firebase
        let FBSavedImageURL = party.savedImageURL
        if  let url = URL(string: FBSavedImageURL){
            print(FBSavedImageURL)
            print("^^^^")
            URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                
                //ran into some download error
                if error != nil {
                    print(error)
                    return
                }
                print("got image yay!")
                if let data1 = data {
                    DispatchQueue.main.async {
                        partyImage = UIImage(data: data1)!
                        self.SharedJamSeshModel.parties[indexPath.row].image = partyImage
                        cell.partyImage.image = partyImage
                    }
                }
            }).resume()
        }
        
        return cell
    }
    
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    
    
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ShowPartySegue") {
            let cell = sender as! UITableViewCell
            let indexPath = tableView.indexPath(for: cell)
            SharedJamSeshModel.currentPartyIndex = indexPath!.row
            
            
            //add user to joined in party
            SharedJamSeshModel.ref.child("parties").child(SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].partyID).child("users").child(SharedJamSeshModel.myUser.username).setValue(SharedJamSeshModel.myUser.username)
            
            //increase the number joined in the party in transaction block to avoid concurrency issues
            SharedJamSeshModel.ref.child("parties").child(SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].partyID).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                if var post = currentData.value as? [String : AnyObject] {
                    //increment the number joined by 1
                    var numberJoined = post["numberJoined"] as? Int ?? 0
                    post["numberJoined"] = numberJoined + 1 as AnyObject?
                    // Set value and report transaction success
                    currentData.value = post
                    return FIRTransactionResult.success(withValue: currentData)
                }
                return FIRTransactionResult.success(withValue: currentData)
            }) { (error, committed, snapshot) in
                if let error = error {
                    print(error.localizedDescription)
                }
            }
            
            //remove the parties observer so that observer is not duplicated in each individual party view controller
            print("remove parties handle \(handle)")
            SharedJamSeshModel.ref.child("parties").removeObserver(withHandle: handle)
            
            let party = SharedJamSeshModel.parties[indexPath!.row]
            print("Show Party Segue \(party.partyName)")
            print("Host: \(party.hostName) vs \(SharedJamSeshModel.myUser.username)")
            
            let partyViewController = segue.destination as! PartyViewController
            partyViewController.party = party
            print("passing party to partyviewcontroller")
        }
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
    /*
     let baseURL = "http://www.citi.io/wp-content/uploads/2015/08/1168-00-06.jpg"
     var imageURL = NSURL(string: "")
     
     let imagePath = party!.imageURL as String
     if(imagePath != nil && imagePath != ""){
     imageURL = NSURL(string: imagePath)
     } else {
     imageURL = NSURL(string: baseURL)
     
     }
     DispatchQueue.global().async {
     let data = try? Data(contentsOf: imageURL! as URL) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
     DispatchQueue.main.async {
     cell.partyImage.image = UIImage(data: data!)
     } 
     */
}
