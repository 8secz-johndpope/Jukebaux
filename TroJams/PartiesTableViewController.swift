//
//  PartiesTableViewController.swift
//  TroJams
//
//  Created by Adam Moffitt on 1/24/17.
//  Copyright © 2017 Adam's Apps. All rights reserved.
//

import UIKit

class PartiesTableViewController: UITableViewController, UINavigationControllerDelegate {
    
    let SharedTrojamsModel = TroJamsModel.shared
    var parties : Array<Party>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        parties = SharedTrojamsModel.parties
        self.navigationController?.delegate = self
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        if viewController is PartiesTableViewController {
            
            viewController.viewWillAppear(true)
        }
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if( SharedTrojamsModel.parties.count == nil) {
            return 0
        }
        else {
            return SharedTrojamsModel.parties.count
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PartyCell", for: indexPath) as! PartyTableViewCell
        
        let party = SharedTrojamsModel.parties[indexPath.row]
        
        let partyImage = party.image
        let partyName = party.partyName
        let hostName = party.hostName
        let numberJoined = party.numberJoined
        
        cell.hostName.text = hostName
        cell.partyName.text = partyName
        cell.numberJoined.text = String(describing: numberJoined)
        cell.partyImage.image = partyImage
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
            SharedTrojamsModel.currentPartyIndex = indexPath!.row
            let party = SharedTrojamsModel.parties[indexPath!.row]
            print("Show Party Segue \(party.partyName)")
            let partyViewController = segue.destination as! PartyViewController
            partyViewController.party = party
            partyViewController.partyImageImage = party.image
            partyViewController.partyName = party.partyName
                print("passing party to partyviewcontroller")
            }
        }
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
