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
import EmptyDataSet_Swift

class AddMusicLibraryViewController: UIViewController, MPMediaPickerControllerDelegate, EmptyDataSetSource, EmptyDataSetDelegate {

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
        self.present(mediaPicker, animated: true, completion: nil)
//        self.view.emptyDataSetSource = self
//        self.view.emptyDataSetDelegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        // Start loading view animation
        loadingIndicatorView = NVActivityIndicatorView(frame: CGRect(x:0,y:0,width:100,height:100), type: NVActivityIndicatorType(rawValue: 31), color: SharedJamSeshModel.mainJamSeshColor )
        loadingIndicatorView.center = self.view.center
        
        overlay = UIView(frame: view.frame)
        overlay!.backgroundColor = UIColor.black
        overlay!.alpha = 0.7
        
        self.view.addSubview(overlay!)
        self.view.addSubview(loadingIndicatorView!)
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController){
        //self.present(mediaPicker, animated: true, completion: nil)
    }
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        print("picked")
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
            
            var i = 0 // TODO this all breaks for very large playlists
            for element in selectedSongs.items {
                if #available(iOS 10.3, *) {
                    print(element)
                        if let name = element.title,
                            let artist = element.artist,
                            let storeID = Int(element.playbackStoreID),
                            let artwork = element.artwork,
                            let image = artwork.image(at: CGSize(width: artwork.bounds.width, height: artwork.bounds.height)) {
                            
                            // if storeID is 0 then song wasnt found on itunes. Need to search the song with itunes api using song title and artist and then get storeID to add song
                            if storeID == 0 {
                            self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].searchTrackAndGetTrackImageURLandThenAddSong(songName: name, songArtist : artist, songImage: image, completionHandler: {_ in
                                    i+=1
                                    print("added: \(name) : \(i)/\(selectedSongs.count)")
                                    // If all the songs have been added
                                    let minimumDoneSongs = Int(Double(selectedSongs.count) * 1)
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
                            } else { // storeID was found in MPMediaItemElement and not 0
                               let songDuration = element.playbackDuration
                                self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].getTrackImageURLandThenAddSong(songName: name, songArtist : artist, songID : storeID, songImage: image, songDuration: Int(songDuration*1000), completionHandler: {_ in
                                        i+=1
                                        print("added: \(name) : \(i)/\(selectedSongs.count)")
                                        // If all the songs have been added
                                        let minimumDoneSongs = Int(Double(selectedSongs.count) * 1)
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
                            }
                        }else {
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
        print("cancel")
        self.navigationController?.popViewController(animated: true)

    }
    
    //MARK: - DZNEmptyDataSetSource
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        text = "Add Music from iTunes Library"
        font = UIFont.init(name: "HelveticaNeue-Light", size: 22)!
        textColor = UIColor.lightGray
        
        let attributes = [
            NSAttributedStringKey.font.rawValue: font!,
            NSAttributedStringKey.foregroundColor: textColor!
            ] as! [NSAttributedStringKey : Any]
        return NSAttributedString.init(string: text!, attributes: attributes)
    }
    
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        text = "Queue up some tunes, and keep the party going!"
        font = UIFont.systemFont(ofSize: 13.0)
        textColor = UIColor.black
        
        let attributes = [
            NSAttributedStringKey.font.rawValue: font!,
            NSAttributedStringKey.foregroundColor: textColor!
            ] as! [NSAttributedStringKey : Any]
        return NSAttributedString.init(string: text!, attributes: attributes)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return UIImage.init(named: "Jukebaux! logo clear")
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
            NSAttributedStringKey.font.rawValue: font!,
            NSAttributedStringKey.foregroundColor: textColor!
            ] as! [NSAttributedStringKey : Any]
        return NSAttributedString.init(string: text!, attributes: attributes)
    }
    
    func buttonBackgroundImage(forEmptyDataSet scrollView: UIScrollView, for state: UIControlState) -> UIImage? {
        var imageName = "button_background_addSongs"
        
        if state == .normal {
            imageName = imageName + "_normal"
        }
        if state == .highlighted {
            imageName = imageName + "_highlight"
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
        return 0.0
    }
    
    //MARK: - DZNEmptyDataSetDelegate Methods
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
    func emptyDataSetShouldAllowTouch(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
    func emptyDataSetShouldAnimateImageView(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapView view: UIView) {
        print("view not button tapped")
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {
        self.present(mediaPicker, animated: true, completion: nil)
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return 0
    }
}
