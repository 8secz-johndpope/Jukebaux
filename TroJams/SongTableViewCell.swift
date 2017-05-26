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
    
    //cellId is so that the cell knows where in the party.songs array it is, so that it can send that id with the delegate in order to change the song upvote counter at that index in the array
    var cellId: Int = 0
    let SharedJamSeshModel = JamSeshModel.shared
    
    @IBOutlet var songImage: UIImageView!
    
    @IBOutlet var songName: UILabel!
    @IBOutlet var songArtist: UILabel!
    
    @IBOutlet var upvoteCount: UILabel!
    
    @IBOutlet var upvoteImageView: UIImageView!
    @IBOutlet var downvoteImageView: UIImageView!
    
    @IBOutlet var downvoteView: UIView!
    @IBOutlet var upvoteView: UIView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        upvoteImageView.image = UIImage(named: "upvoteImage")
        downvoteImageView.image = UIImage(named: "downvoteImage")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func downvoteButtonPressed(_ sender: Any) {
        upvoteCounter -= 1
        upvoteCount.text = String(upvoteCounter)
        delegate?.downvoteButtonPressed(cellId: cellId)
    }
    
    @IBAction func upvoteButton(_ sender: Any) {
        upvoteImageView.transform = .identity
        upvoteImageView.hop(toward: .top)
        upvoteCounter += 1
        upvoteCount.text = String(upvoteCounter)
        delegate?.upvoteButtonPressed(cellId: cellId)
    }
}

