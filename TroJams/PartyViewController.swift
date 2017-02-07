//
//  PartyViewController.swift
//  TroJams
//
//  Created by Adam Moffitt on 1/27/17.
//  Copyright © 2017 Adam's Apps. All rights reserved.
//

import UIKit


protocol SongTableViewCellDelegate {
    func upvoteButtonPressed(cellId: Int)
    func downvoteButtonPressed(cellId: Int)
}

class PartyViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SongTableViewCellDelegate {
    

    let SharedTrojamsModel = TroJamsModel.shared
    
    var partyImageImage : UIImage = UIImage(named: "party")!
    var partyName : String = ""
    var party : Party = Party()
    
    @IBOutlet var partyImage: UIImageView!
    @IBOutlet var partyNameLabel: UILabel!
    
    @IBOutlet var songsTableView: UITableView!
    
    var chatBarButtonItem  = UIButton(type: .custom)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        partyImage.image = partyImageImage
        partyNameLabel.text = partyName
        songsTableView.delegate = self
        songsTableView.dataSource = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("partyviewcontroller view will appear")
        
        party = SharedTrojamsModel.parties[SharedTrojamsModel.currentPartyIndex]
        for element in party.songs{
            print("check order: \(element.songName)")
        }
       
        songsTableView.reloadData()
    }
    
    @IBAction func chatButtonPressed(_ sender: Any) {
        
    }
    
    @IBAction func suggestSongButton(_ sender: Any) {
        
    }

     func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return party.songs.count
    }
    
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongTableViewCell
        cell.delegate = self
        print("cell for row at index path")
        let song = party.songs[indexPath.row]
        let url1 = URL(string: song.songImageUrl)
        print("song: \(song.songName) - \(song.upvotes)")
        var songImage = UIImage(named: "party")
        if let data = try? Data(contentsOf: url1!)  {
            songImage = UIImage(data: data)!
        }
        
        cell.cellId = indexPath.row
        cell.songImage.image = songImage
        print(song.songName)
        cell.songName.text = song.songName
        print(song.songArtist)
        cell.songArtist.text = song.songArtist
        cell.upvoteCounter = song.upvotes
        cell.upvoteCount.text = String(cell.upvoteCounter)
        
        //cell.upvoteView = LAAnimationView.animationNamed("Twitterheart")
        
        return cell
    }
    
    //from SongTableViewCell delegate
    func downvoteButtonPressed(cellId: Int) {
        print( "downvote button pressed" )
        party.songs[cellId].upvotes -= 1
        sortSongs()
        songsTableView.reloadData()
    }
    
    //from SongTableViewCell delegate
    func upvoteButtonPressed(cellId: Int) {
       print( "upvote button pressed" )
        party.songs[cellId].upvotes += 1
        sortSongs()
        songsTableView.reloadData()
    }
    
    //sort songs in songs array by number of upvotes
    func sortSongs() {
        party.songs.sort(by: {
            return $0.upvotes > $1.upvotes
        })

        for element in party.songs{
            print("sorted order: \(element.songName)")
        }
        
        SharedTrojamsModel.parties[SharedTrojamsModel.currentPartyIndex].songs = party.songs
    }

    
    //https://itunes.apple.com/search?term=\()&media=music&limit=15
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
