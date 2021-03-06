//
//  PartyViewController.swift
//  Jukebaux
//
//  Created by Adam Moffitt on 1/27/17.
//  Copyright © 2017 Adam's Apps. All rights reserved.
//

//play by Kuber from the Noun Project

import UIKit
import MediaPlayer
import SCLAlertView
import QuartzCore
import FirebaseDatabase
import SimpleAnimation
import NVActivityIndicatorView
import EmptyDataSet_Swift
import FirebaseInvites
import LiquidFloatingActionButton
import SnapKit

protocol SongTableViewCellDelegate {
    func upvoteButtonPressed(cellId: Int, songID: String)
    func downvoteButtonPressed(cellId: Int, songID: String)
}

// The current party is referred to as SharedJukebauxModel.parties[SharedJukebauxModel.currentPartyIndex] throughout this view controller code
class PartyViewController: UIViewController {
    
    /***************** Outlets ********************/
    @IBOutlet var suggestSongButton: UIButton!
    @IBOutlet var isHostLabel: UILabel!
    @IBOutlet var suggestedByLabel: UILabel!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var currentlyPlayingSongView: UIView!
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

    /***************** Variables ********************/
    let SharedJukebauxModel = JukebauxModel.shared
    let partyMusicHandler = PlayMusicHandler.shared
    let notificationCenter = NotificationCenter.default
    var timer : Timer?
    var floatingActionButton : LiquidFloatingActionButton?
    var playlistHandleAdd : DatabaseHandle?
    var playlistHandleRemove : DatabaseHandle?
    var playlistHandleModify : DatabaseHandle?
    var currentSongHandle : DatabaseHandle?
    var numberJoinedHandle : DatabaseHandle?
    var partyHandle : DatabaseHandle?
    var partyEndHandle : DatabaseHandle?
    var isHost : Bool = false
    var suggestRandomSongsButton : UIButton!
    var endPartyBarButtonItem = UIBarButtonItem()
    var chatBarButtonItem = UIBarButtonItem()
    var loadingIndicatorView : NVActivityIndicatorView!
    var overlay : UIView!
    //    var emptyPlaylistButton : UIButton!
    var cells: [LiquidFloatingCell] = []
    var isEmpty = true {
        didSet {
            songsTableView.reloadEmptyDataSet()
        }
    }
    let refreshControl = UIRefreshControl()

    var isLoading = 0 {
        didSet {
            print("is loading: \(isLoading)")
            if isLoading < 1 {
                isLoading = 0
                hideLoadingAnimation()
            } else {
                showLoadingAnimation()
            }
        }
    }
    
