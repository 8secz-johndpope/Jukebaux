//
//  Party.swift
//  TroJams
//
//  Created by Adam Moffitt on 2/2/17.
//  Copyright © 2017 Adam's Apps. All rights reserved.
//

import UIKit


class Party {
    var hostName : String
    var password : String
    var users : Array<String>
    var image : UIImage
    var imageURL : String
    var partyName : String
    var numberJoined : Int
    var privateParty : Bool
    var songs : [Song] = [Song(songName: "Closer", songArtist : "The Chainsmokers", songID : 1170699703, songImageUrl : "http://is3.mzstatic.com/image/thumb/Music71/v4/8b/78/46/8b78469f-6b82-0fb7-fddd-40a66f356347/source/100x100bb.jpg")]
    
    init() {
        hostName = ""
        password = ""
        users = []
        image = UIImage()
        partyName = ""
        numberJoined = 0
        imageURL = ""
        privateParty = false
    }
    
    convenience init(name: String , partyImage: UIImage, privateParty: Bool, password: String) {
        self.init()
        self.partyName = name
        self.image = partyImage
        self.privateParty = privateParty
        self.password = password
    }
    
    func addSong(songName: String, songArtist : String, songID : Int, songImageUrl : String) {
        songs.append(Song(songName: songName, songArtist : songArtist, songID : songID, songImageUrl : songImageUrl))
    }
}


