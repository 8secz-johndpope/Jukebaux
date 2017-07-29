//
//  Party.swift
//  JamSesh
//
//  Created by Adam Moffitt on 2/2/17.
//  Copyright © 2017 Adam's Apps. All rights reserved.
//

import UIKit
import FirebaseDatabase

class Party {
    var partyID : String
    var hostName : String
    var hostID : String
    var password : String
    var users : Array<String>
    var image : UIImage
    var imageURL : String
    var savedImageURL : String
    var partyName : String
    var numberJoined : Int
    var privateParty : Bool
    var songs : [Song]
    var currentSong : Song
    var currentSongPersistentIDKey : Int
    var hasStarted : Bool
    var songHistory : [Song]
    var key: String
    var ref: DatabaseReference?
    
    init() {
        partyID = ""
        hostName = ""
        hostID = ""
        password = ""
        users = []
        image = UIImage()
        partyName = ""
        numberJoined = 0
        imageURL = ""
        savedImageURL = ""
        privateParty = false
        songs = [] //Song(songName: "Closer", songArtist : "The Chainsmokers", songID : 1170699703, songImageUrl : "http://is3.mzstatic.com/image/thumb/Music71/v4/8b/78/46/8b78469f-6b82-0fb7-fddd-40a66f356347/source/100x100bb.jpg", songDuration: 245506), Song(songName: "Súbame La Radio", songArtist : "Enrique Iglesias", songID : 1206540519, songImageUrl : "http://is3.mzstatic.com/image/thumb/Music111/v4/01/70/ca/0170ca0e-d78b-7531-94ac-9194e29cabf0/source/100x100bb.jpg", songDuration: 208163), Song(songName: "Thunder", songArtist : "Imagine Dragons", songID : 1233502633, songImageUrl : "http://is1.mzstatic.com/image/thumb/Music117/v4/2c/6b/cc/2c6bcc08-8a7a-dd89-d344-4e649f2a1bf8/source/100x100bb.jpg", songDuration: 187145)]
        
        currentSong = Song()
        currentSongPersistentIDKey = -1
        hasStarted = false
        songHistory = []
        
        key = ""
        ref = DatabaseReference()
    }
    
    convenience init(snapshot: DataSnapshot) {
        self.init()
        key = snapshot.key
        ref = snapshot.ref
        if !(snapshot.value is NSNull) {
            let snapshotValue = snapshot.value as! [String: AnyObject]
            self.partyName = snapshotValue["partyName"] as! String
            self.privateParty = snapshotValue["privateParty"] as! Bool
            self.password = snapshotValue["password"] as! String
            self.numberJoined = snapshotValue["numberJoined"] as! Int
            self.hostName = snapshotValue["hostName"] as! String
            self.hostID = snapshotValue["hostID"] as! String
            self.partyID = snapshotValue["partyID"] as! String
            self.currentSongPersistentIDKey = snapshotValue["currentSongPersistentIDKey"] as! Int
            self.savedImageURL = snapshotValue["savedImageURL"] as! String
            if snapshotValue["currentSong"] != nil {
                let tempCurrentSongDict = snapshotValue["currentSong"] as! NSDictionary
                self.currentSong = Song(dictionary: tempCurrentSongDict)
            }
            //Going to try adding the songs to the playlist in the PartyViewController because running it on the dispatchqueue will load it after the view loads, and waiting for all the songs to load will cause the app to freeze
            /*if snapshotValue["playlist"] != nil {
                let tempSongsDict = snapshotValue["playlist"] as! NSDictionary
                var tempSongs : [Song] = []
                for element in tempSongsDict {
                        let s = Song(dictionary: element.value as! NSDictionary)
                        tempSongs.append(s)
                }
                self.songs = tempSongs
            }*/
            if snapshotValue["users"] != nil {
                let tempUsersDict = snapshotValue["users"] as? NSDictionary
                var tempUsers : [String] = []
                
                for user in tempUsersDict! {
                    tempUsers.append(user.value as! String)
                }
                self.users = tempUsers
            }
            if snapshotValue["songHistory"] != nil {
                let tempCurrentSongHistoryDict = snapshotValue["songHistory"] as! NSDictionary
                var tempCurrentSongHistory : [Song] = []
                for element in tempCurrentSongHistoryDict {
                    let s = Song(dictionary: element.value as! NSDictionary)
                    tempCurrentSongHistory.append(s)
                }
                self.songHistory = tempCurrentSongHistory
            }
        }
    }
    
    convenience init(name: String , partyID: String, partyImage: UIImage, privateParty: Bool, password: String, numberJoined: Int) {
        
        self.init()
        
        self.partyID = partyID
        self.partyName = name
        self.image = partyImage
        self.privateParty = privateParty
        self.password = password
        self.numberJoined = numberJoined
        
    }
    
