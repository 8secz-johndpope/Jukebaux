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

protocol SongTableViewCellDelegate {
    func upvoteButtonPressed(cellId: Int)
    func downvoteButtonPressed(cellId: Int)
}

//this party is referred to as SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex] throughout this view controller code
class PartyViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SongTableViewCellDelegate {
    
    let SharedJamSeshModel = JamSeshModel.shared
    let partyMusicHandler = PlayMusicHandler.shared
    var timer = Timer()
    
    var handle : DatabaseHandle?
    
    var party : Party = Party()
    let nc = NotificationCenter.default
    var isHost : Bool = false
    
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
    @IBOutlet var emptyQueueButton: UIButton!
    
    var chatBarButtonItem  = UIButton(type: .custom)
    
    /*****************************************************************************/
    override func viewDidLoad() {
        super.viewDidLoad()
        partyImage.image = party.image
        partyNameLabel.text = party.partyName
        emptyQueueButton.isHidden=true
        songsTableView.delegate = self
        songsTableView.dataSource = self
        songsTableView.layer.borderWidth = 5.0;
        songsTableView.layer.borderColor = UIColor.purple.cgColor
        loadPartyFromFirebase()
        
        let px = 1 / UIScreen.main.scale
        let frame = CGRect(x:0, y:0, width:songsTableView.frame.size.width, height: px)
        let header = UILabel(frame: CGRect(x:0, y:0, width:songsTableView.frame.size.width, height: px))
        let line = UIView(frame: frame)
        line.addSubview(header)
        songsTableView.tableHeaderView = line
        
        currentlyPlayingSongTimeSlider.setThumbImage(UIImage(named: "triangle")!, for: .normal)
        
        nc.addObserver(forName:Notification.Name.MPMusicPlayerControllerNowPlayingItemDidChange,
                       object:nil, queue:nil,
                       using:songChanged)
        
        //check if the user is the host of the party. Being the host will allow them to perform functionalities like playing music etc.
        if SharedJamSeshModel.myUser.userID == SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].hostID {
            isHost = true
        } else {
            isHost  = false
            playPauseButton.isHidden = true
            nextButton.isHidden = true
        }
        
