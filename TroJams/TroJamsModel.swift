//
//  TroJamsModel.swift
//  TroJams
//
//  Created by Adam Moffitt on 1/24/17.
//  Copyright © 2017 Adam's Apps. All rights reserved.
//

import UIKit

class TroJamsModel {

    var parties : [Party] = [Party(name: "Adam's Party" , partyImage: UIImage(named: "party")!, privateParty: false, password: "")]
    var currentPartyIndex: Int = 0
    
    
    //singleton
    static var shared = TroJamsModel()
    
    init() {
        let url1 = URL(string: "http://viterbivoices.usc.edu/wp-content/uploads/2012/10/DSC01216.jpg")
        if let data = try? Data(contentsOf: url1!)  {
        self.newParty(name: "SAL Party" , partyImage: UIImage(data: data)!, privateParty: false, password: "")
    }
        
        let url2 = URL(string: "https://s-media-cache-ak0.pinimg.com/originals/5a/24/9f/5a249f35cb3b98db5d1a4b669d1f2bcd.jpg")
        if let data = try? Data(contentsOf: url2!) {
        self.newParty(name: "Pirate Party" , partyImage: UIImage(data: data)!, privateParty: false, password: "")
        }
        
        /*
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url1!)  {//make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                DispatchQueue.main.async {
                    self.newParty(name: "SAL Party" , partyImage: UIImage(data: data)!, privateParty: false, password: "")
                }
            }
        }

        
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url2!) { //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
            DispatchQueue.main.async {
               self.newParty(name: "Pirate Party" , partyImage: UIImage(data: data)!, privateParty: false, password: "")
                }
            }
        }
 */
    }
    
    func newParty(name: String , partyImage: UIImage, privateParty: Bool, password: String) {
        parties.append(Party(name: name , partyImage: partyImage, privateParty: privateParty, password: password))
    }
    
    }
