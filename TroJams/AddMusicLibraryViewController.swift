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

class AddMusicLibraryViewController: UIViewController, MPMediaPickerControllerDelegate {

    var mediaPicker: MPMediaPickerController!
    let SharedJamSeshModel = JamSeshModel.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mediaPicker = MPMediaPickerController.self(mediaTypes:MPMediaType.music)
        mediaPicker.allowsPickingMultipleItems = true
        mediaPicker.prompt = "Choose some songs to suggest!"
        mediaPicker.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        self.present(mediaPicker, animated: true, completion: nil)
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
            //this is only available in 10.3 or something
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
            var i = 1
            for element in selectedSongs.items {
                if #available(iOS 10.3, *) {
                    if let name = element.title,
                        let artist = element.artist,
                        let storeID = Int(element.playbackStoreID),
                        
                        let artwork = element.artwork,
                        let image = artwork.image(at: CGSize(width: artwork.bounds.width, height: artwork.bounds.height)) {
                        let songDuration = element.playbackDuration
                        
                        
                        self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].getTrackImageURLandThenAddSong(songName: name, songArtist : artist, songID : storeID, songImage: image, songDuration: Int(songDuration*1000), completionHandler: {_ in
                            
                            //if all the songs have been added
                            if(i == selectedSongs.count){
                                self.SharedJamSeshModel.updateParty(party: self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex], completionHandler: {_ in })
                                self.navigationController?.popViewController(animated: true)
                            } else {
                                i += 1
                            }
                        })
                    }
                } else {
                    // Fallback on earlier versions
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
