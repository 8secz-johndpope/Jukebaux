//
//  Song.swift
//  JamSesh
//
//  Created by Adam Moffitt on 2/2/17.
//  Copyright © 2017 Adam's Apps. All rights reserved.
//

import UIKit


class Song {
    var songName : String
    var songArtist : String
    var songID : Int
    var songImage : UIImage
    var songImageURL : String
    var upVotes: Int
    var songDuration: Int // in seconds
    
    init() {
        self.songName = ""
        self.songArtist = ""
        self.songID = 0
        self.songImageURL = ""
        self.songImage = UIImage(named:"party")!
        self.upVotes = 0
        self.songDuration = 0
    }
    
    convenience init(songName: String, songArtist : String, songID : Int, songImageURL : String, songDuration: Int, upVotes: Int) {
        self.init()
        self.songName = songName
        self.songArtist = songArtist
        self.songID = songID
        self.songImageURL = songImageURL
        self.songDuration = songDuration/1000 //parameter is in milliseconds
        self.upVotes = upVotes
        let url = URL(string: songImageURL)
        if(url != nil) {
            if let data = try? Data(contentsOf: url!) { //make sure your image in this URL does exist, otherwise unwrap in a if let check / try-catch
                self.songImage = UIImage(data: data)!
            }
        }
    }

    convenience init(songName: String, songArtist : String, songID : Int, songImage : UIImage, songDuration: Int, upVotes: Int) {
        self.init()
        self.songName = songName
        self.songArtist = songArtist
        self.songID = songID
        self.songImage = songImage
        self.songDuration = songDuration/1000 //parameter is in milliseconds
        self.upVotes = upVotes
    }
    
    convenience init(songName: String, songArtist : String, songID : Int, songImageURL: String, songImage : UIImage, songDuration: Int, upVotes: Int) {
        self.init()
        self.songName = songName
        self.songImageURL = songImageURL
        self.songArtist = songArtist
        self.songID = songID
        self.songImage = songImage
        self.songDuration = songDuration/1000 //parameter is in milliseconds
        self.upVotes = upVotes
    }
    
    convenience init(dictionary: NSDictionary) {
        self.init()
        
        print(dictionary)
        
        if dictionary["songName"] != nil {
            self.songName = dictionary["songName"] as! String
            print("song init from dict - \(dictionary["songName"] as! String)")
        }
        
        
        if dictionary["songArtist"] != nil {
            self.songArtist = dictionary["songArtist"] as! String
        }
        
        if dictionary["songID"] != nil {
            self.songID = dictionary["songID"] as! Int
        }
        
        if dictionary["songImageURL"] != nil {
            self.songImageURL = dictionary["songImageURL"] as! String
            let url = URL(string: self.songImageURL)
            //DispatchQueue.main.async {
                if(url != nil) {
                    if let data = try? Data(contentsOf: url!) { //make sure your image in this URL does exist, otherwise unwrap in a if let check / try-catch
                        self.songImage = UIImage(data: data)!
                    }
                }
            //}
        }
        
        if dictionary["songDuration"] != nil {
            self.songDuration = dictionary["songDuration"] as! Int //parameter is in milliseconds
        }
        
        if dictionary["upVotes"] != nil {
            self.upVotes = dictionary["upVotes"] as! Int
        }
    }

    func toAnyObject() -> Any {
        return [
            "songName": songName,
            "songArtist": songArtist,
            "songID": songID,
            "songImageURL": songImageURL,
            "upVotes": upVotes,
            "songDuration": songDuration
        ]
    }
}