    /*****************************************************************************/
    override func viewDidLoad() {
        super.viewDidLoad()
        print("view did load")
        self.becomeFirstResponder()
//        self.edgesForExtendedLayout = []
//        self.extendedLayoutIncludesOpaqueBars = false
//        self.automaticallyAdjustsScrollViewInsets = false
        
        // Set up loading view animation
        loadingIndicatorView = NVActivityIndicatorView(frame: CGRect(x:0,y:0,width:100,height:100), type: NVActivityIndicatorType(rawValue: 31), color: SharedJukebauxModel.mainJukebauxColor )
        loadingIndicatorView.center = self.view.center
        overlay = UIView(frame: view.frame)
        overlay.backgroundColor = UIColor.black
        overlay.alpha = 0.7
        
        self.view.addSubview(overlay!)
        self.view.addSubview(loadingIndicatorView!)
        
        let currentParty = SharedJukebauxModel.parties[SharedJukebauxModel.currentPartyIndex]
        partyImage.image = currentParty.image
        partyNameLabel.text = currentParty.partyName
        
        loadPartyFromFirebase()
        
        songsTableView.delegate = self
        songsTableView.dataSource = self
        songsTableView.emptyDataSetSource = self
        songsTableView.emptyDataSetDelegate = self
        songsTableView.layer.borderWidth = 5.0;
        songsTableView.layer.borderColor = SharedJukebauxModel.mainJukebauxColor.cgColor
//        songsTableView.backgroundColor = UIColor(cgColor: SharedJukebauxModel.mainJukebauxColor.cgColor)
        songsTableView.tableFooterView = UIView()
        let px = 1 / UIScreen.main.scale
        let frame = CGRect(x:0, y:0, width:songsTableView.frame.size.width, height: px)
        let header = UILabel(frame: CGRect(x:0, y:0, width:songsTableView.frame.size.width, height: px))
        let line = UIView(frame: frame)
        line.addSubview(header)
        songsTableView.tableHeaderView = line
        
        //currentlyPlayingSongTimeSlider.setThumbImage(UIImage(named: "triangle")!, for: .normal)
        
        suggestSongButton.clipsToBounds = true
        suggestSongButton.layer.cornerRadius = 10
        
        makeSuggestSongsWhenEmptyButton()
        
        // Button to prompt user to add songs when playlist is empty UPDATE: now using empty list pod
//        emptyPlaylistButton = UIButton(frame: CGRect(x: self.view.frame.minX + 10, y: self.view.frame.minY+100, width: self.view.frame.width-20, height: 400))
//        emptyPlaylistButton.alpha = 0.8
//        emptyPlaylistButton.backgroundColor = SharedJukebauxModel.mainJukebauxColor
//        emptyPlaylistButton.setTitle("The playlist for this party is empty! Click here to add some songs and keep the tunes rolling.",for: .normal)
//        emptyPlaylistButton.titleLabel?.numberOfLines = 0
//        emptyPlaylistButton.titleLabel?.textAlignment = NSTextAlignment.center
//        emptyPlaylistButton.titleLabel?.textColor = UIColor.white
//        emptyPlaylistButton.addTarget(self, action:#selector(emptyPlaylistButtonPressed), for: .touchUpInside)
//        let dismissButton = UIButton(frame: CGRect(x: 20, y: 3*emptyPlaylistButton.frame.height/4, width: emptyPlaylistButton.frame.width-40, height: 40))
//        dismissButton.backgroundColor = UIColor.black
//        dismissButton.setTitle("Dismiss",for: .normal)
//        dismissButton.titleLabel?.textAlignment = NSTextAlignment.center
//        dismissButton.titleLabel?.textColor = SharedJukebauxModel.mainJukebauxColor
//        dismissButton.addTarget(self, action:#selector(dismissEmptyPlaylistButtonPressed), for: .touchUpInside)
        //emptyPlaylistButton.addSubview(dismissButton)
        //chatBarButtonItem = UIBarButtonItem(image: UIImage(named: "chat"), style: .done, target: self, action: #selector(chatBarButtonPressed))
        
        // Check if the user is the host of the party. Being the host will allow them to perform functionalities like playing music etc.
        if SharedJukebauxModel.myUser.userID == currentParty.hostID { // User is Host
            isHostLabel.text = "You are the Host"
            isHost = true
            playPauseButton.isHidden = false
            nextButton.isHidden = false
            endPartyBarButtonItem =  UIBarButtonItem(title: "End Party", style: UIBarButtonItemStyle.plain, target: self, action: #selector(endPartyButtonPressed))
//            self.navigationItem.rightBarButtonItems = [chatBarButtonItem, endPartyBarButtonItem]
            self.navigationItem.rightBarButtonItems = [endPartyBarButtonItem]
        } else { // user is not host
            isHost  = false
            //self.navigationItem.rightBarButtonItems = [chatBarButtonItem]
            isHostLabel.text = "You are the not the Host"
            playPauseButton.isHidden = true
            nextButton.isHidden = true
            currentlyPlayingSongTimeSlider.isHidden = true
            currentlyPlayingSongTimeElapsedLabel.isHidden = true
            currentlyPlayingSongDurationLabel.isHidden = true
        }
        
        scrollView.delegate = self
        
        floatingActionButton = LiquidFloatingActionButton(frame: CGRect(x: self.view.frame.width - 56 - 16, y: self.view.frame.height - 56 - 16, width: 56, height: 56))
        floatingActionButton?.animateStyle = LiquidFloatingActionButtonAnimateStyle.up
        floatingActionButton?.dataSource = self
        floatingActionButton?.delegate = self
        let customCellFactory: (String, String) -> LiquidFloatingCell = { (iconName, menuName) in
            let cell = CustomCell(icon: UIImage(named: iconName)!, name: menuName)
            return cell
        }
        cells.append(customCellFactory("invite", "Invite"))
        cells.append(customCellFactory("music-library", "Library"))
        cells.append(customCellFactory("music-player", "Apple Music"))
        
        self.view.addSubview(floatingActionButton!)
        
        refreshControl.addTarget(self, action: #selector(refresh), for: UIControlEvents.valueChanged)
        self.scrollView.addSubview(refreshControl)
    }
    /*****************************************************************************/
    
    @objc func refresh() {
        self.songsTableView.reloadData()
        self.refreshControl.endRefreshing()
    }
    
    /*****************************************************************************/
    override func viewWillAppear(_ animated: Bool) {
        
        //        for barItem in self.navigationItem.rightBarButtonItems! {
        //            barItem.style
        //        }
        
        //self.navigationItem.rightBarButtonItem = UIBarButtonStyle.done
        
        print("view will appear \(partyMusicHandler.getPlaybackState().rawValue)")
        
        songsTableView.reloadData()
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    deinit {
        print("deinit")
        stopTimer()
        let partyID = self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].partyID
        
        if let refHandleAdd = playlistHandleAdd {
            SharedJukebauxModel.ref.child("parties").child(partyID).child("playlist").removeObserver(withHandle: refHandleAdd)
        }
        if let refHandleRemove = playlistHandleRemove {
            SharedJukebauxModel.ref.child("parties").child(partyID).child("playlist").removeObserver(withHandle: refHandleRemove)
        }
        if let refHandleObserve = playlistHandleModify {
            SharedJukebauxModel.ref.child("parties").child(partyID).child("playlist").removeObserver(withHandle: refHandleObserve)
        }
        if let currentSongH = currentSongHandle {
            SharedJukebauxModel.ref.child("parties").child(partyID).removeObserver(withHandle:  currentSongH)
        }
        if let partyEndH = partyEndHandle {
            SharedJukebauxModel.ref.child("parties").child(partyID).removeObserver(withHandle:  partyEndH)
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func makeSuggestSongsWhenEmptyButton() { // TODO WHY IS THIS APPEARING UNDER TABLEVIEW????!!!!!!!!!
        suggestRandomSongsButton = UIButton(frame: CGRect(x:5, y:5, width: self.currentlyPlayingSongView.frame.width-10, height: currentlyPlayingSongView.frame.height-10))
        suggestRandomSongsButton.center = self.currentlyPlayingSongView.center
        suggestRandomSongsButton.backgroundColor = SharedJukebauxModel.mainJukebauxColor
        suggestRandomSongsButton.addTarget(self, action: #selector(suggestSongs), for: .touchUpInside)
        suggestRandomSongsButton.setTitle("Out of song ideas? Let us help. Click to here automatically add some popular songs!", for: .normal)
        suggestRandomSongsButton.titleLabel?.numberOfLines = 0
        suggestRandomSongsButton.titleLabel?.adjustsFontSizeToFitWidth=true
        suggestRandomSongsButton.isHidden = true
        suggestRandomSongsButton.titleLabel?.textAlignment = .center
        currentlyPlayingSongView.addSubview(suggestRandomSongsButton)
        currentlyPlayingSongView.bringSubview(toFront: suggestRandomSongsButton)
        
        suggestRandomSongsButton.centerXAnchor.constraint(equalTo: currentlyPlayingSongView.centerXAnchor).isActive = true
        suggestRandomSongsButton.centerYAnchor.constraint(equalTo: currentlyPlayingSongView.centerYAnchor).isActive = true
        suggestRandomSongsButton.topAnchor.constraint(equalTo: currentlyPlayingSongView.topAnchor).isActive = true
        suggestRandomSongsButton.bottomAnchor.constraint(equalTo: currentlyPlayingSongView.bottomAnchor).isActive = true
        suggestRandomSongsButton.leadingAnchor.constraint(equalTo: currentlyPlayingSongView.leadingAnchor).isActive = true
        suggestRandomSongsButton.trailingAnchor.constraint(equalTo: currentlyPlayingSongView.trailingAnchor).isActive = true
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
    func checkFirebasePartyPlaylistEmpty(completion: @escaping (Bool)->()) {
        let partyID = self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].partyID
        SharedJukebauxModel.ref.child("parties").child(partyID).child("playlist").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            print("check firebase party playlist empty \(snapshot)")
                if !snapshot.exists() {
                    completion(true)
                    return
                }
                completion(false)
//            if snapshot.hasChild("playlist") {
//                completion(false)
//            } else {
//                completion(true)
//            }
        })
    }
    /*****************************************************************************/

    
    /*****************************************************************************/
    func showEmptyPlaylistAlert() {
        let appearance = SCLAlertView.SCLAppearance( kCircleIconHeight: 45.0, showCircularIcon: true )
        let alert = SCLAlertView(appearance: appearance)
        alert.addButton("Choose Songs") {
            self.emptyPlaylistButtonPressed()
        }
        alert.addButton("Suggest Popular Songs") {
            self.suggestSongs()
        }
        alert.showInfo("Out of Songs!", subTitle: "Choose some songs or let us suggest some popular songs to keep the party rolling!", colorStyle: UInt(self.SharedJukebauxModel.mainJukebauxColorInt), circleIconImage: UIImage(named: "AppIcon"))
    }
    /*****************************************************************************/

    /*****************************************************************************/ //now using that pod to control empty songs
//    func showEmptyPlaylistButton() {
//        if (!self.view.subviews.contains(emptyPlaylistButton)) {
//            self.view.addSubview(emptyPlaylistButton)
//        }
//    }
//
//    func hideEmptyPlaylistButton() {
//        if (self.view.subviews.contains(emptyPlaylistButton)) {
//            emptyPlaylistButton.removeFromSuperview()
//        }
//    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func moveToNextSong() {
        print("MOVE TO NEXT SONG")
        if (SharedJukebauxModel.currentPartyIndex < SharedJukebauxModel.parties.count) {
            let currentParty = SharedJukebauxModel.parties[SharedJukebauxModel.currentPartyIndex]
            // If songs are empty
            if currentParty.songs.count < 1 {
                //Handle empty songs
                //showEmptyPlaylistButton()
                print("SHOW RANDOM SONG SUGGESTION BOX")
                self.suggestRandomSongsButton.isHidden = false
                checkFirebasePartyPlaylistEmpty(completion: {(empty) in
                    if empty {
//                        self.showEmptyPlaylistAlert() // cant figure out how to show this only when playlist is empty with firebase
                        self.isEmpty=true
                    }
                })
            }
            else {
                self.suggestRandomSongsButton.isHidden = true
//                hideEmptyPlaylistButton()
                SharedJukebauxModel.setPartySong(song: currentParty.songs[0])
                SharedJukebauxModel.removePartySong(song: currentParty.songs[0])
            }
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func playNextSong () {
        let currentParty = SharedJukebauxModel.parties[SharedJukebauxModel.currentPartyIndex]
        // If songs are empty
        if currentParty.songs.count < 1 {
            //Handle empty songs
            //showEmptyPlaylistButton()
            isEmpty=true
        }
        else {
//            hideEmptyPlaylistButton()
            // Play next song
            SharedJukebauxModel.setPartySong(song: currentParty.songs[0])
            partyMusicHandler.setCurrentPlaybackTime(time: 0)
            partyMusicHandler.appleMusicPlayTrackId(ids: [currentParty.songs[0].songID])
            partyMusicHandler.setCurrentPlaybackTime(time: 0)
            SharedJukebauxModel.removePartySong(song: currentParty.songs[0])
        }
        updateNowPlayingInfo()
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func playCurrentSong () {
        self.suggestRandomSongsButton.isHidden = true
        let currentParty = SharedJukebauxModel.parties[SharedJukebauxModel.currentPartyIndex]
        
        currentlyPlayingSongNameLabel.text = currentParty.currentSong.songName
        currentlyPlayingSongArtistLabel.text = currentParty.currentSong.songArtist
        //currentlyPlayingSongImage.image = currentParty.currentSong.songImage // TOdo uncomment ifimagenot loading
        
        //updateNowPlayingInfoCenter()
        //        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
        //            MPMediaItemPropertyTitle: currentParty.currentSong.songName,
        //            MPMediaItemPropertyArtist: currentParty.currentSong.songArtist,
        //            MPMediaItemPropertyArtwork: MPMediaItemArtwork(image: currentParty.currentSong.songImage)
        //        ]
        
        // Play current song
        partyMusicHandler.appleMusicPlayTrackId(ids: [currentParty.currentSong.songID])
        partyMusicHandler.setCurrentPlaybackTime(time: 0)
        updateNowPlayingInfo()
        
        // If songs are empty
        if currentParty.songs.count < 1 { // Handle empty songs
            //showEmptyPlaylistButton()
            isEmpty = true
        }
        else {
//            hideEmptyPlaylistButton()
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func loadPartyFromFirebase() {
        print("load party from firebase")
//        self.showLoadingAnimation()
        self.isLoading += 1 // When isLoading == 0 then loading animation is hidden
        let partyID = self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].partyID
        
        /*
         numberJoinedHandle = SharedJukebauxModel.ref.child("parties").child(partyID).child("numberJoined").observe(DataEventType.value, with: { (snapshot) in
         if !snapshot.exists() {
         return
         }
         if let numberJoinedSnapshot = snapshot as? DataSnapshot {
         print(numberJoinedSnapshot)
         if !(numberJoinedSnapshot.value is NSNull) {
         let snapshotValue = snapshot.value as! [String: AnyObject]
         let newNumberJoined = snapshotValue["numberJoined"] as! Int
         self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].numberJoined = newNumberJoined
         }
         }
         })
         */
        
        partyEndHandle = SharedJukebauxModel.ref.child("parties").child(partyID).child("partyEndNotification").observe(DataEventType.value, with: { (snapshot) in
            if !snapshot.exists() {
                print("bad partyEndNotification")
                return
            }
            print("party end notification received \(snapshot)")
            if let indicator = snapshot.value as? Bool{
                print(indicator)
                if indicator {
                    if let refHandleRemove = self.playlistHandleRemove {
                        self.SharedJukebauxModel.ref.child("parties").child(partyID).child("playlist").removeObserver(withHandle: refHandleRemove)
                    }
                    if let currentHandle = self.currentSongHandle {
                        self.SharedJukebauxModel.ref.child("parties").child(partyID).child("playlist").removeObserver(withHandle: currentHandle)
                    }
                    // TODO this is probably a bad way to do it as then you get a lot of people writing nils to FB but whateves hopefully it works for now
                    if (self.isHost) {
                        let partyID = self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].partyID
                        self.stopTimer()
                        self.partyMusicHandler.stop()
                        self.navigationController?.popViewController(animated: true)
                        self.SharedJukebauxModel.deletePartyImage(imageName: self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].savedImageURL)
                        self.SharedJukebauxModel.parties.remove(at: self.SharedJukebauxModel.currentPartyIndex)
                        
                        self.SharedJukebauxModel.ref.child("parties").child(partyID).setValue(nil) { error, arg  in
                            if error != nil {
                                print("party remove error \(String(describing: error))")
                            } else {
                                print("party removed")
                            }
                        }
                        self.SharedJukebauxModel.userDoneHosting()
                    } else {
                        let appearance = SCLAlertView.SCLAppearance(
                            showCloseButton: false
                        )
                        let alertView = SCLAlertView(appearance: appearance)
                        alertView.addButton("Okay", action: {
                            self.SharedJukebauxModel.parties.remove(at: self.SharedJukebauxModel.currentPartyIndex)
                            self.navigationController?.popViewController(animated: true)
                        })
                        alertView.showInfo("Your current party ended", subTitle: "Looks like the host ended the party. Join another party and keep the tunes coming!")
                    }
                }
            }
        })
        
        
        currentSongHandle  = SharedJukebauxModel.ref.child("parties").child(partyID).child("currentSong").observe(DataEventType.value, with: { (snapshot) in
            if !snapshot.exists() {
                print("get current song doesnt exist")
                if ( self.isHost ) {
                    self.moveToNextSong()
                    self.isLoading -= 1
                }
                return
            }
            if let currentSongSnapshot = snapshot as? DataSnapshot {
                
                let tempCurrentSong = Song(dictionary: currentSongSnapshot.value as! NSDictionary)
                
                if tempCurrentSong.songName == "" { // current song doesnt exist
                    print("get current song doesnt exist")
                    if ( self.isHost ) {
                        self.moveToNextSong()
                        self.isLoading -= 1
                    }
                    return
                }
                
                if (self.SharedJukebauxModel.currentPartyIndex < self.SharedJukebauxModel.parties.count) {
                    self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].currentSong = tempCurrentSong
                }
                print("get current song: \(tempCurrentSong.songName)")
                self.suggestRandomSongsButton.isHidden = true
                DispatchQueue.global(qos: .userInitiated).async {
                    let url1 = URL(string: tempCurrentSong.songImageURL)
                    if (url1 != nil) {
                        if let data = try? Data(contentsOf: url1!)  {
                            let image = UIImage(data: data)!
                            DispatchQueue.main.async {
                                self.currentlyPlayingSongImage.image = image
                                /*
                                 MPNowPlayingInfoCenter.default().nowPlayingInfo = [
                                 MPMediaItemPropertyTitle: tempCurrentSong.songName,
                                 MPMediaItemPropertyArtist: tempCurrentSong.songArtist,
                                 MPMediaItemPropertyArtwork: MPMediaItemArtwork(image: image)
                                 ] */
                            }
                            self.updateNowPlayingInfoCenter()
                        }
                    }
                }
                
                self.currentlyPlayingSongNameLabel.text = tempCurrentSong.songName
                self.currentlyPlayingSongArtistLabel.text = tempCurrentSong.songArtist
                print("suggestedBy: \(tempCurrentSong.suggestedBy)")
                if tempCurrentSong.suggestedBy != "" {
                    self.suggestedByLabel.text = "Suggested by: \(tempCurrentSong.suggestedBy)"
                }
                print("\(self.partyMusicHandler.getPlaybackState().rawValue) :: \(MPMusicPlaybackState.stopped.rawValue)")
                if ( self.isHost) {
                    if self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].currentSong.songName != "" {
                        print("play current song from observer")
                        self.playCurrentSong()
                    } else {
                        print("play next song from observer")
                        self.moveToNextSong()
                    }
                }
//                self.hideLoadingAnimation()
                self.isLoading -= 1
            }
        })
        
        self.setPlaylistFBObservers(partyID: partyID)
        
        /*
         SharedJukebauxModel.ref.child("parties").child(partyID).child("playlist").observeSingleEvent(of: .value, with: { (snapshot) in
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
         self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs = playlist
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
        for song in self.SharedJukebauxModel.parties[SharedJukebauxModel.currentPartyIndex].songs {
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
        
        playlistHandleAdd = SharedJukebauxModel.ref.child("parties").child(partyID).child("playlist").observe(DataEventType.childAdded, with: { (snapshot) -> Void in
            if !snapshot.exists() {
                return
            }
//            self.hideEmptyPlaylistButton()
            let currentParty = self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex]
//            self.showLoadingAnimation()
            self.isLoading += 1 // When isLoading == 0 then loading animation is hidden
            // The listener is passed a snapshot containing the new child's data.
            if let childSongSnapshot = snapshot as? DataSnapshot {
                let newSong = Song(dictionary: childSongSnapshot.value as! NSDictionary)
                print("observed add in playlist \(newSong.songName)")
                self.suggestRandomSongsButton.isHidden=true
                self.isEmpty = false
                
                // if is the host, and the current song is done playing, and there is no other songs, put right into current song
                if self.isHost &&
                    ((Float(self.partyMusicHandler.getCurrentPlaybackTime()) >= Float(currentParty.currentSong.songDuration)) || self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].currentSong.songName == "") {
                    print("looks like no current song, so lets set the party song")
                    self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].currentSong = newSong
                    self.SharedJukebauxModel.setPartySong(song: newSong)
                    self.SharedJukebauxModel.removePartySong(song: newSong)
//                    self.hideLoadingAnimation()
                    self.isLoading -= 1
                    return
                }
                
                if !currentParty.songs.contains(where: { $0.songID == newSong.songID}) { // if song isnt already in the playlist
                    if currentParty.songs.isEmpty { //if playlist is empty, insert at 0
                        self.songsTableView.beginUpdates()
                        currentParty.songs.insert(newSong, at: 0)
                        self.songsTableView.insertSections(IndexSet(integer: 0), with: .automatic)
                        self.songsTableView.endUpdates()
                    }
                    else if let index = currentParty.songs.index(where: { // get index where new song should go
                        return $0.upVotes < newSong.upVotes
                    }) {
                        self.songsTableView.beginUpdates()
                        currentParty.songs.insert(newSong, at: index)
                        self.songsTableView.insertSections(IndexSet(integer: index), with: .automatic)
                        self.songsTableView.endUpdates()
//                        self.sortSongs()  // TODO does changing this break things? motivation is that if you are adding a song in the middle of the tableview, all the cellID's are going to be messed up
                    } else { // insert at end of playlist
                        self.songsTableView.beginUpdates()
                        currentParty.songs.append(newSong)
                        self.songsTableView.insertSections(IndexSet(integer: currentParty.songs.count-1), with: .automatic)
                        self.songsTableView.endUpdates()
                    }
                }
//                self.hideLoadingAnimation()
                self.isLoading -= 1
            }
        })
        
        playlistHandleRemove = SharedJukebauxModel.ref.child("parties").child(partyID).child("playlist").observe(DataEventType.childRemoved, with: { (snapshot) -> Void in
            if !snapshot.exists() {
                print("observed removed in playlist, null snapshot")
                return
            }
            // Find which child was removed, and delete that row
            // The snapshot passed to the callback block contains the data for the removed child.
            if let childSongSnapshot = snapshot as? DataSnapshot {
                // print("observed removed in playlist childSongsnapshot: \(snapshot)")
                let childSongID = (childSongSnapshot.value as! NSDictionary)["songID"] as! String
                if let i = self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs.index(where: { $0.songID == childSongID }) {
                    print("observed removed in playlist \(self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs[i].songName) :: \(self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs.count) :: \(i) :: \(self.songsTableView.numberOfSections)")
                    
                    if (self.songsTableView.numberOfSections > 0) {
                        self.songsTableView.beginUpdates()
                        self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs.remove(at: i)
                        self.songsTableView.deleteSections(IndexSet(integer: i), with: UITableViewRowAnimation.top)
                        self.songsTableView.endUpdates()
                    }
                    
                    // self.updateSongCellIds()
                    self.sortSongs()
                    
                    // check if playlist is now empty and then prompt user to add more songs if so
                    if(self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs.isEmpty) {
                        // self.showEmptyPlaylistButton()
                        self.isEmpty = true
                    }
                }
            }
        })
        
        playlistHandleModify = SharedJukebauxModel.ref.child("parties").child(partyID).child("playlist").observe(DataEventType.childChanged, with: { (snapshot) -> Void in
            print("observed change in playlist")
            print(snapshot)
            if !snapshot.exists() {
                return
            }
            // Find which child was changed, and update that row
            // The snapshot passed to the event listener contains the updated data for the child.
            let childSongID = (snapshot.value as! NSDictionary)["songID"] as! String
            // Get changed song index in curent songs array
            if let i = self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs.index(where: { $0.songID == childSongID }) {
                let snapshotDictionary = (snapshot.value as! NSDictionary)
                let newUpVotes = snapshotDictionary["upVotes"] as! Int
                
                print("reloading \(i)")
                
                // Check if was upvote or downvote
                let isUpVote = (self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs[i].upVotes <= newUpVotes)
                
                self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs[i].upVotes = newUpVotes
                self.songsTableView.beginUpdates()
                //self.songsTableView.reloadRows(at: rowsToReload, with: .automatic)
                self.songsTableView.reloadSections(IndexSet(integer: i), with: .automatic)
                self.songsTableView.endUpdates()
                
                // if true, then change is upvote, if false, then downvote
                /* Animate moving song rows */
                if (isUpVote) {
                    self.moveUpVote(rowToMove: i)
                }
                else{
                    self.moveDownVote(rowToMove: i, newUpVotes: newUpVotes)
                }
                
                if snapshotDictionary["upvotedBy"] != nil {
                    self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs[i].upvotedBy=snapshotDictionary["upvotedBy"] as! [String:Int]
                } else {
                    self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs[i].upvotedBy = [:]
                }
                if snapshotDictionary["downvotedBy"] != nil {
                    self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs[i].downvotedBy=snapshotDictionary["downvotedBy"] as! [String:Int]
                } else {
                    self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs[i].downvotedBy = [:]
                }
                
            }
        })
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
           func moveSongFromTo(fromIndex: Int, toIndex: Int) {
               
               // switch songs at the indices
               if ( fromIndex != toIndex ) {
                   self.songsTableView.beginUpdates()
                   self.songsTableView.moveSection(fromIndex, toSection: toIndex)
                   //self.songsTableView.moveRow(at: NSIndexPath(row: fromIndex, section: 0) as IndexPath, to: NSIndexPath(row: toIndex, section: 0) as IndexPath)
                   SharedJukebauxModel.parties[SharedJukebauxModel.currentPartyIndex].songs.rearrange(from: fromIndex, to: toIndex)
                   self.songsTableView.endUpdates()
                   print( "Moved \(fromIndex) to \(toIndex)")
               }
               
               updateSongCellIds()
           }
           /*****************************************************************************/
    
