//
//  Song.swift
//  Jukebaux
//
//  Created by Adam Moffitt on 2/2/17.
//  Copyright © 2017 Adam's Apps. All rights reserved.
//

import UIKit


class Song {
    var songName : String
    var songArtist : String
    var songID : String // apple track ID, needs to be string to be key for firebase
    var songImage : UIImage
    var songImageURL : String
    var upVotes: Int
    var songDuration: Int // in seconds
    var suggestedBy : String // username who suggested it
    var upvotedBy : [String:Int] // user ids of those who have upvoted this todo change to bools
    var downvotedBy : [String:Int] // user ids of those who have upvoted this todo change to bool
    var addedDate: Date // used to sort songs with same number of upvotes by time added
    var playlistOrderIndex: Int //used to hold song's order in playlist. negative if not set
    
    init() {
        self.songName = ""
        self.songArtist = ""
        self.songID = ""
        self.songImageURL = ""
        self.songImage = UIImage(named:"party")!
        self.upVotes = 1
        self.songDuration = 0
        self.suggestedBy = ""
        self.upvotedBy = [:]
        self.downvotedBy = [:]
        self.addedDate = Date()
        self.playlistOrderIndex = -1
    }
    
    convenience init(songName: String, songArtist : String, songID : String, songImageURL : String, songDuration: Int, upVotes: Int) {
        self.init()
        self.songName = songName
        self.songArtist = songArtist
        self.songID = songID
        self.songImageURL = songImageURL
        self.songDuration = songDuration/1000 //parameter is in milliseconds
        self.upVotes = upVotes
        let url = URL(string: songImageURL)
        if(url != nil) {
            DispatchQueue.global(qos: .userInitiated).async {
                if let data = try? Data(contentsOf: url!) { //make sure image in this URL does exist, otherwise unwrap in a if let check / try-catch
                    self.songImage = UIImage(data: data)!
                }
            }
        }
    }

    convenience init(songName: String, songArtist : String, songID : String, songImage : UIImage, songDuration: Int, upVotes: Int) {
        self.init()
        self.songName = songName
        self.songArtist = songArtist
        self.songID = songID
        self.songImage = songImage
        self.songDuration = songDuration/1000 //parameter is in milliseconds
        self.upVotes = upVotes
    }
    
    convenience init(songName: String, songArtist : String, songID : String, songImageURL: String, songImage : UIImage, songDuration: Int, upVotes: Int) {
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
        
        if dictionary["songName"] != nil {
            self.songName = dictionary["songName"] as! String
        }
        if dictionary["songArtist"] != nil {
            self.songArtist = dictionary["songArtist"] as! String
        }
        if dictionary["songID"] != nil {
            self.songID = dictionary["songID"] as! String
        }
        if dictionary["songImageURL"] != nil {
            self.songImageURL = dictionary["songImageURL"] as! String
            let url = URL(string: self.songImageURL)
            DispatchQueue.global(qos: .userInitiated).async {
                if(url != nil) {
                    if let data = try? Data(contentsOf: url!) { //make sure your image in this URL does exist, otherwise unwrap in a if let check / try-catch
                        self.songImage = UIImage(data: data)!
                    }
                }
            }
        }
        if dictionary["songDuration"] != nil {
            self.songDuration = dictionary["songDuration"] as! Int //parameter is in milliseconds
        }
        if dictionary["upVotes"] != nil {
            self.upVotes = dictionary["upVotes"] as! Int
        }
        if dictionary["suggestedBy"] != nil {
            self.suggestedBy = dictionary["suggestedBy"] as! String
        }
        if dictionary["upvotedBy"] != nil {
            self.upvotedBy = dictionary["upvotedBy"] as! [String:Int]
        }
        if dictionary["downvotedBy"] != nil {
            self.downvotedBy = dictionary["downvotedBy"] as! [String:Int]
        }
    }
    
    // convert from dictionary but dont pull song image
    convenience init(dictionary: NSDictionary, getImage: Bool) {
        self.init()
        
        if dictionary["songName"] != nil {
            self.songName = dictionary["songName"] as! String
        }
        if dictionary["songArtist"] != nil {
            self.songArtist = dictionary["songArtist"] as! String
        }
        if dictionary["songID"] != nil {
            self.songID = dictionary["songID"] as! String
        }
        if dictionary["songImageURL"] != nil {
            self.songImageURL = dictionary["songImageURL"] as! String
        }
        if dictionary["songDuration"] != nil {
            self.songDuration = dictionary["songDuration"] as! Int //parameter is in milliseconds
        }
        if dictionary["upVotes"] != nil {
            self.upVotes = dictionary["upVotes"] as! Int
        }
        if dictionary["suggestedBy"] != nil {
            self.suggestedBy = dictionary["suggestedBy"] as! String
        }
        if dictionary["upvotedBy"] != nil {
            self.upvotedBy = dictionary["upvotedBy"] as! [String:Int]
        }
        if dictionary["downvotedBy"] != nil {
            self.downvotedBy = dictionary["downvotedBy"] as! [String:Int]
        }
        if dictionary["addedDate"] != nil {
            let dateString = dictionary["addedDate"] as! String
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            self.addedDate = dateFormatter.date(from:dateString)!
        }
    }

    func toAnyObject() -> Any {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = dateFormatter.string(from: addedDate as Date)
        return [
            "songName": songName,
            "songArtist": songArtist,
            "songID": songID,
            "songImageURL": songImageURL,
            "upVotes": upVotes,
            "songDuration": songDuration,
            "suggestedBy" : suggestedBy,
            "upvotedBy" : upvotedBy,
            "downvotedBy" : downvotedBy,
            "addedDate" : dateString
        ]
    }

    static func contentMatches(lhs: Song, _ rhs: Song) -> Bool {
        return lhs.songName == rhs.songName
            && lhs.songArtist == rhs.songArtist
            && lhs.songID == rhs.songID
            && lhs.upVotes == rhs.upVotes
    }
}

extension Song: Equatable {}

func ==(lhs: Song, rhs: Song) -> Bool {
    return lhs.songID == rhs.songID
}

