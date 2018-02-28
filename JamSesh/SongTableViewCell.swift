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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func downvoteButtonPressed(_ sender: Any) {
        
        delegate?.downvoteButtonPressed(cellId: cellId)

        /*
        if ( !alreadyDownvoted || alreadyUpvoted ) {
            print(4)
            if alreadyUpvoted {
                print(5)
                alreadyUpvoted = false
            } else {
                print(6)
                alreadyDownvoted = true
            }
            upvoteCounter -= 1
            upvoteCount.text = String(upvoteCounter)
            delegate?.downvoteButtonPressed(cellId: cellId)
        } else {
            print("nope")
        }*/
    }
    
    @IBAction func upvoteButton(_ sender: Any) {
        //upvoteImageView.transform = .identity
        //upvoteImageView.hop(toward: .top)
        delegate?.upvoteButtonPressed(cellId: cellId)

        /*
        if ( !alreadyUpvoted || alreadyDownvoted ) {
            print(1)
            if alreadyDownvoted {
                print(2)
                alreadyDownvoted = false
            } else {
                print(3)
                alreadyUpvoted = true
            }
            upvoteButton.transform = .identity
            upvoteButton.hop(toward: .top)
            upvoteCounter += 1
            upvoteCount.text = String(upvoteCounter)
            delegate?.upvoteButtonPressed(cellId: cellId)
        } else {
            print("nope")
        } */
    }
    
    /* override func prepareForReuse() {
        super.prepareForReuse
        if let refHandle = handle {
                SharedJamSeshModel.ref.removeObserver(withHandle: refHandle)
        }
    } */
}