    /****************************************************************************/
    // Upvote rearrangement logic - go to row where row upvotes are less than new song's upvotes, and put it there.
    func moveUpVote(rowToMove: Int) {
        if let toIndex = self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs.index(where: {
            let fromSong = self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs[rowToMove]
            print("upvote: \($0.upVotes) - \(fromSong.upVotes)")
            if ($0.upVotes == fromSong.upVotes && $0.songID == fromSong.songID) { return true }
            return $0.upVotes < fromSong.upVotes
        }) {
            print("From Index: \(rowToMove) - Upvotes: \(self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs[rowToMove].upVotes) : To Index: \(toIndex) - UpVotes\(self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs[toIndex].upVotes)")
            self.moveSongFromTo(fromIndex: rowToMove, toIndex: toIndex)
        }
    }
    /****************************************************************************/
    
    /****************************************************************************/
    func moveDownVote(rowToMove: Int, newUpVotes: Int) {
        print("moveDownVote")
        let songName = self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs[rowToMove].songName
        if ( newUpVotes < 0 && self.isHost) {
            if( isHost ) {
                let appearance = SCLAlertView.SCLAppearance( // Prompt host to remove song as has less than 0 upvotes
                    showCloseButton: false
                )
                let alertView = SCLAlertView(appearance: appearance)
                alertView.addButton("Remove") {
                    print("REMOVE: \(self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs) :: \(rowToMove)")
                    self.SharedJukebauxModel.removePartySong(song: self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs[rowToMove])
                }
                alertView.addButton("Don't remove") {
                    self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs[rowToMove].upVotes = 0
                    self.setSongUpVotesOnFirebase(songName: songName, newUpVotes: 0)
                }
                alertView.showInfo("Remove Song?", subTitle: "\(songName) has less than zero upvotes. Remove from playlist?")
            }
        } else {
        // Downvote rearrangement logic
            for (index, item) in self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs.enumerated().reversed() {
                print( "\(item.songName) \(item.upVotes) \(index)")
            }
            for (index, item) in self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs.enumerated().reversed() {
                if (item.upVotes > newUpVotes && index > rowToMove) {
                    print("move downvote from \(rowToMove)(\(newUpVotes)) to \(index)(\(item.upVotes))")
                    self.moveSongFromTo(fromIndex: rowToMove, toIndex: index)
                } else if (item.songName == songName) {
                    // TODO tbh idk why i have this case but maybe its important
                }
            }
        }
    }
    /****************************************************************************/
    
