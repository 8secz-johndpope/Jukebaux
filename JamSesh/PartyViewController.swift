//
//  PartyViewController.swift
//  JamSesh
//
//  Created by Adam Moffitt on 1/27/17.
//  Copyright © 2017 Adam's Apps. All rights reserved.
//

import UIKit
import MediaPlayer
import SCLAlertView
import QuartzCore
import FirebaseDatabase
import SimpleAnimation
import NVActivityIndicatorView

protocol SongTableViewCellDelegate {
    func upvoteButtonPressed(cellId: Int)
    func downvoteButtonPressed(cellId: Int)
}

// The current party is referred to as SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex] throughout this view controller code
class PartyViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SongTableViewCellDelegate {
    
    let SharedJamSeshModel = JamSeshModel.shared
    let partyMusicHandler = PlayMusicHandler.shared
    var timer : Timer?
    
    var playlistHandleAdd : DatabaseHandle?
    var playlistHandleRemove : DatabaseHandle?
    var playlistHandleModify : DatabaseHandle?
    var currentSongHandle : DatabaseHandle?
    var numberJoinedHandle : DatabaseHandle?
    var partyHandle : DatabaseHandle?
    var partyEndHandle : DatabaseHandle?
    
    let notificationCenter = NotificationCenter.default
    var isHost : Bool = false
    
    @IBOutlet var isHostLabel: UILabel!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var currentlyPlayingSongNameLabel: UILabel!
    
    @IBOutlet var currentlyPlayingSongImage: UIImageView!
    
    @IBOutlet var currentlyPlayingSongArtistLabel: UILabel!
    
    @IBOutlet var currentlyPlayingSongDurationLabel: UILabel!
    
    @IBOutlet var currentlyPlayingSongTimeElapsedLabel: UILabel!
    
    @IBOutlet var currentlyPlayingSongTimeSlider: UISlider!
    @IBOutlet var playPauseButton: UIButton!
    @IBOutlet var partyImage: UIImageView!
    @IBOutlet var partyNameLabel: UILabel!
    @IBOutlet var nextButton: UIButton!
    
    @IBOutlet var songsTableView: UITableView!
    
    var endPartyBarButtonItem = UIBarButtonItem()
    var chatBarButtonItem = UIBarButtonItem()
    var loadingIndicatorView : NVActivityIndicatorView!
    var overlay : UIView!
    var emptyPlaylistButton : UIButton!
    
    /*****************************************************************************/
    override func viewDidLoad() {
        super.viewDidLoad()
        print("view did load")
        // Set up loading view animation
        loadingIndicatorView = NVActivityIndicatorView(frame: CGRect(x:0,y:0,width:100,height:100), type: NVActivityIndicatorType(rawValue: 31), color: UIColor.purple )
        loadingIndicatorView.center = self.view.center
        
        overlay = UIView(frame: view.frame)
        overlay.backgroundColor = UIColor.black
        overlay.alpha = 0.7
        
        self.view.addSubview(overlay!)
        self.view.addSubview(loadingIndicatorView!)
        
        let currentParty = SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex]
        partyImage.image = currentParty.image
        partyNameLabel.text = currentParty.partyName
        
        loadPartyFromFirebase()
        
        songsTableView.delegate = self
        songsTableView.dataSource = self
        songsTableView.layer.borderWidth = 5.0;
        songsTableView.layer.borderColor = UIColor.purple.cgColor
        let px = 1 / UIScreen.main.scale
        let frame = CGRect(x:0, y:0, width:songsTableView.frame.size.width, height: px)
        let header = UILabel(frame: CGRect(x:0, y:0, width:songsTableView.frame.size.width, height: px))
        let line = UIView(frame: frame)
        line.addSubview(header)
        songsTableView.tableHeaderView = line
        
        //currentlyPlayingSongTimeSlider.setThumbImage(UIImage(named: "triangle")!, for: .normal)
        