        if isHost && !SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].hasStarted{
            if SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].currentSong.songName != "" {
                self.playCurrentSong()
                self.updateNowPlayingInfo()
            } else {
                self.playNextSong()
                self.updateNowPlayingInfo()
            }
        }
    }
    /*****************************************************************************/
    
    
    
    /*****************************************************************************/
    override func viewWillAppear(_ animated: Bool) {
        //loadPartyFromFirebase()
        
        if isHost && partyMusicHandler.getPlaybackState() == MPMusicPlaybackState.stopped {
            if( SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].songs.count < 1 ) {
                playCurrentSong()
            }else {
                playNextSong()
            }
            updateNowPlayingInfo()
        }
        songsTableView.reloadData()
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    deinit {
        
        if let refHandle = handle {
            SharedJamSeshModel.ref.removeObserver(withHandle: refHandle)
        }
        
        
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func playNextSong () {
        //if songs are empty
        if SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].songs.count < 1 {
            //emptyQueueLabel.isHidden = false
            //emptyQueueButton.isHidden = false
        }
        else {
            //emptyQueueLabel.isHidden = true
            //emptyQueueButton.isHidden = true
            
            //try just playing one song at a time
            sortSongs()
            partyMusicHandler.appleMusicPlayTrackId(ids: [String(describing: SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].songs[0].songID)])
            SharedJamSeshModel.setPartySong(song: SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].songs[0])
            updateNowPlayingInfo()
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func playCurrentSong () {
        //if songs are empty
        if SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].songs.count < 1 {
            //emptyQueueLabel.isHidden = false
            //emptyQueueButton.isHidden = false
        }
        else {
            //emptyQueueLabel.isHidden = true
            //emptyQueueButton.isHidden = true
            
            //try just playing one song at a time
            sortSongs()
            partyMusicHandler.appleMusicPlayTrackId(ids: [String(describing: SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].currentSong.songID)])
            SharedJamSeshModel.setPartySong(song: SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].currentSong)
            updateNowPlayingInfo()
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func loadPartyFromFirebase() {
        print("load party from firebase")
        handle = SharedJamSeshModel.ref.child("parties").observe(DataEventType.value, with: { (snapshot) in
            if !snapshot.exists() {
                return
            }
            if let child = snapshot.childSnapshot(forPath: self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].partyID) as? DataSnapshot {
                if let party = Party(snapshot: child) as? Party {
                    if !(snapshot.value is NSNull) {
                        let snapshotValue = snapshot.value as! [String: AnyObject]
                        if snapshotValue["playlist"] != nil {
                            let tempSongsDict = snapshotValue["playlist"] as! NSDictionary
                            print("here: \(tempSongsDict)")
                            for element in tempSongsDict {
                                //run on background thread because pulling song image takes a while
                                print("element: \(element)")
                                DispatchQueue.main.async{
                                    let s = Song(dictionary: element.value as! NSDictionary)
                                    print(s.songName)
                                    party.songs.append(s)
                                    self.songsTableView.reloadData()
                                }
                            }
                        }
                    }
                    self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex] = party
                    }
                }
            self.sortSongs()
            self.songsTableView.reloadData()
        })
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func songChanged (notification: Notification) -> Void {
        
        if partyMusicHandler.getPlaybackState() == MPMusicPlaybackState.stopped {
            SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].currentSongPersistentIDKey = (notification.userInfo?.first?.value as? Int)!
            if(SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].songs.count > 0){
                playNextSong()
                updateNowPlayingInfo()
            }
            sortSongs()
            songsTableView.reloadData()
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    @IBAction func chatButtonPressed(_ sender: Any) {
        
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    @IBAction func suggestSongButton(_ sender: Any) {
        
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    @IBAction func nextButtonPressed(_ sender: Any) {
        if(SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].songs.count > 0){
            playNextSong()
            updateNowPlayingInfo()
        }
        songsTableView.reloadData()
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    @IBAction func prevButtonPressed(_ sender: Any) {
        //TODO - Do i want to allow previous song functionality?
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    @IBAction func emptyQueueButtonPressed(_ sender: Any) {
        if SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].songs.count > 0 {
            //emptyQueueButton.isHidden = true
            //emptyQueueLabel.isHidden = true
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    @IBAction func playPauseButtonPressed(_ sender: Any) {
        if(partyMusicHandler.getPlaybackState()==MPMusicPlaybackState.paused){
            playPauseButton.titleLabel?.text = "Play"
            partyMusicHandler.playPause()
        } else if(partyMusicHandler.getPlaybackState()==MPMusicPlaybackState.playing){
            playPauseButton.titleLabel?.text = "Pause"
            partyMusicHandler.playPause()
        }
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
        if(song.songImage) != nil {
            songImage = song.songImage
        } else if song.songImageURL != nil {
            let url1 = URL(string: song.songImageURL)
            if let data = try? Data(contentsOf: url1!)  {
                songImage = UIImage(data: data)!
            }
        }
        
        cell.cellId = indexPath.row
        cell.songImage.image = songImage
        cell.songName.text = song.songName
        cell.songArtist.text = song.songArtist
        cell.upvoteCounter = song.upVotes
        cell.upvoteCount.text = String(cell.upvoteCounter)
        
        //cell.upvoteView = LAAnimationView.animationNamed("Twitterheart")
        
        return cell
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    //from SongTableViewCell delegate
    //if there are less than 0 downvotes, prompt user to remove song from queue
    func downvoteButtonPressed(cellId: Int) {
        if SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].songs[cellId].upVotes > 0 {
            SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].songs[cellId].upVotes -= 1
            
            SharedJamSeshModel.ref.child("parties").child(SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].partyID).runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                if var post = currentData.value as? [String : AnyObject] {
                    //increment the number joined by 1
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
        else {
            let alertView = SCLAlertView()
            alertView.addButton("Remove") {
                self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs.remove(at: cellId) //TODO implement these changes in firebase
            }
            alertView.addButton("Don't remove") {
                self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs[cellId].upVotes = 0
            }
            
            alertView.showInfo("Remove Song?", subTitle: "\(self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs[cellId].songName) has less than zero upvotes. Remove from playlist?") // Info
        }
        
        sortSongs()
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    //from SongTableViewCell delegate
    func upvoteButtonPressed(cellId: Int) {
        SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].songs[cellId].upVotes += 1
        self.songsTableView.reloadData()
        
        //send change to firebase
        let songName = SharedJamSeshModel.encodeForFirebaseKey(string: (SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].songs[cellId].songName))
        let songRef = SharedJamSeshModel.ref.child("parties").child(SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].partyID).child("playlist").child(songName)
            
            songRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if var post = currentData.value as? [String : AnyObject] {
                //increment the number joined by 1
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
        sortSongs()
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    //sort songs in songs array by number of upvotes
    func timerFired(_:AnyObject) {
        currentlyPlayingSongNameLabel.text = SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].currentSong.songName
        
        currentlyPlayingSongArtistLabel.text = SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].currentSong.songArtist
        
        currentlyPlayingSongImage.image = SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].currentSong.songImage
        
        
        //TODO  song duration
        let trackDurationMinutes = Int(SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].currentSong.songDuration / 60)
        
        let trackDurationSeconds = Int(SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].currentSong.songDuration % 60)
        if trackDurationSeconds < 10 {
            currentlyPlayingSongDurationLabel.text = "\(trackDurationMinutes):0\(trackDurationSeconds)"
        } else {
            currentlyPlayingSongDurationLabel.text = "\(trackDurationMinutes):\(trackDurationSeconds)"
        }
        if (partyMusicHandler.getCurrentPlaybackTime().isNaN || partyMusicHandler.getCurrentPlaybackTime().isInfinite) {
        } else {
            let trackElapsed = partyMusicHandler.getCurrentPlaybackTime()
            let trackElapsedMinutes = Int(trackElapsed / 60)
            
            let trackElapsedSeconds = Int(trackElapsed.truncatingRemainder(dividingBy: 60))
            
            if trackElapsedSeconds < 10 {
                currentlyPlayingSongTimeElapsedLabel.text = "\(trackElapsedMinutes):0\(trackElapsedSeconds)"
            } else {
                currentlyPlayingSongTimeElapsedLabel.text = "\(trackElapsedMinutes):\(trackElapsedSeconds)"
            }
            
            currentlyPlayingSongTimeSlider.maximumValue = Float(SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].currentSong.songDuration)
            currentlyPlayingSongTimeSlider.value = Float(trackElapsed)
        }
        
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func sortSongs() {
        SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].songs.sort(by: {
            return $0.upVotes > $1.upVotes
        })
        self.songsTableView.reloadData()
        //SharedJamSeshModel.updateParty(party: SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex], completionHandler: {_ in self.songsTableView.reloadData()})
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func updateNowPlayingInfo(){
        
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(PartyViewController.timerFired(_:)), userInfo: nil, repeats: true)
        self.timer.tolerance = 0.1
        
    }
    /*****************************************************************************/
    
    
    /*****************************************************************************/
    @IBAction func songSliderTimeChanged(_ sender: Any) {
        partyMusicHandler.setCurrentPlaybackTime(time: TimeInterval(currentlyPlayingSongTimeSlider.value))
        
    }
    /*****************************************************************************/
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        SharedJamSeshModel.ref.removeObserver(withHandle: handle!)
        
        if segue.identifier == "ChatSegue" {
            if let chatVC = segue.destination as? ChatViewController {
                chatVC.chatRef = SharedJamSeshModel.ref.child("parties").child(SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].partyID).child("chat")
                
                chatVC.senderDisplayName = SharedJamSeshModel.myUser.username
                chatVC.title = SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].partyName
            }
        }
    }
    
    //https://itunes.apple.com/search?term=\()&media=music&limit=15
    
}
