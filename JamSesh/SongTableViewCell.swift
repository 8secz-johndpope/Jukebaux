//
//  SongTableViewCell.swift
//  JamSesh
//
//  Created by Adam Moffitt on 1/27/17.
//  Copyright © 2017 Adam's Apps. All rights reserved.
//

import UIKit
import SimpleAnimation

class SongTableViewCell: UITableViewCell {

    var delegate: SongTableViewCellDelegate? = nil
    
    var upvoteCounter : Int = 0
    var alreadyUpvoted = false
    var alreadyDownvoted = false
    //cellId is so that the cell knows where in the party.songs array it is, so that it can send that id with the delegate in order to change the song upvote counter at that index in the array
    var cellId: Int = 0
    let SharedJamSeshModel = JamSeshModel.shared
    
    @IBOutlet var songImage: UIImageView!
    
    @IBOutlet var songName: UILabel!
    @IBOutlet var songArtist: UILabel!
    
    @IBOutlet var upvoteCount: UILabel!
    
    @IBOutlet var upvoteButton: UIButton!
    @IBOutlet var downvoteButton: UIButton!
    

    @IBAction func downvoteButtonPressed(_ sender: Any) {
        
        delegate?.downvoteButtonPressed(cellId: cellId)
    }
    
    @IBAction func upvoteButton(_ sender: Any) {
        delegate?.upvoteButtonPressed(cellId: cellId)

    }
}