        // Button to prompt user to add songs when playlist is empty
        emptyPlaylistButton = UIButton(frame: CGRect(x: self.view.frame.minX + 10, y: self.view.frame.minY+100, width: self.view.frame.width-20, height: 400))
        emptyPlaylistButton.alpha = 0.8
        emptyPlaylistButton.backgroundColor = UIColor.purple
        emptyPlaylistButton.setTitle("The playlist for this party is empty! Click here to add some songs and keep the tunes rolling.",for: .normal)
        emptyPlaylistButton.titleLabel?.numberOfLines = 0
       emptyPlaylistButton.titleLabel?.textAlignment = NSTextAlignment.center
        emptyPlaylistButton.titleLabel?.textColor = UIColor.white
        emptyPlaylistButton.addTarget(self, action:#selector(emptyPlaylistButtonPressed), for: .touchUpInside)
        let dismissButton = UIButton(frame: CGRect(x: 20, y: 3*emptyPlaylistButton.frame.height/4, width: emptyPlaylistButton.frame.width-20, height: 40))
        dismissButton.backgroundColor = UIColor.black
        dismissButton.setTitle("Dismiss",for: .normal)
        dismissButton.titleLabel?.textAlignment = NSTextAlignment.center
        dismissButton.titleLabel?.textColor = UIColor.purple
        dismissButton.addTarget(self, action:#selector(dismissEmptyPlaylistButtonPressed), for: .touchUpInside)
        emptyPlaylistButton.addSubview(dismissButton)
        
        chatBarButtonItem = UIBarButtonItem(title: "Chat", style: UIBarButtonItemStyle.plain, target: self, action: #selector(chatBarButtonPressed))
        // Check if the user is the host of the party. Being the host will allow them to perform functionalities like playing music etc.
        if SharedJamSeshModel.myUser.userID == currentParty.hostID { // User is Host
            isHostLabel.text = "You are the Host"
            isHost = true
            playPauseButton.isHidden = false
            nextButton.isHidden = false
            
            endPartyBarButtonItem =  UIBarButtonItem(title: "End Party", style: UIBarButtonItemStyle.plain, target: self, action: #selector(endPartyButtonPressed))
            self.navigationItem.rightBarButtonItems = [chatBarButtonItem, endPartyBarButtonItem]
        } else { // user is not host
            isHost  = false
           
            self.navigationItem.rightBarButtonItems = [chatBarButtonItem]
            
            isHostLabel.text = "You are the not the Host"
            playPauseButton.isHidden = true
            nextButton.isHidden = true
            currentlyPlayingSongTimeSlider.isHidden = true
            currentlyPlayingSongTimeElapsedLabel.isHidden = true
            currentlyPlayingSongDurationLabel.isHidden = true
        }
        
        print("call VWA")
    }
    /*****************************************************************************/
    
    
    /*****************************************************************************/
    func testNowPlayingDidChange (notification: Notification) -> Void  {
        if ( partyMusicHandler.getPlaybackState() == MPMusicPlaybackState.stopped) {
            print("TEST NOW PLAYING DID CHANGE - move to next song :: \(partyMusicHandler.getPlaybackState().rawValue) :: \(MPMusicPlaybackState.stopped.rawValue)")
           // moveToNextSong()
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func testPlaybackStopped (notification: Notification) -> Void {
        print("TEST PLAYBACK STOPPED")
    }
    /*****************************************************************************/

    /*****************************************************************************/
    override func viewWillAppear(_ animated: Bool) {
        let currentParty = SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex]
        print("view will appear \(partyMusicHandler.getPlaybackState().rawValue)")
        songsTableView.reloadData()
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    deinit {
        print("deinit")
        stopTimer()
        let partyID = self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].partyID
        
        if let refHandleAdd = playlistHandleAdd {
            SharedJamSeshModel.ref.child("parties").child(partyID).child("playlist").removeObserver(withHandle: refHandleAdd)
        }
        if let refHandleRemove = playlistHandleRemove {
            SharedJamSeshModel.ref.child("parties").child(partyID).child("playlist").removeObserver(withHandle: refHandleRemove)
        }
        if let refHandleObserve = playlistHandleModify {
            SharedJamSeshModel.ref.child("parties").child(partyID).child("playlist").removeObserver(withHandle: refHandleObserve)
        }
        if let currentSongH = currentSongHandle {
            SharedJamSeshModel.ref.child("parties").child(partyID).removeObserver(withHandle:  currentSongH)
        }
        if let partyEndH = partyEndHandle {
            SharedJamSeshModel.ref.child("parties").child(partyID).removeObserver(withHandle:  partyEndH)
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func showEmptyPlaylistButton() {
        if (!self.view.subviews.contains(emptyPlaylistButton)) {
            self.view.addSubview(emptyPlaylistButton)
        }
    }
    
    func hideEmptyPlaylistButton() {
        if (self.view.subviews.contains(emptyPlaylistButton)) {
            emptyPlaylistButton.removeFromSuperview()
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func moveToNextSong() {
        if (SharedJamSeshModel.currentPartyIndex < SharedJamSeshModel.parties.count) {
            let currentParty = SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex]
            // If songs are empty
            if currentParty.songs.count < 1 {
                //Handle empty songs
                showEmptyPlaylistButton()
            }
            else {
                hideEmptyPlaylistButton()
                SharedJamSeshModel.setPartySong(song: currentParty.songs[0])
                SharedJamSeshModel.removePartySong(song: currentParty.songs[0])
            }
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func playNextSong () {
        let currentParty = SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex]
        // If songs are empty
        if currentParty.songs.count < 1 {
            //Handle empty songs
           showEmptyPlaylistButton()
        }
        else {
            hideEmptyPlaylistButton()
            // Play next song
            SharedJamSeshModel.setPartySong(song: currentParty.songs[0])
            partyMusicHandler.setCurrentPlaybackTime(time: 0)
            partyMusicHandler.appleMusicPlayTrackId(ids: [String(describing: currentParty.songs[0].songID)])
            partyMusicHandler.setCurrentPlaybackTime(time: 0)
            SharedJamSeshModel.removePartySong(song: currentParty.songs[0])
        }
        updateNowPlayingInfo()
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func playCurrentSong () {
        let currentParty = SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex]
        
        currentlyPlayingSongNameLabel.text = currentParty.currentSong.songName
        currentlyPlayingSongArtistLabel.text = currentParty.currentSong.songArtist
        currentlyPlayingSongImage.image = currentParty.currentSong.songImage
        
        // Play current song
        partyMusicHandler.appleMusicPlayTrackId(ids: [String(describing: currentParty.currentSong.songID)])
        partyMusicHandler.setCurrentPlaybackTime(time: 0)
        updateNowPlayingInfo()
        
        // If songs are empty
        if currentParty.songs.count < 1 { // Handle empty songs
            showEmptyPlaylistButton()
        }
        else {
            hideEmptyPlaylistButton()
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func loadPartyFromFirebase() {
        print("load party from firebase")
        self.showLoadingAnimation()
        
        let partyID = self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].partyID
    
        /*
        numberJoinedHandle = SharedJamSeshModel.ref.child("parties").child(partyID).child("numberJoined").observe(DataEventType.value, with: { (snapshot) in
            if !snapshot.exists() {
                return
            }
            if let numberJoinedSnapshot = snapshot as? DataSnapshot {
                print(numberJoinedSnapshot)
                if !(numberJoinedSnapshot.value is NSNull) {
                    let snapshotValue = snapshot.value as! [String: AnyObject]
                    let newNumberJoined = snapshotValue["numberJoined"] as! Int
                    self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].numberJoined = newNumberJoined
                }
            }
        })
        */
        
        partyEndHandle = SharedJamSeshModel.ref.child("parties").child(partyID).child("partyEndNotification").observe(DataEventType.value, with: { (snapshot) in
                if !snapshot.exists() {
                    print("bad partyEndNotification")
                    return
                }
                print("party end notification received \(snapshot)")
                if let indicator = snapshot.value as? Bool{
                    print(indicator)
                    if indicator {
                        if let refHandleRemove = self.playlistHandleRemove {
                            self.SharedJamSeshModel.ref.child("parties").child(partyID).child("playlist").removeObserver(withHandle: refHandleRemove)
                        }
                        if let currentHandle = self.currentSongHandle {
                            self.SharedJamSeshModel.ref.child("parties").child(partyID).child("playlist").removeObserver(withHandle: currentHandle)
                        }
                        // TODO this is probably a bad way to do it as then you get a lot of people writing nils to FB but whateves hopefully it works for now
                        if (self.isHost) {
                            let partyID = self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].partyID
                            self.stopTimer()
                            self.partyMusicHandler.stop()
                            self.navigationController?.popViewController(animated: true)
                            self.SharedJamSeshModel.parties.remove(at: self.SharedJamSeshModel.currentPartyIndex)
                            self.SharedJamSeshModel.ref.child("parties").child(partyID).setValue(nil) { error in
                                if error != nil {
                                    print("party remove error \(error)")
                                } else {
                                    print("party removed")
                                }
                            }
                        } else {
                            let appearance = SCLAlertView.SCLAppearance(
                                showCloseButton: false
                            )
                            let alertView = SCLAlertView(appearance: appearance)
                            alertView.addButton("Okay", action: {
                                let partyID = self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].partyID
                                self.SharedJamSeshModel.parties.remove(at: self.SharedJamSeshModel.currentPartyIndex)
                                self.navigationController?.popViewController(animated: true)
                            })
                            alertView.showInfo("Your current party ended", subTitle: "Looks like the host ended the party. Join another party and keep the tunes coming!")
                        }
                    }
                }
            })
            
        
        currentSongHandle  = SharedJamSeshModel.ref.child("parties").child(partyID).child("currentSong").observe(DataEventType.value, with: { (snapshot) in
            if !snapshot.exists() {
                print("get current song doesnt exist")
                if ( self.isHost ) {
                    self.moveToNextSong()
                }
                return
            }
            if let currentSongSnapshot = snapshot as? DataSnapshot {
                
                let tempCurrentSong = Song(dictionary: currentSongSnapshot.value as! NSDictionary)
                if (self.SharedJamSeshModel.currentPartyIndex < self.SharedJamSeshModel.parties.count) {
                    self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].currentSong = tempCurrentSong
                }
                print("get current song: \(tempCurrentSong.songName)")
                
                DispatchQueue.global(qos: .userInitiated).async {
                    let url1 = URL(string: tempCurrentSong.songImageURL)
                    if (url1 != nil) {
                        if let data = try? Data(contentsOf: url1!)  {
                            DispatchQueue.main.async {
                                self.currentlyPlayingSongImage.image = UIImage(data: data)!
                            }
                        }
                    }
                }
                
                self.currentlyPlayingSongNameLabel.text = tempCurrentSong.songName
                self.currentlyPlayingSongArtistLabel.text = tempCurrentSong.songArtist
                
                print("\(self.partyMusicHandler.getPlaybackState().rawValue) :: \(MPMusicPlaybackState.stopped.rawValue)")
                if ( self.isHost) {
                    if self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].currentSong.songName != "" {
                        print("play current song from observer")
                        self.playCurrentSong()
                    } else {
                        print("play next song from observer")
                        self.moveToNextSong()
                    }
                }
                self.hideLoadingAnimation()
            }
        })
        
        self.setPlaylistFBObservers(partyID: partyID)
        
        /*
        SharedJamSeshModel.ref.child("parties").child(partyID).child("playlist").observeSingleEvent(of: .value, with: { (snapshot) in
            if !snapshot.exists() {
                print("get playlist doesnt exist")
                self.hideLoadingAnimation()
                return
            }
            if let currentPlaylistSnapshot = snapshot as? DataSnapshot {
                print("get playlist")
                let tempSongsDict = currentPlaylistSnapshot.value as! NSDictionary
                let dictSize = tempSongsDict.count
                var counter = 0
                var playlist : [Song] = []
                for element in tempSongsDict {
                    //run on background thread because pulling song image takes a while
                    DispatchQueue.main.async{
                        let s = Song(dictionary: element.value as! NSDictionary, getImage: false)
                        print(s.songName)
                        playlist.append(s)
                        counter = counter + 1
                        if counter >= dictSize { // when all songs are loaded
                            self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs = playlist
                            self.pullSongImages()
                            self.sortSongs()
                            self.setPlaylistFBObservers(partyID: partyID)
                        }
                    }
                }
            }
        }) */
    }
    /*****************************************************************************/
    
    /*****************************************************************************/

    func hideLoadingAnimation() {
        self.loadingIndicatorView.stopAnimating()
        self.loadingIndicatorView.isHidden = true
        self.overlay.isHidden = true
        self.view.willRemoveSubview(self.overlay)
    }
    
    func showLoadingAnimation() {
        self.loadingIndicatorView.startAnimating()
        self.loadingIndicatorView.isHidden = false
        self.overlay.isHidden = false
        self.view.addSubview(self.overlay)
    }
    /*****************************************************************************/

    
    /*****************************************************************************/
    func indexOfMessage(_ snapshot: DataSnapshot) -> Int {
        var index = 0
        print(snapshot)
        for song in self.SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].songs {
            print("KEY: " + snapshot.key)
            if snapshot.key == song.songName {
                return index
            }
            index += 1
        }
        return -1
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func setPlaylistFBObservers(partyID: String) {
        print("set Playlist FB observers")
        
        playlistHandleAdd = SharedJamSeshModel.ref.child("parties").child(partyID).child("playlist").observe(DataEventType.childAdded, with: { (snapshot) -> Void in
            if !snapshot.exists() {
                return
            }
            self.hideEmptyPlaylistButton()
            let currentParty = self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex]
            //self.showLoadingAnimation()
            // The listener is passed a snapshot containing the new child's data.
            if let childSongSnapshot = snapshot as? DataSnapshot {
                let newSong = Song(dictionary: childSongSnapshot.value as! NSDictionary)
               print("observed add in playlist \(newSong.songName)")
                
                // if is the host, and the current song is done playing, and there is no other songs, put right into current song
                if self.isHost && Float(self.partyMusicHandler.getCurrentPlaybackTime()) >= Float(currentParty.currentSong.songDuration) {
                    self.SharedJamSeshModel.setPartySong(song: newSong)
                }
                
                
                if !currentParty.songs.contains(where: { $0.songID == newSong.songID}) { // if song isnt already in the playlist
                    if let index = currentParty.songs.index(where: { // get index where new song should go
                        return $0.upVotes < newSong.upVotes
                    }) {
                        let indexPath:IndexPath = IndexPath(row: index, section: 0)
//                        self.songsTableView.beginUpdates()
                       currentParty.songs.insert(newSong, at: index)
//                        self.songsTableView.insertRows(at: [indexPath], with: .automatic)
//                        self.songsTableView.endUpdates()
                          self.sortSongs()  // TODO does changing this break things? motivation is that if you are adding a song in the middle of the tableview, all the cellID's are going to be messed up
                          self.songsTableView.reloadData()
                    } else {
                        let indexPath:IndexPath = IndexPath(row: currentParty.songs.count-1, section: 0)
                        self.songsTableView.beginUpdates()
                        currentParty.songs.append(newSong)
                        self.songsTableView.insertRows(at: [indexPath], with: .automatic)
                        self.songsTableView.endUpdates()
                    }
                    self.hideLoadingAnimation()
//                    self.sortSongs()
//                    self.songsTableView.reloadData()
                }
            }
        })
        
        playlistHandleRemove = SharedJamSeshModel.ref.child("parties").child(partyID).child("playlist").observe(DataEventType.childRemoved, with: { (snapshot) -> Void in
            if !snapshot.exists() {
                print("observed removed in playlist, null snapshot")
                return
            }
            // Find which child was removed, and delete that row
            // The snapshot passed to the callback block contains the data for the removed child.
            if let childSongSnapshot = snapshot as? DataSnapshot {
                // print("observed removed in playlist childSongsnapshot: \(snapshot)")
                let childSongID = (childSongSnapshot.value as! NSDictionary)["songID"] as! Int
                if let i = self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs.index(where: { $0.songID == childSongID }) {
                    print("observed removed in playlist \(self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs[i].songName) :: \(self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs.count) :: \(i) :: \(self.songsTableView.numberOfRows(inSection: 0))")
                    let rowToDelete = IndexPath.init(row: i, section: 0)
                    let rowsToDelete = [rowToDelete]
                    if (self.songsTableView.numberOfRows(inSection: 0) > 0) {
                        self.songsTableView.beginUpdates()
                        self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs.remove(at: i)
                        self.songsTableView.deleteRows(at: rowsToDelete, with: .automatic)
                        self.songsTableView.endUpdates()
                    }
                    
                    
                    self.sortSongs()
                    self.songsTableView.reloadData() // TODO maybe causing crash
                    
                    if(self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs.isEmpty) {
                        self.showEmptyPlaylistButton()
                    }
                }
            }
        })
        
        playlistHandleModify = SharedJamSeshModel.ref.child("parties").child(partyID).child("playlist").observe(DataEventType.childChanged, with: { (snapshot) -> Void in
            print("observed change in playlist")
            print(snapshot)
            if !snapshot.exists() {
                return
            }
            // Find which child was changed, and update that row
            // The snapshot passed to the event listener contains the updated data for the child.
            let childSongID = (snapshot.value as! NSDictionary)["songID"] as! Int
            // Get changed song index in curent songs array
            if let i = self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs.index(where: { $0.songID == childSongID }) {
                
                let newUpVotes = (snapshot.value as! NSDictionary)["upVotes"] as! Int
                // Check if was upvote or downvote
                let isUpVote = (self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs[i].upVotes <= newUpVotes) // if true, then change is upvote, if false, then downvote
                
                self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs[i].upVotes = newUpVotes
                print("reloading \(i)")
                let rowToReload = IndexPath.init(row: i, section: 0)
                let rowsToReload = Array.init(arrayLiteral: rowToReload)
                
                self.songsTableView.beginUpdates()
                self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs[i].upVotes = newUpVotes
                self.songsTableView.reloadRows(at: rowsToReload, with: .automatic)
                self.songsTableView.endUpdates()
                
                /* Animate moving song rows */
                if (isUpVote) {
                    self.moveUpVote(rowToMove: i)
                }
                else{
                    self.moveDownVote(rowToMove: i, newUpVotes: newUpVotes)
                }
            }
        })
    }
    /*****************************************************************************/
    
    
    /****************************************************************************/
    // Upvote rearrangement logic - go to row where row upvotes are less than new song's upvotes, and put it there.
    func moveUpVote(rowToMove: Int) {
        if let toIndex = self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs.index(where: {
            let fromSong = self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs[rowToMove]
                print("upvote: \($0.upVotes) - \(fromSong.upVotes)")
                if ($0.upVotes == fromSong.upVotes && $0.songID == fromSong.songID) { return true }
                return $0.upVotes < fromSong.upVotes
            }) {
            print("From Index: \(rowToMove) - Upvotes: \(self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs[rowToMove].upVotes) : To Index: \(toIndex) - UpVotes\(self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs[toIndex].upVotes)")
            self.moveSongFromTo(fromIndex: rowToMove, toIndex: toIndex)
        }
    }
    /****************************************************************************/
    
    /****************************************************************************/
    func moveDownVote(rowToMove: Int, newUpVotes: Int) {
        print("moveDownVote")
        let songName = self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs[rowToMove].songName
        if ( newUpVotes < 0 ) {
            if( isHost ) {
                let appearance = SCLAlertView.SCLAppearance( // Prompt host to remove song as has less than 0 upvotes
                    showCloseButton: false
                )
                let alertView = SCLAlertView(appearance: appearance)
                alertView.addButton("Remove") {
                    print("REMOVE: \(self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs) :: \(rowToMove)")
                    self.SharedJamSeshModel.removePartySong(song: self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs[rowToMove])
                }
                alertView.addButton("Don't remove") {
                    self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs[rowToMove].upVotes = 0
                    self.setSongUpVotesOnFirebase(songName: songName, newUpVotes: 0)
                }
                alertView.showInfo("Remove Song?", subTitle: "\(songName) has less than zero upvotes. Remove from playlist?")
            }
        } else { // Downvote rearrangement logic
            for (index, item) in self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs.enumerated().reversed() {
                    print( "\(item.songName) \(item.upVotes) \(index)")
            }
            for (index, item) in self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs.enumerated().reversed() {
                    if (item.upVotes > newUpVotes && index > rowToMove) {
                        print("move downvote from \(rowToMove)(\(newUpVotes)) to \(index)(\(item.upVotes))")
                        self.moveSongFromTo(fromIndex: rowToMove, toIndex: index)
                    } else if (item.songName == songName) {
                        // TODO
                }
            }
        }
    }
    /****************************************************************************/
    
    /*****************************************************************************/
    func pullSongImages() {
        print("pull song images")
        var counter = 0
        for song in self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs {
            var songImage = UIImage(named: "party")
            if song.songImage != nil  && song.songImage != UIImage(named:"party")!{
                print("VWA NOT null song image\(song.songName)")
                counter = counter + 1
            } else {
                DispatchQueue.global(qos: .userInitiated).async {
                    let url1 = URL(string: song.songImageURL)
                    if (url1 != nil) {
                        if let data = try? Data(contentsOf: url1!)  {
                            //print("VWA song image: \(song.songName) SET \(counter)")
                            song.songImage = UIImage(data: data)!
                            songImage = UIImage(data: data)!
                            counter = counter + 1
                        }
                    } else {
                        counter = counter + 1
                    }
                }
            }
        }
        
        while ( counter < self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs.count ) {
            print("* \(counter) \(self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs.count)")
            sleep(1)
            // Wait for all song images to be loaded
        }
        
        // Hide indicator animation view
        hideLoadingAnimation()
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func songChanged (notification: Notification) -> Void {
        let currentParty = SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex]
        print("song changed")
        if partyMusicHandler.getPlaybackState() == MPMusicPlaybackState.stopped {
            print("song changed \((notification.userInfo?.first?.value as? Int)!)")
            currentParty.currentSongPersistentIDKey = (notification.userInfo?.first?.value as? Int)!
            if(currentParty.songs.count > 0){
                playNextSong()
            } else {
                self.showEmptyPlaylistButton()
            }
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    @IBAction func newSuggestSongButtonPressed(_ sender: Any) {
        print(" new suggest song button pressed")
        emptyPlaylistButtonPressed()
    }
    /*****************************************************************************/
    
    func emptyPlaylistButtonPressed() {
        performSegue(withIdentifier: "suggestSongSegue", sender: self)
    }
    
    func dismissEmptyPlaylistButtonPressed() {
        self.hideEmptyPlaylistButton()
    }
    
    /*****************************************************************************/
    func chatBarButtonPressed() {
        self.performSegue(withIdentifier: "ChatSegue", sender: self)
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    @IBAction func suggestSongButton(_ sender: Any) {
        print("suggest song button pressed")
        emptyPlaylistButtonPressed()
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].songs.count
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongTableViewCell
        cell.delegate = self
        let song = SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].songs[indexPath.row]
        var songImage = UIImage(named: "party")
        if song.songImage != nil  && song.songImage != UIImage(named:"party")! {
            //print("NOT null song image\(song.songName)")
            songImage = song.songImage
            cell.songImage.image = songImage
        } else if song.songImageURL != "" {
            let v = makeLoadingIndicatorView(tempView: cell.songImage)
            cell.songImage.addSubview(v)
            cell.addConstraint(NSLayoutConstraint(item: v, attribute: .trailing, relatedBy: .equal, toItem: cell.songImage, attribute: .trailing, multiplier: 1, constant: 0))
            cell.addConstraint(NSLayoutConstraint(item: v, attribute: .leading, relatedBy: .equal, toItem: cell.songImage, attribute: .leading, multiplier: 1, constant: 0))
            cell.addConstraint(NSLayoutConstraint(item: v, attribute: .top, relatedBy: .equal, toItem: cell.songImage, attribute: .top, multiplier: 1, constant: 0))
            cell.addConstraint(NSLayoutConstraint(item: v, attribute: .bottom, relatedBy: .equal, toItem: cell.songImage, attribute: .bottom, multiplier: 1, constant: 0))
            
            DispatchQueue.global(qos: .userInitiated).async {
                let url1 = URL(string: song.songImageURL)
                if let data = try? Data(contentsOf: url1!)  {
                    songImage = UIImage(data: data)!
                    DispatchQueue.main.async {
                        cell.songImage.image = songImage
                        cell.reloadInputViews()
                        for view in cell.songImage.subviews {
                            if let indicatorView = view as? NVActivityIndicatorView { // if the view is an activity indicator view
                                indicatorView.stopAnimating()
                            }
                            view.removeFromSuperview()
                        }
                    }
                }
            }
        }
        cell.cellId = indexPath.row
        // cell.partyID = self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].partyID
        cell.songName.text = song.songName
        cell.songArtist.text = song.songArtist
        cell.upvoteCounter = song.upVotes
        cell.upvoteCount.text = String(cell.upvoteCounter)
        
        return cell
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func makeLoadingIndicatorView(tempView: UIView) -> UIView{
        // Set up loading view animation
        let tempLoadingIndicatorView = NVActivityIndicatorView(frame: tempView.frame, type: NVActivityIndicatorType(rawValue: 31), color: UIColor.purple )
        tempLoadingIndicatorView.center = tempView.center
        tempLoadingIndicatorView.startAnimating()
        
        let tempOverlay = UIView(frame: tempView.frame)
        tempOverlay.backgroundColor = UIColor.black
        tempOverlay.alpha = 0.5
        
        tempLoadingIndicatorView.addSubview(tempOverlay)
        
        return tempLoadingIndicatorView
        
        
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func setSongUpVotesOnFirebase(songName: String, newUpVotes: Int) {
        let currentParty = SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex]
        // Send change to firebase, change will be handled upon receiving the data changed event from firebase
        let songRef = SharedJamSeshModel.ref.child("parties").child(currentParty.partyID).child("playlist").child(songName)
        songRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if var post = currentData.value as? [String : AnyObject] {
                // Increment the number joined by 1
                post["upVotes"] = newUpVotes - 1 as AnyObject?
                // Set value and report transaction success
                currentData.value = post
                return TransactionResult.success(withValue: currentData)
            }
            return TransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                print("error: \(error.localizedDescription)")
            }
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    // SongTableViewCell Delegate Function
    // If there are less than 0 downvotes, prompt user to remove song from queue
    func downvoteButtonPressed(cellId: Int) {
        let currentParty = SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex]
        
            // Send change to firebase, change will be handled upon receiving the data changed event from firebase
        if( cellId < currentParty.songs.count) {
            let songName = SharedJamSeshModel.encodeForFirebaseKey(string: (currentParty.songs[cellId].songName))
            let songRef = SharedJamSeshModel.ref.child("parties").child(currentParty.partyID).child("playlist").child(songName)
            songRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                if var post = currentData.value as? [String : AnyObject] {
                    // Increment the number joined by 1
                    let upVotes = post["upVotes"] as? Int ?? 0
                    post["upVotes"] = upVotes - 1 as AnyObject?
                    // Set value and report transaction success
                    currentData.value = post
                    return TransactionResult.success(withValue: currentData)
                }
                return TransactionResult.success(withValue: currentData)
            }) { (error, committed, snapshot) in
                if let error = error {
                    print(error.localizedDescription)
                }
            }
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    // SongTableViewCell Delegate Function
    func upvoteButtonPressed(cellId: Int) {
        let currentParty = SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex]
        
        // Send change to firebase, change will be handled upon receiving the data changed event from firebase
        let songName = SharedJamSeshModel.encodeForFirebaseKey(string: (currentParty.songs[cellId].songName))
        print("upvote pressed :: \(songName) :: \(cellId)")
        let songRef = SharedJamSeshModel.ref.child("parties").child(currentParty.partyID).child("playlist").child(songName)
        songRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if var post = currentData.value as? [String : AnyObject] {
                // Increment the number joined by 1
                let upVotes = post["upVotes"] as? Int ?? 0
                post["upVotes"] = upVotes + 1 as AnyObject?
                // Set value and report transaction success
                currentData.value = post
                return TransactionResult.success(withValue: currentData)
            }
            return TransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func moveSongFromTo(fromIndex: Int, toIndex: Int) {
        
        // switch songs at the indices
        if ( fromIndex != toIndex ) {
           self.songsTableView.beginUpdates()
            self.songsTableView.moveRow(at: NSIndexPath(row: fromIndex, section: 0) as IndexPath, to: NSIndexPath(row: toIndex, section: 0) as IndexPath)
            SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].songs.rearrange(from: fromIndex, to: toIndex)
            self.songsTableView.endUpdates()
                print( "Moved \(fromIndex) to \(toIndex)")
        }
        
        // change all cell IDs after the toIndex (increment them all by one
        // Iterate over all the rows of a section
        print("change cell ids")
        for i in stride(from: toIndex, to: self.songsTableView.numberOfRows(inSection: 0), by: 1) {
            let cell = self.songsTableView.cellForRow(at: NSIndexPath(row: i, section: 0) as IndexPath) as? SongTableViewCell
            cell?.cellId = i
            if ( cell != nil ) {
                //print("\(cell?.songName.text) - \(cell?.cellId)")
            }
        }
    }
    /*****************************************************************************/
                    
    /*****************************************************************************/
    func sortSongs() {
        SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].songs.sort(by: {
            return $0.upVotes > $1.upVotes
        })
        //self.songsTableView.reloadData()
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ChatSegue" {
            if let chatVC = segue.destination as? FirebaseChatViewController {
                let currentParty = SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex]
                chatVC.channelRef = SharedJamSeshModel.ref.child("parties").child(currentParty.partyID)
                print("USERNAME: \(SharedJamSeshModel.myUser.username)")
                chatVC.senderDisplayName = SharedJamSeshModel.myUser.username
                chatVC.title = currentParty.partyName
            }
        } else if segue.identifier == "ReturnToPartiesSegue" {
            if let partiesVC = segue.destination as? PartiesTableViewController {
                partiesVC.partyEndedNotification()
            }
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if(self.isMovingFromParentViewController){
            let appearance = SCLAlertView.SCLAppearance(
                showCloseButton: false
            )
            let alertView = SCLAlertView(appearance: appearance)
            alertView.addButton("Leave Party") {
                return true
            }
            alertView.addButton("Stay in Party") {
                return false
            }
            alertView.showInfo("Cancel your current Party?", subTitle: "You are currently hosting a party, and joining a different party will cause your current party to be canceled. Are you sure you want to leave your party?")
        }
        
        // by default, transition
        return true
    }
    /*****************************************************************************/

    /*****************************************************************************/
    func loadingAnimation () {
        let indicator = NVActivityIndicatorView(frame: CGRect(x:0, y:0, width:40, height:40), type: NVActivityIndicatorType(rawValue: 31), color: UIColor.purple )
            indicator.center = self.view.center
            self.view.addSubview(indicator)
    }
    /*****************************************************************************/
    
    
    /*****************************************************************************/
    /*****************              HOST                       *******************/
    /*****************************************************************************/
    
    /*****************************************************************************/
    func timerFired(_:AnyObject) {
        let currentParty = SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex]
    
        // TODO: song duration
        let trackDurationMinutes = Int(currentParty.currentSong.songDuration / 60)
        
        let trackDurationSeconds = Int(currentParty.currentSong.songDuration % 60)
        if trackDurationSeconds < 10 {
            currentlyPlayingSongDurationLabel.text = "\(trackDurationMinutes):0\(trackDurationSeconds)"
        } else {
            currentlyPlayingSongDurationLabel.text = "\(trackDurationMinutes):\(trackDurationSeconds)"
        }
        if (!partyMusicHandler.getCurrentPlaybackTime().isNaN && !partyMusicHandler.getCurrentPlaybackTime().isInfinite) {
            let trackElapsed = partyMusicHandler.getCurrentPlaybackTime()
            var trackElapsedMinutes = 0
            if !(trackElapsed.isNaN || trackElapsed.isInfinite) {
                trackElapsedMinutes = Int(trackElapsed / 60)
            }
            if !(trackElapsed.isNaN || trackElapsed.isInfinite) {
                let trackElapsedTruncated = trackElapsed.truncatingRemainder(dividingBy: 60)
                if !(trackElapsedTruncated.isNaN || trackElapsedTruncated.isInfinite) {
                    let trackElapsedSeconds = Int(trackElapsedTruncated)
                    if trackElapsedSeconds < 10 {
                        currentlyPlayingSongTimeElapsedLabel.text = "\(trackElapsedMinutes):0\(trackElapsedSeconds)"
                    } else {
                        currentlyPlayingSongTimeElapsedLabel.text = "\(trackElapsedMinutes):\(trackElapsedSeconds)"
                    }
                } else {
                    currentlyPlayingSongTimeElapsedLabel.text = "\(trackElapsedMinutes):00"
                }
            }
            
            currentlyPlayingSongTimeSlider.maximumValue = Float(currentParty.currentSong.songDuration)
            currentlyPlayingSongTimeSlider.value = Float(trackElapsed)
            if ( Float(trackElapsed) >= Float(currentParty.currentSong.songDuration)) {
                moveToNextSong()
            }
        }
        
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    @IBAction func songSliderTimeChanged(_ sender: Any) {
        self.stopTimer()
        partyMusicHandler.setCurrentPlaybackTime(time: TimeInterval(currentlyPlayingSongTimeSlider.value))
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func updateNowPlayingInfo(){
        if(isHost) {
            if (self.timer == nil) {
                self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(PartyViewController.timerFired(_:)), userInfo: nil, repeats: true)
                self.timer?.tolerance = 0.1
            }
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/

    func stopTimer() {
        if let t = self.timer {
            t.invalidate()
            self.timer = nil
        }
    }
    /*****************************************************************************/

    /*****************************************************************************/
    @IBAction func nextButtonPressed(_ sender: Any) {
        // playNextSong()
        print("next button pressed")
        moveToNextSong()
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    @IBAction func playPauseButtonPressed(_ sender: Any) {
        if(partyMusicHandler.getPlaybackState() == MPMusicPlaybackState.paused){
            print("play")
            playPauseButton.titleLabel?.text = "Play"
        } else if(partyMusicHandler.getPlaybackState()==MPMusicPlaybackState.playing){
            print("pause")
            playPauseButton.titleLabel?.text = "Pause"
        }
        partyMusicHandler.playPause()
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func endPartyButtonPressed() {
        print("end button pressed")
        let partyID = self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].partyID
        SharedJamSeshModel.ref.child("parties").child(partyID).child("partyEndNotification").setValue(true) { error in
            if error != nil {
                print("error \(error)")
            } else {
                print("party end notification sent")
            }
        }
    }
    /*****************************************************************************/
}

extension UIButton {
    func hideAndAllowTouchesThrough() {
        self.isHidden = true
        self.isUserInteractionEnabled = false
    }
    
    func show() {
        self.isHidden = false
        self.isUserInteractionEnabled = true
    }
}
