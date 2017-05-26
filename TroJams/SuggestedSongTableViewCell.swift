//
//  SuggestedSongTableViewCell.swift
//  JamSesh
//
//  Created by Adam Moffitt on 2/3/17.
//  Copyright © 2017 Adam's Apps. All rights reserved.
//

import UIKit

class SuggestedSongTableViewCell: UITableViewCell {

    
    @IBOutlet var suggestedSongImageView: UIImageView!
    
    @IBOutlet var suggestedSongName: UILabel!
    @IBOutlet var suggestedSongArtist: UILabel!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
