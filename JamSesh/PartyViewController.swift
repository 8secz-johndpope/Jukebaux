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
    var timer = Timer()
    
    var playlistHandleAdd : DatabaseHandle?
    var playlistHandleRemove : DatabaseHandle?
    var playlistHandleModify : DatabaseHandle?
    var numberJoinedHandle : DatabaseHandle?
    var partyHandle : DatabaseHandle?
    
    let notificationCenter = NotificationCenter.default
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
    var loadingIndicatorView : NVActivityIndicatorView!
    var overlay : UIView?
    
    /*****************************************************************************/
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Start loading view animation
        loadingIndicatorView = NVActivityIndicatorView(frame: CGRect(x:0,y:0,width:100,height:100), type: NVActivityIndicatorType(rawValue: 31), color: UIColor.purple )
        loadingIndicatorView.center = self.view.center
        
        overlay = UIView(frame: view.frame)
        overlay!.backgroundColor = UIColor.black
        overlay!.alpha = 0.7
        
        self.view.addSubview(overlay!)
        self.view.addSubview(loadingIndicatorView!)
        
        let currentParty = SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex]
        partyImage.image = currentParty.image
        
        partyNameLabel.text = currentParty.partyName
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
        
        notificationCenter.addObserver(forName:Notification.Name.MPMusicPlayerControllerNowPlayingItemDidChange,
                       object:nil, queue:nil,
                       using:songChanged)
        
        // Check if the user is the host of the party. Being the host will allow them to perform functionalities like playing music etc.
        if SharedJamSeshModel.myUser.userID == currentParty.hostID {
            isHost = true
            playPauseButton.isHidden = false
            nextButton.isHidden = false
        } else {
            isHost  = false
            playPauseButton.isHidden = true
            nextButton.isHidden = true
        }
        
        if isHost && !currentParty.hasStarted{
            if currentParty.currentSong.songName != "" {
                self.playCurrentSong()
                self.updateNowPlayingInfo()
            } else {
                self.playNextSong()
                self.updateNowPlayingInfo()
            }
        }
        
        print("call VWA")
        self.viewWillAppear(true)
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    override func viewWillAppear(_ animated: Bool) {
        let currentParty = SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex]
        print("IsHost: \(isHost)")
        if isHost && partyMusicHandler.getPlaybackState() == MPMusicPlaybackState.stopped {
            if( currentParty.songs.count < 1 ) {
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
        if let refHandle1 = playlistHandleAdd {
            SharedJamSeshModel.ref.removeObserver(withHandle: refHandle1)
        }
        if let refHandle2 = playlistHandleRemove {
            SharedJamSeshModel.ref.removeObserver(withHandle: refHandle2)
        }
        if let refHandle3 = playlistHandleModify {
            SharedJamSeshModel.ref.removeObserver(withHandle: refHandle3)
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func playNextSong () {
        let currentParty = SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex]
        // If songs are empty
        if currentParty.songs.count < 1 {
            //TODO: Handle empty songs
        }
        else {
            // Try just playing one song at a time
            partyMusicHandler.appleMusicPlayTrackId(ids: [String(describing: currentParty.songs[0].songID)])
            SharedJamSeshModel.setPartySong(song: currentParty.songs[0])
            updateNowPlayingInfo()
            let indexPath = [NSIndexPath(row: 0, section: 0)]
            self.songsTableView.deleteRows(at: indexPath as [IndexPath], with: .automatic)
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func playCurrentSong () {
        let currentParty = SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex]
        // If songs are empty
        if currentParty.songs.count < 1 {
            //TODO: Handle empty songs
        }
        else {
            // Try just playing one song at a time
            sortSongs()
            partyMusicHandler.appleMusicPlayTrackId(ids: [String(describing: currentParty.currentSong.songID)])
            SharedJamSeshModel.setPartySong(song: currentParty.currentSong)
            updateNowPlayingInfo()
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func loadPartyFromFirebase() {
        print("load party from firebase")
        self.loadingIndicatorView.isHidden = false
        self.loadingIndicatorView.startAnimating()
        self.overlay?.isHidden = false
        
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
        
        SharedJamSeshModel.ref.child("parties").child(partyID).child("currentSong").observe(DataEventType.value, with: { (snapshot) in
            if !snapshot.exists() {
                print("get current song doesnt exist")
                return
            }
            if let currentSongSnapshot = snapshot as? DataSnapshot {
                print("get current song: \(currentSongSnapshot)")
                let tempCurrentSong = Song(dictionary: currentSongSnapshot.value as! NSDictionary)
                self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].currentSong = tempCurrentSong
                if self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].currentSong.songName != "" {
                    self.playCurrentSong()
                    self.updateNowPlayingInfo()
                } else {
                    self.playNextSong()
                    self.updateNowPlayingInfo()
                }
            }
        })
        SharedJamSeshModel.ref.child("parties").child(partyID).child("playlist").observeSingleEvent(of: .value, with: { (snapshot) in
            if !snapshot.exists() {
                print("get playlist doesnt exist")
                self.loadingIndicatorView.stopAnimating()
                self.loadingIndicatorView.isHidden = true
                self.overlay?.isHidden = true
                self.view.willRemoveSubview(self.overlay!)
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
                        if counter >= dictSize {
                            self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs = playlist
                            self.sortSongs()
                            self.pullSongImages()
                            self.setPlaylistFBObservers(partyID: partyID)
                        }
                    }
                }
            }
        })
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
        
        playlistHandleAdd = SharedJamSeshModel.ref.child("parties").child(partyID).child("playlist").observe(DataEventType.childAdded, with: { (snapshot) -> Void in
            print("observed add in playlist")
            print(snapshot)
            if !snapshot.exists() {
                return
            }
            
            // The listener is passed a snapshot containing the new child's data.
            if let childSongSnapshot = snapshot as? DataSnapshot {
                let newSong = Song(dictionary: childSongSnapshot.value as! NSDictionary)
                self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs.append(newSong)
                self.songsTableView.beginUpdates()
                let end = self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs.count-1
                let indexPath:IndexPath = IndexPath(row: end, section: 0)
                self.songsTableView.insertRows(at: [indexPath], with: .automatic)
                self.songsTableView.endUpdates()
            }
        })
        
        playlistHandleRemove = SharedJamSeshModel.ref.child("parties").child(partyID).child("playlist").observe(DataEventType.childRemoved, with: { (snapshot) -> Void in
            print("observed removed in playlist")
            print(snapshot)
            if !snapshot.exists() {
                return
            }
            // Find which child was removed, and delete that row
            // The snapshot passed to the callback block contains the data for the removed child.
            if let childSongSnapshot = snapshot as? DataSnapshot {
                let childSongID = (childSongSnapshot.value as! NSDictionary)["songID"] as! Int
                if let i = self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs.index(where: { $0.songID as! Int == childSongID }) {
                    let rowToReload = IndexPath.init(row: i, section: 0)
                    let rowsToReload = Array.init(arrayLiteral: rowToReload)
                    self.songsTableView.beginUpdates()
                    self.songsTableView.deleteRows(at: rowsToReload, with: .automatic)
                    self.songsTableView.endUpdates()
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
            if let childSongSnapshot = snapshot as? DataSnapshot {
                let childSongID = (childSongSnapshot.value as! NSDictionary)["songID"] as! Int
                    if let i = self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs.index(where: { $0.songID as! Int == childSongID }) {
                        var upvoteIndicator = false // if true, then change is upvote, if false, then downvote
                        // Change is upvote (not downvote)
                        if (self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs[i].upVotes <= (childSongSnapshot.value as! NSDictionary)["upVotes"] as! Int) {
                            upvoteIndicator = true
                        }
                        self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs[i].upVotes = (childSongSnapshot.value as! NSDictionary)["upVotes"] as! Int
                        let rowToReload = IndexPath.init(row: i, section: 0)
                        let rowsToReload = Array.init(arrayLiteral: rowToReload)
                        self.songsTableView.beginUpdates()
                        self.songsTableView.reloadRows(at: rowsToReload, with: .automatic)
                        self.songsTableView.endUpdates()
                        
                        /* Animate moving song rows */
                        
                            if let toIndex = self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs.index(where: {
                                let tempSong = self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs[i]
                                if upvoteIndicator { // Upvote rearrangement logic - go to row where row upvotes are less than new song's upvotes, and put it there.
                                    if ($0.upVotes == tempSong.upVotes && $0.songID == tempSong.songID) { return true }
                                    return $0.upVotes < tempSong.upVotes
                                } else { // Downvote rearrangement logic
                                    return $0.upVotes > tempSong.upVotes
                                }
                            }) {
                                print("\(self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs[i].upVotes) : \(i) : \(toIndex)")
                                self.moveSongFromTo(fromIndex: i, toIndex: toIndex)
                            }
                    }
            }
        })
    }
    /*****************************************************************************/
    
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
                print("VWA IS null song image: \(song.songName)")
                DispatchQueue.global(qos: .userInitiated).async {
                    let url1 = URL(string: song.songImageURL)
                    print(url1)
                    if (url1 != nil) {
                        if let data = try? Data(contentsOf: url1!)  {
                            print("VWA song image: \(song.songName) SET \(counter)")
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
        self.songsTableView.reloadData()
        self.loadingIndicatorView.stopAnimating()
        self.loadingIndicatorView.isHidden = true
        self.overlay?.isHidden = true
        self.view.willRemoveSubview(self.overlay!)
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func songChanged (notification: Notification) -> Void {
        let currentParty = SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex]
        if partyMusicHandler.getPlaybackState() == MPMusicPlaybackState.stopped {
            currentParty.currentSongPersistentIDKey = (notification.userInfo?.first?.value as? Int)!
            if(currentParty.songs.count > 0){
                playNextSong()
                updateNowPlayingInfo()
            }
            sortSongs()
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
        if song.songImage != nil  && song.songImage != UIImage(named:"party")!{
            print("NOT null song image\(song.songName)")
            songImage = song.songImage
        } else if song.songImageURL != nil {
           print("IS null song image\(song.songName)")
            DispatchQueue.global(qos: .userInitiated).async {
                let url1 = URL(string: song.songImageURL)
                if let data = try? Data(contentsOf: url1!)  {
                    print("song image\(song.songName) SET")
                    songImage = UIImage(data: data)!
                }
            }
        }
                        
        cell.cellId = indexPath.row
        // cell.partyID = self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].partyID
        cell.songImage.image = songImage
        cell.songName.text = song.songName
        cell.songArtist.text = song.songArtist
        cell.upvoteCounter = song.upVotes
        cell.upvoteCount.text = String(cell.upvoteCounter)
        
        return cell
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    // SongTableViewCell Delegate Function
    // If there are less than 0 downvotes, prompt user to remove song from queue
    func downvoteButtonPressed(cellId: Int) {
        let currentParty = SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex]
        if currentParty.songs[cellId].upVotes > 0 {
            // Send change to firebase, change will be handled upon receiving the data changed event from firebase
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
        else {
            let alertView = SCLAlertView()
            alertView.addButton("Remove") {
                self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs.remove(at: cellId)
                //TODO implement these changes in firebase
            }
            alertView.addButton("Don't remove") {
                self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs[cellId].upVotes = 0
            }
            
            alertView.showInfo("Remove Song?", subTitle: "\(self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].songs[cellId].songName) has less than zero upvotes. Remove from playlist?") // Info
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    // SongTableViewCell Delegate Function
    func upvoteButtonPressed(cellId: Int) {
        let currentParty = SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex]
        
        // Send change to firebase, change will be handled upon receiving the data changed event from firebase
        let songName = SharedJamSeshModel.encodeForFirebaseKey(string: (currentParty.songs[cellId].songName))
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
    // sort songs in songs array by number of upvotes
    func timerFired(_:AnyObject) {
        let currentParty = SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex]
        currentlyPlayingSongNameLabel.text = currentParty.currentSong.songName
        
        currentlyPlayingSongArtistLabel.text = currentParty.currentSong.songArtist
        
        currentlyPlayingSongImage.image = currentParty.currentSong.songImage
        
        
        // TODO: song duration
        let trackDurationMinutes = Int(currentParty.currentSong.songDuration / 60)
        
        let trackDurationSeconds = Int(currentParty.currentSong.songDuration % 60)
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
            
            currentlyPlayingSongTimeSlider.maximumValue = Float(currentParty.currentSong.songDuration)
            currentlyPlayingSongTimeSlider.value = Float(trackElapsed)
        }
        
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func moveSongFromTo(fromIndex: Int, toIndex: Int) {
        self.songsTableView.beginUpdates()
        
        // 1. find next lowest row
        // 2. get location
        // 3. make change in UI and to array
        
        // switch songs at the indices
        if ( fromIndex != toIndex ) {
           
            self.songsTableView.moveRow(at: NSIndexPath(row: fromIndex, section: 0) as IndexPath, to: NSIndexPath(row: toIndex, section: 0) as IndexPath)
            SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex].songs.rearrange(from: fromIndex, to: toIndex)
            
                print( "Moved \(fromIndex) to \(toIndex)")
        }
        self.songsTableView.endUpdates()

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
        self.songsTableView.reloadData()
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
    
    /*****************************************************************************/
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "ChatSegue" {
            if let chatVC = segue.destination as? ChatViewController {
                let currentParty = SharedJamSeshModel.parties[SharedJamSeshModel.currentPartyIndex]
                chatVC.chatRef = SharedJamSeshModel.ref.child("parties").child(currentParty.partyID).child("chat")
                
                chatVC.senderDisplayName = SharedJamSeshModel.myUser.username
                chatVC.title = currentParty.partyName
            }
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func loadingAnimation () {
        let indicator = NVActivityIndicatorView(frame: CGRect(x:0, y:0, width:40, height:40), type: NVActivityIndicatorType(rawValue: 31), color: UIColor.purple )
            indicator.center = self.view.center
            self.view.addSubview(indicator)
    }
    /*****************************************************************************/
}

