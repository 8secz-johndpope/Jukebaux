//
//  AddMusicLibraryViewController.swift
//  JamSesh
//
//  Created by Adam Moffitt on 5/24/17.
//  Copyright © 2017 Adam's Apps. All rights reserved.
//

import UIKit
import MediaPlayer
import MobileCoreServices
import NVActivityIndicatorView

class AddMusicLibraryViewController: UIViewController, MPMediaPickerControllerDelegate {

    var mediaPicker: MPMediaPickerController!
    let SharedJamSeshModel = JamSeshModel.shared
    var loadingIndicatorView : NVActivityIndicatorView!
    var overlay : UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mediaPicker = MPMediaPickerController.self(mediaTypes:MPMediaType.music)
        mediaPicker.allowsPickingMultipleItems = true
        mediaPicker.prompt = "Choose some songs to suggest!"
        mediaPicker.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        self.present(mediaPicker, animated: true, completion: nil)
       
        // Start loading view animation
        loadingIndicatorView = NVActivityIndicatorView(frame: CGRect(x:0,y:0,width:100,height:100), type: NVActivityIndicatorType(rawValue: 31), color: UIColor.purple )
        loadingIndicatorView.center = self.view.center
        
        overlay = UIView(frame: view.frame)
        overlay!.backgroundColor = UIColor.black
        overlay!.alpha = 0.7
        
        self.view.addSubview(overlay!)
        self.view.addSubview(loadingIndicatorView!)
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController){
        self.present(mediaPicker, animated: true, completion: nil)
    }
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        self.dismiss(animated: true, completion: nil)
        let selectedSongs = mediaItemCollection
        
        var tempSongs : [String] = []
        var tempString = ""
        for element in selectedSongs.items {
            //this is only available in 10.3
            if #available(iOS 10.3, *) {
                tempSongs.append(String(element.playbackStoreID))
                tempString += "\(String(describing: element.title!))\n"
            } else {
                // Fallback on earlier versions
            }
            
        }
        let alert = UIAlertController(title: "Suggest Songs?",
                                      message: "\(tempString)",
            preferredStyle: .alert)
        let addAction = UIAlertAction(title: "Add to Queue", style: .default)  { _ in
           
            // Show loading screen
            self.loadingIndicatorView.isHidden = false
            self.loadingIndicatorView.startAnimating()
            
            var i = 0
            for element in selectedSongs.items {
                if #available(iOS 10.3, *) {
                    print(element.title)
                        if let name = element.title,
                            let artist = element.artist,
                            let storeID = Int(element.playbackStoreID),
                            let artwork = element.artwork,
                            let image = artwork.image(at: CGSize(width: artwork.bounds.width, height: artwork.bounds.height)) {
                                let songDuration = element.playbackDuration
                            self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].getTrackImageURLandThenAddSong(songName: name, songArtist : artist, songID : storeID, songImage: image, songDuration: Int(songDuration*1000), completionHandler: {_ in
                                    i+=1
                                    print("added: \(name) : \(i)/\(selectedSongs.count)")
                                    // If all the songs have been added
                                    let minimumDoneSongs = Int(Double(selectedSongs.count) * 0.9)
                                    if ( i >= minimumDoneSongs ) { // At least 90% of songs have been created and added to queue (TODO solve problem well some songs cant be added. For now, 90% is good enough)
                                        print("All songs have been created and added to queue")
                                        self.SharedJamSeshModel.updatePartyOnFirebase(party: self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex], completionHandler: {_ in
                                            
                                            self.loadingIndicatorView.stopAnimating()
                                            self.loadingIndicatorView.isHidden = true
                                            self.overlay?.isHidden = true
                                            self.view.willRemoveSubview(self.overlay!)
                                        })
                                        self.navigationController?.popViewController(animated: true)
                                    }
                            })
                        } else {
                            print("item failed to load") // Element didnt have all fields hmmm
                            i+=1
                    }
                } else {
                    // Fallback on earlier versions TODO ????
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Nevermind", style: .default)
        
        alert.addAction(cancelAction)
        alert.addAction(addAction)
        
        
        present(alert, animated: true, completion: nil)
        
    }
    
    // MPMediaPickerController Delegate methods
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        self.dismiss(animated: true, completion: nil)
        self.navigationController?.popViewController(animated: true)

    }
}