    /*****************************************************************************/
    func pullSongImages() {
        print("pull song images")
        var counter = 0
        for song in self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs {
            if song.songImage != UIImage(named:"party")!{
                print("VWA NOT null song image\(song.songName)")
                counter = counter + 1
            } else {
                DispatchQueue.global(qos: .userInitiated).async {
                    let url1 = URL(string: song.songImageURL)
                    if (url1 != nil) {
                        if let data = try? Data(contentsOf: url1!)  {
                            song.songImage = UIImage(data: data)!
                            counter = counter + 1
                        }
                    } else {
                        counter = counter + 1
                    }
                }
            }
        }
        
        while ( counter < self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs.count ) {
            print("* \(counter) \(self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].songs.count)")
            sleep(1)
            // Wait for all song images to be loaded
        }
        
        // Hide indicator animation view
//        hideLoadingAnimation()
        self.isLoading -= 1
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func songChanged (notification: Notification) -> Void {
        let currentParty = SharedJukebauxModel.parties[SharedJukebauxModel.currentPartyIndex]
        print("song changed")
        if partyMusicHandler.getPlaybackState() == MPMusicPlaybackState.stopped {
            print("song changed \((notification.userInfo?.first?.value as? Int)!)")
            currentParty.currentSongPersistentIDKey = (notification.userInfo?.first?.value as? Int)!
            if(currentParty.songs.count > 0){
                playNextSong()
            } else {
                //self.showEmptyPlaylistButton()
                isEmpty = true
            }
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    @IBAction func newSuggestSongButtonPressed(_ sender: Any) {
        print(" new suggest song button pressed")
//        emptyPlaylistButtonPressed()
    }
    /*****************************************************************************/
    
    @objc func emptyPlaylistButtonPressed() {
        performSegue(withIdentifier: "suggestSongSegue", sender: self)
    }
    
    @objc func dismissEmptyPlaylistButtonPressed() {
//        self.hideEmptyPlaylistButton()
    }
    
    /*****************************************************************************/
    @objc func chatBarButtonPressed() {
        self.performSegue(withIdentifier: "ChatSegue", sender: self)
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    @IBAction func suggestSongButtonPressed(_ sender: Any) {
        print("suggest song button pressed")
        emptyPlaylistButtonPressed()
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func makeLoadingIndicatorView(tempView: UIView) -> UIView{
        // Set up loading view animation
        let dimension = CGFloat.minimum(tempView.frame.width, tempView.frame.height)
        let tempLoadingIndicatorView = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: dimension, height: dimension), type: NVActivityIndicatorType(rawValue: 31), color: SharedJukebauxModel.mainJukebauxColor )
        tempLoadingIndicatorView.center = tempView.center
        tempLoadingIndicatorView.startAnimating()
        
        let tempOverlay = UIView(frame: CGRect(x: 0, y: 0, width: tempView.frame.width, height: tempView.frame.height))
        tempOverlay.backgroundColor = UIColor.black
        tempOverlay.alpha = 0.5
        
        tempLoadingIndicatorView.addSubview(tempOverlay)
        
        return tempLoadingIndicatorView
        
        
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func setSongUpVotesOnFirebase(songName: String, newUpVotes: Int) {
        let currentParty = SharedJukebauxModel.parties[SharedJukebauxModel.currentPartyIndex]
        // Send change to firebase, change will be handled upon receiving the data changed event from firebase
        let songRef = SharedJukebauxModel.ref.child("parties").child(currentParty.partyID).child("playlist").child(songName)
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
    func updateSongCellIds() {
        // change all cell IDs after the toIndex (increment them all by one
        // Iterate over all the rows of a section
        print("change cell ids")
        // for i in stride(from: toIndex, to: self.songsTableView.numberOfRows(inSection: 0), by: 1) {
        for i in stride(from: 0, to: self.songsTableView.numberOfSections, by: 1) {
            //let cell = self.songsTableView.cellForRow(at: NSIndexPath(row: i, section: 0) as IndexPath) as? SongTableViewCell
            let cell = self.songsTableView.cellForRow(at: NSIndexPath(row: 0, section: i) as IndexPath) as? SongTableViewCell
            cell?.cellId = i
            print(" order: \(SharedJukebauxModel.parties[SharedJukebauxModel.currentPartyIndex].songs[i].songName) - \(i)")
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func printSongCellIds() {
        // Iterate over all the rows of a section
        print("print cell ids")
        // for i in stride(from: toIndex, to: self.songsTableView.numberOfRows(inSection: 0), by: 1) {
        for i in stride(from: 0, to: self.songsTableView.numberOfSections, by: 1) {
            //let cell = self.songsTableView.cellForRow(at: NSIndexPath(row: i, section: 0) as IndexPath) as? SongTableViewCell
            let cell = self.songsTableView.cellForRow(at: NSIndexPath(row: 0, section: i) as IndexPath) as? SongTableViewCell
            print(" order: \(SharedJukebauxModel.parties[SharedJukebauxModel.currentPartyIndex].songs[i].songName) - \(String(describing: cell?.cellId))")
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    func sortSongs() {
        SharedJukebauxModel.parties[SharedJukebauxModel.currentPartyIndex].songs.sort(by: {
            if $0.upVotes == $1.upVotes {
                return $0.addedDate > $1.addedDate
            } else {
                return $0.upVotes > $1.upVotes
            }
        })
        //self.songsTableView.reloadData()
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ChatSegue" {
            if let chatVC = segue.destination as? FirebaseChatViewController {
                let currentParty = SharedJukebauxModel.parties[SharedJukebauxModel.currentPartyIndex]
                chatVC.channelRef = SharedJukebauxModel.ref.child("parties").child(currentParty.partyID)
                print("USERNAME: \(SharedJukebauxModel.myUser.username)")
                chatVC.senderDisplayName = SharedJukebauxModel.myUser.username
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
        // TODO THIS ISNT BEING CALLED, WANT TO STOP HOST FROM LEAVING PARTY AND IF THEY DO, TOTALLY LOG THEM OUT OF PARTY IN A WAY THAT LETS THEM SAFELY REJOIN THE PARTY
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
    /*****************              HOST                       *******************/
    /*****************************************************************************/
    
    /*****************************************************************************/
    @objc func timerFired(_:AnyObject) {
        let currentParty = SharedJukebauxModel.parties[SharedJukebauxModel.currentPartyIndex]
        
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
            //print("timer: \(trackElapsed)")
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
        printSongCellIds()
        if(partyMusicHandler.getPlaybackState() == MPMusicPlaybackState.paused){
            print("play")
//            playPauseButton.titleLabel?.text = "Play"
            playPauseButton.setImage(UIImage(named: "pauseIcon"), for: .normal)
            partyMusicHandler.applicationMusicPlayer.play()
            return
        } else if(partyMusicHandler.getPlaybackState()==MPMusicPlaybackState.playing){
            print("pause")
//            playPauseButton.titleLabel?.text = "Pause"
            playPauseButton.setImage(UIImage(named: "playIcon"), for: .normal)
            partyMusicHandler.applicationMusicPlayer.pause()
            return
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    @objc func endPartyButtonPressed() {
        print("end button pressed")
        let partyID = self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].partyID
        SharedJukebauxModel.ref.child("parties").child(partyID).child("partyEndNotification").setValue(true) { error, arg in
            if error != nil {
                print("error \(String(describing: error?.localizedDescription))")
            } else {
                print("party end notification sent")
            }
        }
    }
    /*****************************************************************************/
    
    /*****************************************************************************/
    override func remoteControlReceived(with event: UIEvent?) {
        guard let event = event else {
            return
        }
        switch event.subtype {
        case .remoteControlPlay:
            print("remote play")
            partyMusicHandler.applicationMusicPlayer.play()
        case .remoteControlPause:
            print("remote pause")
            partyMusicHandler.applicationMusicPlayer.pause()
        case .remoteControlStop:
            partyMusicHandler.applicationMusicPlayer.pause()
        case .remoteControlNextTrack:
            print("skip here 1")
            self.moveToNextSong()
        default:
            print("default action")
        }
    }
    
    func setupNowPlayingInfoCenter() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        self.updateNowPlayingInfoCenter()
        MPRemoteCommandCenter.shared().playCommand.addTarget {event in
            self.partyMusicHandler.applicationMusicPlayer.play()
            self.updateNowPlayingInfoCenter()
            return .success
        }
        MPRemoteCommandCenter.shared().pauseCommand.addTarget {event in
            self.partyMusicHandler.applicationMusicPlayer.pause()
            return .success
        }
        MPRemoteCommandCenter.shared().nextTrackCommand.addTarget {event in
            print("skip here 2")
            self.partyMusicHandler.nextSong()
            return .success
        }
        MPRemoteCommandCenter.shared().previousTrackCommand.addTarget {event in
            self.partyMusicHandler.prevSong()
            return .success
        }
    }
    /*****************************************************************************/

    
    /*****************************************************************************/
    func updateNowPlayingInfoCenter() {
//        guard let file = partyMusicHandler.applicationMusicPlayer.nowPlayingItem else {
//            MPNowPlayingInfoCenter.default().nowPlayingInfo = [String: AnyObject]()
//            return
//        }
//        print("file: \(file.title!), \(file.albumTitle!), \(file.artist!), \(partyMusicHandler.applicationMusicPlayer.nowPlayingItem?.playbackDuration)")
//
//        //        if let imageURL = URL(string: JukebauxModel.shared.parties[JukebauxModel.shared.currentPartyIndex].currentSong.songImageURL) {
//        //            URLSession.shared.dataTask(with: imageURL, completionHandler: { (data, response, error) in
//        //                //ran into some download error
//        //                if error != nil {
//        //                    return
//        //                }
//        //                print("hi")
//        //                MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: UIImage(data: data!)!)
//        //            })
//        //        }
//        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
//            MPMediaItemPropertyTitle: file.title! ,
//            MPMediaItemPropertyAlbumTitle: file.albumTitle! ,
//            MPMediaItemPropertyArtist: file.artist! ,
//            //            MPMediaItemPropertyPlaybackDuration: self.partyMusicHandler.applicationMusicPlayer.nowPlayingItem?.playbackDuration ?? ""
//        ]
//        print("*******: \(MPNowPlayingInfoCenter.default().nowPlayingInfo!)")
    }
    
    @objc func suggestSongs() {
//        self.showLoadingAnimation()
        self.isLoading += 1 // When isLoading == 0 then loading animation is hidden
        self.SharedJukebauxModel.getTopTracks(completion: {
            var i = 0
            for song in self.SharedJukebauxModel.topTracks {
                self.searchSongs(track: song.key, artist: song.value, completionHandler: {_ in
                    i=i+1
                    print(i)
                    if i >= 10 {
                        self.SharedJukebauxModel.updatePartyOnFirebase(party: self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex], completionHandler: {_ in
//                            self.hideLoadingAnimation()
                            self.isLoading -= 1
                            print("got all songs now update firebase")
                        })
                    }
                })
            }
        })
    }
    
    /* For auto suggest top 40 songs */
    typealias CompletionHandler = (_ success:Bool) -> Void
    func searchSongs(track: String, artist:String,  completionHandler: @escaping CompletionHandler) {
        // Show loading screen
        DispatchQueue.global(qos: .background).async {
            var goodTrack = track.replacingOccurrences(of: " ", with: "-")
            goodTrack = goodTrack.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed)!
            var goodArtist = artist.replacingOccurrences(of: " ", with: "-")
            goodArtist = goodArtist.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed)!
            let url = NSURL(string: "https://geo.itunes.apple.com/search?term=\(goodTrack)&media=music")
            let request = NSMutableURLRequest(
                url: url! as URL,
                cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData,
                timeoutInterval: 10)
            request.httpMethod = "GET"
            
            let session = URLSession(
                configuration: URLSessionConfiguration.default,
                delegate: nil,
                delegateQueue: OperationQueue.main
            )
            
            let task: URLSessionDataTask = session.dataTask(with: request as URLRequest,
                                                            completionHandler: { (dataOrNil, response, error) in
                                                                if let data = dataOrNil {
                                                                    if let responseDictionary = try? JSONSerialization.jsonObject(
                                                                        with: data, options:[]) as? NSDictionary {
                                                                        
                                                                        let results = (responseDictionary!["results"] as?[NSDictionary])!
                                                                            if !results.isEmpty {
                                                                                let suggestedSong = results[0] as NSDictionary
                                                                                print("******* adding song \((suggestedSong["trackName"] as? String)!)")
                                                                                self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].addSong(songName: (suggestedSong["trackName"] as? String)!, songArtist : (suggestedSong["artistName"] as? String)!, songID : String((suggestedSong["trackId"] as? Int)!), songImageUrl : (suggestedSong["artworkUrl100"] as? String)!, songDuration: (suggestedSong["trackTimeMillis"] as? Int)!)
                                                                                
                                                                                completionHandler(true)
                                                                            }
                                                                    }
                                                                }
                                                                if error != nil {
//                                                                    self.hideLoadingAnimation()
                                                                    self.isLoading -= 1
                                                                    print("Error \(String(describing: error?.localizedDescription))")
                                                                }
            })
            task.resume()
        }
    }
}

//MARK: - UITableViewDataSource
extension PartyViewController : UITableViewDataSource {
    /*****************************************************************************/
        func numberOfSections(in tableView: UITableView) -> Int {
            return SharedJukebauxModel.parties[SharedJukebauxModel.currentPartyIndex].songs.count
        }
        /*****************************************************************************/
        // Set the spacing between sections
        func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            return 10
        }
        
        // Make the background color show through
        func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
            let headerView = UIView()
            headerView.backgroundColor = UIColor.clear
            return headerView
        }
        /*****************************************************************************/
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return 1
        }
        /*****************************************************************************/
        
        /*****************************************************************************/
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongTableViewCell
            cell.delegate = self
            if indexPath.section < SharedJukebauxModel.parties[SharedJukebauxModel.currentPartyIndex].songs.count {
                let song = SharedJukebauxModel.parties[SharedJukebauxModel.currentPartyIndex].songs[indexPath.section]
                
                cell.upvoteButton.isEnabled = !song.upvotedBy.keys.contains(SharedJukebauxModel.myUser.userID)
                cell.downvoteButton.isEnabled = !song.downvotedBy.keys.contains(SharedJukebauxModel.myUser.userID)
                
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
                    cell.addConstraint(NSLayoutConstraint(item: v, attribute: .height, relatedBy: .equal, toItem: cell.songImage, attribute: .height, multiplier: 1, constant: 0))
                    cell.addConstraint(NSLayoutConstraint(item: v, attribute: .width, relatedBy: .equal, toItem: cell.songImage, attribute: .width, multiplier: 1, constant: 0))
                    v.centerXAnchor.constraint(equalTo: cell.songImage.centerXAnchor).isActive = true
                    v.centerYAnchor.constraint(equalTo: cell.songImage.centerYAnchor).isActive = true
                    
                    //TODO optimize this to not be always loading song images. Dictionary of songID to songImage?
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
                cell.cellId = indexPath.section
                // cell.partyID = self.SharedJukebauxModel.parties[self.SharedJukebauxModel.currentPartyIndex].partyID
                cell.songID = song.songID
                cell.songName.text = song.songName
                print(song.songName)
                cell.songArtist.text = song.songArtist
                cell.upvoteCounter = song.upVotes
                cell.upvoteCount.text = String(cell.upvoteCounter)
                cell.layer.cornerRadius = 20
                cell.layer.masksToBounds = true
                cell.backgroundColor = UIColor.clear
    //            cell.clipsToBounds = true
            }
            return cell
        }
        /*****************************************************************************/
}

//MARK: - SongTableViewCellDelegate
extension PartyViewController : SongTableViewCellDelegate {
    /*****************************************************************************/
        // SongTableViewCell Delegate Function
        func upvoteButtonPressed(cellId: Int, songID: String) {
            let currentParty = SharedJukebauxModel.parties[SharedJukebauxModel.currentPartyIndex]
            
            // Send change to firebase, change will be handled upon receiving the data changed event from firebase
    //        let songName = SharedJukebauxModel.encodeForFirebaseKey(string: (currentParty.songs[cellId].songName))
            let songName = currentParty.songs.first(where: {$0.songID == songID})?.songName
            print("upvote pressed :: \(songName) :: \(cellId)")
            let songRef = SharedJukebauxModel.ref.child("parties").child(currentParty.partyID).child("playlist").child(String(songID))
            
            songRef.child("downvotedBy").observeSingleEvent(of: .value, with: { (snapshot) in
                
                if snapshot.hasChild(self.SharedJukebauxModel.myUser.userID){
                    print("song was downvoted by him, upvote")
                    // then user already dwownvoted this, up vote it first
                    songRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                        if var post = currentData.value as? [String : Any] {
                            // Increment the number joined by 1
                            let upVotes = post["upVotes"] as? Int ?? 0
                            post["upVotes"] = upVotes + 1 as AnyObject?
                            post["downvotedBy"] = nil
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
                    //                songRef.child("downvotedBy").child(self.SharedJukebauxModel.myUser.userID).removeValue { error in
                    //                    if error != nil {
                    //                        print("error \(error)")
                    //                    }
                    //                  }
                } else {
                    songRef.child("upvotedBy").observeSingleEvent(of: .value, with: { (snapshot) in
                        
                        if snapshot.hasChild(self.SharedJukebauxModel.myUser.userID){
                            // then user already upvoted this
                            print("song was already upvoted by him, do nothing")
                        }else{
                            print("song was NOT already upvoted by him, upvote")
                            songRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                                if var post = currentData.value as? [String : Any] {
                                    // Increment the number joined by 1
                                    let upVotes = post["upVotes"] as? Int ?? 0
                                    post["upVotes"] = upVotes + 1 as AnyObject?
                                    if post["upvotedBy"] == nil {
                                        post["upvotedBy"] = [self.SharedJukebauxModel.myUser.userID : 1]
                                    } else {
                                        var dict = post["upvotedBy"] as! Dictionary<String,Int>
                                        dict.updateValue(1, forKey: self.SharedJukebauxModel.myUser.userID)
                                        post["upvotedBy"] = dict
                                    }
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
                    })
                }
            })
        }
        /*****************************************************************************/
    
    /*****************************************************************************/
        // SongTableViewCell Delegate Function
        // If there are less than 0 downvotes, prompt user to remove song from queue
        func downvoteButtonPressed(cellId: Int, songID: String) {
            let currentParty = SharedJukebauxModel.parties[SharedJukebauxModel.currentPartyIndex]
            
            // Send change to firebase, change will be handled upon receiving the data changed event from firebase
            if( cellId < currentParty.songs.count) {
    //            let songName = SharedJukebauxModel.encodeForFirebaseKey(string: (currentParty.songs[cellId].songName))
                let songName = currentParty.songs.first(where: {$0.songID == songID})
                let songRef =  SharedJukebauxModel.ref.child("parties").child(currentParty.partyID).child("playlist").child(String(songID)) // TODO: REFACTOR TO USE SONG ID, SONG NAME NOT UNIQUE
                songRef.child("upvotedBy").observeSingleEvent(of: .value, with: { (snapshot) in
                    
                    if snapshot.hasChild(self.SharedJukebauxModel.myUser.userID){
                        // then user already upvoted this, down vote it first
                        print("then user already upvoted this, down vote it first")
                        songRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                            if var post = currentData.value as? [String : Any] {
                                // Increment the number joined by 1
                                let upVotes = post["upVotes"] as? Int ?? 0
                                post["upVotes"] = upVotes - 1 as AnyObject?
                                post["upvotedBy"] = nil
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
                        //                    songRef.child("upvotedBy").child(self.SharedJukebauxModel.myUser.userID).removeValue { error in
                        //                            if error != nil {
                        //                                print("error \(error)")
                        //                            }
                        //                          }
                    } else {
                        songRef.child("downvotedBy").observeSingleEvent(of: .value, with: { (snapshot) in
                            
                            if snapshot.hasChild(self.SharedJukebauxModel.myUser.userID){
                                // then user already upvoted this
                                print("user has already downvoted, do nothign")
                            }else{
                                print("user has NOT already downvoted, downvote")
                                songRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                                    if var post = currentData.value as? [String : Any] {
                                        let upVotes = post["upVotes"] as? Int ?? 0
                                        post["upVotes"] = upVotes - 1 as AnyObject?
                                        if post["downvotedBy"] == nil {
                                            post["downvotedBy"] = [self.SharedJukebauxModel.myUser.userID : 1]
                                        } else {
                                            var dict = post["downvotedBy"] as! Dictionary<String,Int>
                                            dict.updateValue(1, forKey: self.SharedJukebauxModel.myUser.userID)
                                            post["downvotedBy"] = dict
                                        }
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
                        })
                    }
                })
                
            }
        }
        /*****************************************************************************/
}


//MARK: - InviteDelegate
extension PartyViewController : InviteDelegate {
    func sendInvite() {
         if let invite = Invites.inviteDialog() {
             invite.setInviteDelegate(self)
             
             // NOTE: You must have the App Store ID set in your developer console project
             // in order for invitations to successfully be sent.
             
             // A message hint for the dialog. Note this manifests differently depending on the
             // received invitation type. For example, in an email invite this appears as the subject.
             invite.setMessage("Hey, come join the party!\n -\(SharedJukebauxModel.myUser.username)")
             // Title for the dialog, this is what the user sees before sending the invites.
             invite.setTitle("Control the music with Jukebaux!")
             //invite.setDeepLink(SharedJukebauxModel.parties[SharedJukebauxModel.currentPartyIndex].partyID)
             invite.setCallToActionText("Install!")
             invite.setCustomImage("http://adammoffitt.me/images/jukebauxLogo.png")
             invite.open()
         }
     }
     func inviteFinished(withInvitations invitationIds: [String], error: Error?) {
         if let error = error {
             print("Failed: " + error.localizedDescription)
         } else {
             print("\(invitationIds.count) invites sent")
         }
     }
}


func numberOfCells(_ liquidFloatingActionButton: LiquidFloatingActionButton) -> Int {
    return 3
}

func cellForIndex(_ index: Int) -> LiquidFloatingCell {
    return cells[index]
}

func liquidFloatingActionButton(_ liquidFloatingActionButton: LiquidFloatingActionButton, didSelectItemAtIndex index: Int) {
    print("did Tapped! \(index)")
    liquidFloatingActionButton.close()
    switch index {
    case 0:
        sendInvite()
    case 1:
        let addMusicLibraryViewController = AddMusicLibraryViewController()
        self.navigationController?.pushViewController(addMusicLibraryViewController, animated: true)
    case 2:
        emptyPlaylistButtonPressed()
    default:
        break
    }
    
}
    
//MARK: - EmptyDataSetSource
extension PartyViewController : EmptyDataSetSource {
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
            var text: String?
            var font: UIFont?
            var textColor: UIColor?
            
            text = "Playlist is empty!"
            font = UIFont.init(name: "HelveticaNeue-Light", size: 22)!
            textColor = SharedJukebauxModel.mainJukebauxColor
            
            let attributes = [
                NSAttributedStringKey.font: font!,
                NSAttributedStringKey.foregroundColor: textColor!
                ] as! [NSAttributedStringKey : Any]
            return NSAttributedString.init(string: text!, attributes: attributes)
        }
        
        
        func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
            
            let text = "Queue up some tunes, and keep the party going!"
            let font = UIFont.systemFont(ofSize: 13.0)
            let textColor = UIColor.black
            
            let attributes = [
                NSAttributedStringKey.font: font,
                NSAttributedStringKey.foregroundColor: textColor
                ]as! [NSAttributedStringKey : Any]
            return NSAttributedString.init(string: text, attributes: attributes )
        }
        
        func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
    //        return UIImage.init(named: "Jukebaux! logo clear")
            return nil
        }
        
        func imageAnimation(forEmptyDataSet scrollView: UIScrollView) -> CAAnimation? {
            let animation = CABasicAnimation.init(keyPath: "transform")
            animation.fromValue = NSValue.init(caTransform3D: CATransform3DIdentity)
            animation.toValue = NSValue.init(caTransform3D: CATransform3DMakeRotation(.pi/2, 0.0, 0.0, 1.0))
            animation.duration = 0.25
            animation.isCumulative = true
            animation.repeatCount = MAXFLOAT
            
            return animation;
        }
        
        func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControlState) -> NSAttributedString? {
            var text: String?
            var font: UIFont?
            var textColor: UIColor?
            
            text = "Add Songs";
            font = UIFont.systemFont(ofSize: 16)
            textColor = (state == .normal ? UIColor.black : UIColor.darkGray)
            
            let attributes = [
                NSAttributedStringKey.font: font!,
                NSAttributedStringKey.foregroundColor: textColor!
                ] as [NSAttributedStringKey : Any]
            return NSAttributedString.init(string: text!, attributes: attributes)
        }
        
        func buttonBackgroundImage(forEmptyDataSet scrollView: UIScrollView, for state: UIControlState) -> UIImage? {
            var imageName = "button_background_addSongs"
            
            if state == .normal {
                imageName = imageName + "_highlight"
            }
            if state == .highlighted {
                imageName = imageName + "_normal"
            }
            
            var capInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            var rectInsets = UIEdgeInsets.zero
            
            let image = UIImage.init(named: imageName)
            
            return image?.resizableImage(withCapInsets: capInsets, resizingMode: .stretch).withAlignmentRectInsets(rectInsets)
        }
        
        func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
            return UIColor.lightGray
        }
        
        func spaceHeight(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
            return 5
        }

}

//MARK: - EmptyDataSetDelegate
extension PartyViewController : EmptyDataSetDelegate {
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
    func emptyDataSetShouldAllowTouch(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return false
    }
    
    func emptyDataSetShouldAnimateImageView(_ scrollView: UIScrollView) -> Bool {
        return false
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapView view: UIView) {
        isEmpty = true
        self.emptyPlaylistButtonPressed()
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {
        self.isEmpty = true
        self.emptyPlaylistButtonPressed()
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return -175
    }

}

//MARK: - UIScrollViewDelegate
extension : UIScrollViewDelegate{
    
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

public class CustomCell : LiquidFloatingCell {
    var name: String = "sample"
    
    init(icon: UIImage, name: String) {
        self.name = name
        super.init(icon: icon)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func setupView(_ view: UIView) {
        super.setupView(view)
        let label = UILabel(frame: CGRect(x:5, y:2, width: 40, height: 20))
        label.text = name
        label.textColor = UIColor.white
        label.font = UIFont(name: "Helvetica-Neue", size: 12)
        label.adjustsFontSizeToFitWidth=true
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 5
        label.backgroundColor = UIColor(red: 82 / 255.0, green: 112 / 255.0, blue: 235 / 255.0, alpha: 1.0)
        addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalTo(self).offset(-95)
            make.width.equalTo(90)
            make.top.height.equalTo(self)
        }
        /*self.addConstraints([
         NSLayoutConstraint(item: self, attribute: .left, relatedBy: .equal, toItem: label, attribute: .left, multiplier: 1, constant: 80),
         NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: label, attribute: .width, multiplier: 1, constant:0),
         NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: label, attribute: .height, multiplier: 1, constant:0)]) */
    }
}

/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
public class CustomDrawingActionButton: LiquidFloatingActionButton {
    
    override public func createPlusLayer(_ frame: CGRect) -> CAShapeLayer {
        
        let plusLayer = CAShapeLayer()
        plusLayer.lineCap = kCALineCapRound
        plusLayer.strokeColor = UIColor.white.cgColor
        plusLayer.lineWidth = 3.0
        
        let w = frame.width
        let h = frame.height
        
        let points = [
            (CGPoint(x: w * 0.25, y: h * 0.35), CGPoint(x: w * 0.75, y: h * 0.35)),
            (CGPoint(x: w * 0.25, y: h * 0.5), CGPoint(x: w * 0.75, y: h * 0.5)),
            (CGPoint(x: w * 0.25, y: h * 0.65), CGPoint(x: w * 0.75, y: h * 0.65))
        ]
        
        let path = UIBezierPath()
        for (start, end) in points {
            path.move(to: start)
            path.addLine(to: end)
        }
        
        plusLayer.path = path.cgPath
        
        return plusLayer
    }
}
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
