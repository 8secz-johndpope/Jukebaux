//
//  Song.swift
//  TroJams
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
    var songImageUrl : String
    var upvotes: Int
    init() {
        self.songName = ""
        self.songArtist = ""
        self.songID = 0
        self.songImageUrl = ""
        self.songImage = UIImage(named:"party")!
        self.upvotes = 1
    }
    
    convenience init(songName: String, songArtist : String, songID : Int, songImageUrl : String) {
        self.init()
        self.songName = songName
        self.songArtist = songArtist
        self.songID = songID
        self.songImageUrl = songImageUrl
    }
}