    convenience init(name: String , partyID: String, partyImage: UIImage, savedImageURL: String, privateParty: Bool, password: String, numberJoined: Int) {
        
        self.init(name: name , partyID: partyID, partyImage: partyImage, privateParty: privateParty, password: password, numberJoined: numberJoined)
        self.savedImageURL = savedImageURL
    }
    
    convenience init(name: String , partyID: String, partyImage: UIImage, savedImageURL: String, privateParty: Bool, password: String, numberJoined: Int, partyPlaylist: [Song], hostName: String, hostID: String, users: [String]) {
        
        self.init(name: name , partyID: partyID, partyImage: partyImage, savedImageURL: savedImageURL, privateParty: privateParty, password: password, numberJoined: numberJoined)
        self.songs = partyPlaylist
        self.hostName = hostName
        self.hostID = hostID
        self.users = users
    }
    
    func addSong(songName: String, songArtist : String, songID : Int, songImageUrl : String, songDuration: Int) {
        songs.append(Song(songName: songName, songArtist : songArtist, songID : songID, songImageURL : songImageUrl, songDuration: songDuration, upVotes: 1))
    }
    
    typealias CompletionHandler = (_ success:Bool) -> Void
    func getTrackImageURLandThenAddSong(songName: String, songArtist : String, songID : Int, songImage : UIImage, songDuration: Int, completionHandler: @escaping CompletionHandler) {
        
        DispatchQueue(qos: .background).async {
            
            var trackImageURL = ""
            var term = String(songID).replacingOccurrences(of: " ", with: "-")
            term = term.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed)!
            let url = NSURL(string: "https://itunes.apple.com/lookup?id=\(term)&entity=song")
            let request = NSMutableURLRequest(
                url: url! as URL,
                cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData,
                timeoutInterval: 10)
            request.httpMethod = "GET"
            
            let session = URLSession(
                configuration: URLSessionConfiguration.default,
                delegate: nil,
                delegateQueue: OperationQueue.main
            )
            
            let task: URLSessionDataTask = session.dataTask(with: request as URLRequest,
                                                            completionHandler: { (dataOrNil, response, error) in
                                                                if let data = dataOrNil {
                                                                    if let responseDictionary = try! JSONSerialization.jsonObject(
                                                                        with: data, options:[]) as? NSDictionary {
                                                                        
                                                                        var tempResults = (responseDictionary["results"] as?[NSDictionary])!
                                                                        if tempResults[0]["artworkUrl100"] != nil {
                                                                            trackImageURL = tempResults[0]["artworkUrl100"] as! String
                                                                            //now that we got the imageURL, add the song using the other addSong function
                                                                            self.songs.append(Song(songName: songName, songArtist : songArtist, songID : songID, songImageURL : trackImageURL, songImage: songImage, songDuration: songDuration, upVotes: 0))
                                                                            completionHandler(true)
                                                                        }
                                                                    }
                                                                }
            })
            task.resume()
        }
    }
    
    func setCurrentSong (songId: String) {
        var i = 0
        songHistory.append(currentSong)
        for element in songs {
            if String(describing: element.songID) == songId {
                currentSong = element
                songs.remove(at: i)
            }
            i += 1
        }
    }
    
    func toAnyObject() -> Any {
        var usersDict = [String : String]()
        for element in users {
            usersDict[encodeForFirebaseKey(string: "username")] = element
        }
        
        var songsDict = [String : AnyObject]()
        for element in songs {
            songsDict[encodeForFirebaseKey(string: element.songName)] = element.toAnyObject() as AnyObject
        }
        var songsHistoryDict = [String : AnyObject]()
        for element in songHistory {
            songsHistoryDict[encodeForFirebaseKey(string: element.songName)] = element.toAnyObject() as AnyObject
        }
        
        return [
            "hostName": hostName,
            "hostID": hostID,
            "partyID": partyID,
            "password": password,
            "users": usersDict,
            "imageURL": imageURL,
            "savedImageURL": savedImageURL,
            "partyName": partyName,
            "numberJoined": numberJoined,
            "privateParty": privateParty,
            "playlist": songsDict,
            "currentSong": currentSong.toAnyObject(),
            "currentSongPersistentIDKey": currentSongPersistentIDKey,
            "hasStarted": hasStarted,
            "songHistory": songsHistoryDict
        ]
    }
    
    func playlistToAnyObject() -> Any {
        
        var songsDict = [String : AnyObject]()
        for element in songs {
            songsDict[encodeForFirebaseKey(string: element.songName)] = element.toAnyObject() as AnyObject
        }
        
        return [
            "playlist": songsDict
        ]
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
}


