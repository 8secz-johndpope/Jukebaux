//
//  JamSeshModel.swift
//  JamSesh
//
//  Created by Adam Moffitt on 1/24/17.
//  Copyright © 2017 Adam's Apps. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import SwiftyJSON

class JamSeshModel {
    
    var parties : [Party] = []
    var currentPartyIndex: Int = 0
    var ref: DatabaseReference!
    var partiesChanged = true
    var storage : Storage
    var storageRef : StorageReference
    var myUser : User
    var topTracks : [String:String] = [:]
    
    // R: 149 G: 83 B: 207
    var mainJamSeshColor = UIColor(red: 149.0/255.0, green: 83.0/255.0, blue: 207.0/255.0, alpha: 1)
    var mainJamSeshColorInt = 9786319
    
    //singleton
    static var shared = JamSeshModel()
    
    init() {
        ref = Database.database().reference()
        
        // Get a reference to the storage service using the default Firebase App
        storage = Storage.storage()
        // Create a storage reference from our storage service
        storageRef = storage.reference()
        
        myUser = User()
    }
    
    func newParty(name: String , partyImage: UIImage, privateParty: Bool, password: String, numberJoined: Int, hostName: String, hostID: String) {
        
        //add new party to firebase
        let partyID = NSUUID().uuidString
        
        //upload image
        let tempImageName = NSUUID().uuidString
        let tempStorageRef = storageRef.child("\(tempImageName).png")
        var tempSavedImageURL = ""
        if let uploadData = UIImageJPEGRepresentation(partyImage, 0.1) {
            tempStorageRef.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                if error != nil {
                    print (error ?? "Error")
                    return
                }
                
                //save the firebase image url in order to download the image later
                tempSavedImageURL = (metadata?.downloadURL()?.absoluteString)!
                
                let newParty = Party(name: name , partyID: partyID, partyImage: partyImage, savedImageURL: tempSavedImageURL, privateParty: privateParty, password: password, numberJoined: numberJoined, partyPlaylist: [], hostName: hostName, hostID: hostID, users: [self.myUser.username])
                
                //upload to firebase
                self.ref.child("parties").child(partyID).setValue(newParty.toAnyObject())
            })
        } else {
            let newParty = Party(name: name , partyID: partyID, partyImage: partyImage, savedImageURL: tempSavedImageURL, privateParty: privateParty, password: password, numberJoined: numberJoined, partyPlaylist: [], hostName: hostName, hostID: hostID, users: [self.myUser.username])
            
            //upload to firebase
            self.ref.child("parties").child(partyID).setValue(newParty.toAnyObject())
        }
    }
    
    func deletePartyImage(imageName: String) {
        // Create a reference to the file to delete
        let desertRef = storageRef.child("\(imageName).png")
        
        // Delete the file
        desertRef.delete { error in
            if let error = error {
                // Uh-oh, an error occurred!
                print(error)
            } else {
                // File deleted successfully
            }
        }
    }
    
    func setPartySong(song: Song) {
        
        //set current song on firebase
        ref.child("parties").child(parties[currentPartyIndex].partyID).child("currentSong").setValue(song.toAnyObject())
    }
    
    func removePartySong(song: Song) {
        ref.child("parties").child(parties[currentPartyIndex].partyID).child("playlist").child(encodeForFirebaseKey(string: song.songName)).removeValue()
    }
    
    typealias CompletionHandler = (_ success:Bool) -> Void
    
    /******************* New load from firebase - observe *******************/
    func loadFromFirebase(completionHandler: @escaping CompletionHandler) {
        ref.child("parties").queryOrdered(byChild: "numberJoined").observe(DataEventType.value, with: { (snapshot) in
            if !snapshot.exists() {
                return
            }
            var newParties : [Party] = []
            for child in (snapshot.children.allObjects as? [DataSnapshot])! {
                let party = Party(snapshot: child )
                newParties.append(party)
            }
            self.parties = newParties
        })
        completionHandler(true)
    }
    /****************************************************************************/
    
    func setMyUser(newUser: User) {
        myUser = newUser
    }
    
    func addNewUser(newUser: User) {
        print(newUser.toAnyObject())
        ref.child("users").child(newUser.userID).setValue(newUser.toAnyObject())
    }
    
    func userDoneHosting() {
         ref.child("users").child(self.myUser.userID).child("isHost").setValue(false)
    }
    
    func userIsHosting() {
        ref.child("users").child(self.myUser.userID).child("isHost").setValue(true)
    }
    
    //update the numberJoined and playlist of the party
    func updatePartyOnFirebase(party: Party, completionHandler: @escaping CompletionHandler) {
            ref.child("parties").child(party.partyID).child("numberJoined").setValue(party.numberJoined)
            ref.child("parties").child(party.partyID).updateChildValues(party.playlistToAnyObject() as! [AnyHashable : Any])
        completionHandler(true)
    }
    
    func encodeForFirebaseKey(string: String) -> (String){
        var string1 = string.replacingOccurrences(of: "_", with: "__")
        string1 = string1.replacingOccurrences(of: ".", with: "_P")
        string1 = string1.replacingOccurrences(of: "$", with: "_D")
        string1 = string1.replacingOccurrences(of: "#", with: "_H")
        string1 = string1.replacingOccurrences(of: "[", with: "_O")
        string1 = string1.replacingOccurrences(of: "]", with: "_C")
        string1 = string1.replacingOccurrences(of: "/", with: "_S")
        return string1
    }

    func decodeFromFireBaseKey (string: String) -> (String) {
        var string1 = string.replacingOccurrences(of: "__" , with: "_")
        string1 = string1.replacingOccurrences(of: "_P", with: ".")
        string1 = string1.replacingOccurrences(of: "_D", with: "$")
        string1 = string1.replacingOccurrences(of: "_H", with: "#")
        string1 = string1.replacingOccurrences(of: "_O", with: "[")
        string1 = string1.replacingOccurrences(of: "_C", with: "]")
        string1 = string1.replacingOccurrences(of: "_S", with: "/")
        return string1
    }
    
    func getTopTracks(completion: @escaping ()->()) {
        print("get top tracks")
        let urlString = URL(string: "http://ws.audioscrobbler.com/2.0/?method=chart.gettoptracks&api_key=23ab27800668436c2cfcae1c18c9d369&format=json")
        if let url = urlString {
            print(url)
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    print(error!.localizedDescription)
                } else {
                    print(data ?? "boo")
                    if let usableData = data {
                        print("*****************")
                        let json = JSON(usableData)
                        print(json)
                        var trackArtistDictionary : [String:String] = [:]
                        let tracksRoot = json["tracks"].dictionaryValue
                        let tracks = JSON(tracksRoot["track"]?.array)
                        for (index,subJson):(String, JSON) in tracks {
                            if Int(index)! > 25 {
                                break
                            }
                            let artist = subJson["artist"]["name"].stringValue
                            let track = subJson["name"].stringValue
                            trackArtistDictionary[track] = artist
                            print(track)
                            print(trackArtistDictionary[track]!)
                        }
                        self.topTracks = trackArtistDictionary
                        completion()
                    }
                }
            }
            task.resume()
        }
    }
}

    
