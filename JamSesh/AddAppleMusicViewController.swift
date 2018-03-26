//
//  AddSongViewController.swift
//  JamSesh
//
//  Created by Adam Moffitt on 2/3/17.
//  Copyright © 2017 Adam's Apps. All rights reserved.
//

import UIKit
import MediaPlayer
import MobileCoreServices
import NVActivityIndicatorView
import EmptyDataSet_Swift

class AddAppleMusicViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, EmptyDataSetSource, EmptyDataSetDelegate {
    
    @IBAction func keyboardDismissButton(_ sender: Any) {
        self.view.endEditing(true)
        searchSongTextField.resignFirstResponder()
    }

    @IBOutlet var searchButton: UIButton!
    @IBOutlet var searchView: UIView!
    @IBOutlet var searchSongTextField: UITextField!
    
    @IBOutlet var suggestedSongsTableView: UITableView!
    
    let SharedJamSeshModel = JamSeshModel.shared
    var results: [NSDictionary] = []
    var searchTerm : String = ""
    var loadingIndicatorView : NVActivityIndicatorView!
    var overlay : UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        searchButton.layer.cornerRadius = 10
        suggestedSongsTableView.delegate = self
        suggestedSongsTableView.dataSource = self
        suggestedSongsTableView.emptyDataSetSource = self
        suggestedSongsTableView.emptyDataSetDelegate = self
        suggestedSongsTableView.reloadEmptyDataSet()
        self.suggestedSongsTableView.tableFooterView = UIView()
        // Start loading view animation
        let frame = CGRect(x: suggestedSongsTableView.frame.minX, y: suggestedSongsTableView.frame.minY, width: self.view.frame.width, height: self.view.frame.height-self.searchView.frame.height)
            
        loadingIndicatorView = NVActivityIndicatorView(frame: frame, type: NVActivityIndicatorType(rawValue: 31), color: UIColor.purple )
        
//        overlay = UIView(frame: frame)
//        overlay.backgroundColor = UIColor.black
//        overlay.alpha = 0.7
        
        //loadingIndicatorView.addSubview(overlay)
//        self.overlay.isHidden = false
        self.loadingIndicatorView.isHidden = true
        self.view.addSubview(loadingIndicatorView)
        
    
    }
    @IBAction func searchSongButton(_ sender: Any) {
        if(self.searchSongTextField.text != "") {
            if(searchTerm != self.searchSongTextField.text){
                self.searchSongTextField.resignFirstResponder()
                searchTerm = self.searchSongTextField.text!
                searchSongs(string: self.searchSongTextField.text!, completionHandler: {_ in
                    DispatchQueue.main.async {
                        self.suggestedSongsTableView.reloadData()
                    }
                })
            }
        }
    }
    
    func validSearchCheck() {
        if(self.searchSongTextField.text != "") {
            if(searchTerm != self.searchSongTextField.text){
                self.searchSongTextField.resignFirstResponder()
                searchTerm = self.searchSongTextField.text!
                searchSongs(string: self.searchSongTextField.text!, completionHandler: {_ in
                    DispatchQueue.main.async {
                        self.suggestedSongsTableView.reloadData()
                    }
                })
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            if(results.count < 1){
                return 0
            }
            else {
                return results.count
            }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestedSongCell", for: indexPath) as! SuggestedSongTableViewCell
            print(1)
            let suggestedSong = results[indexPath.row] as NSDictionary
            print(2)
            cell.suggestedSongName.text = suggestedSong["trackName"] as? String
        print(3)
            cell.suggestedSongArtist.text = suggestedSong["artistName"] as? String
        print(4)
            
            
            if let data = try? Data(contentsOf: URL(string: suggestedSong["artworkUrl60"] as! String)!)  {
                print(5)
                cell.suggestedSongImageView.image = UIImage(data: data)!
                print(6)
            }
        return cell
    }
    
    typealias CompletionHandler = (_ success:Bool) -> Void
    
    func searchSongs(string: String, completionHandler: @escaping CompletionHandler) {
        // Show loading screen
        showLoadingAnimation()
        DispatchQueue.global(qos: .background).async {
            var term = string.replacingOccurrences(of: " ", with: "-")
            term = term.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed)!
            let url = NSURL(string: "https://geo.itunes.apple.com/search?term=\(term)&media=music")
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
                                                                    if let responseDictionary = try! JSONSerialization.jsonObject(
                                                                        with: data, options:[]) as? NSDictionary {
                                                                        
                                                                        self.results = (responseDictionary["results"] as?[NSDictionary])!
                                                                    }
                                                                    DispatchQueue.main.async {
                                                                        self.suggestedSongsTableView.reloadData()
                                                                        self.hideLoadingAnimation()
                                                                    }
                                                                }
                                                                if error != nil {
                                                                    self.hideLoadingAnimation()
                                                                    print("Error \(error?.localizedDescription)")
                                                                }
            })
            task.resume()
            completionHandler(true)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let suggestedSong = results[indexPath.row] as NSDictionary
        
        let alert = UIAlertController(title: "Suggest \(suggestedSong["trackName"]! as! String)?",
            message: "by \(suggestedSong["artistName"]! as! String)?",
            preferredStyle: .alert)
        
        let addAction = UIAlertAction(title: "Add to Queue", style: .default)  { _ in
            self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex].addSong(songName: (suggestedSong["trackName"] as? String)!, songArtist : (suggestedSong["artistName"] as? String)!, songID : (suggestedSong["trackId"] as? Int)!, songImageUrl : (suggestedSong["artworkUrl100"] as? String)!, songDuration: (suggestedSong["trackTimeMillis"] as? Int)!)
            self.SharedJamSeshModel.updatePartyOnFirebase(party: self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex], completionHandler: {_ in
                //TODO need a completion handler here?
            })
            self.navigationController?.popViewController(animated: true)
        }
        
        let cancelAction = UIAlertAction(title: "Nevermind", style: .default)
        
        alert.addAction(cancelAction)
        alert.addAction(addAction)
        
        
        present(alert, animated: true, completion: nil)
    }
    
    func hideLoadingAnimation() {
        self.loadingIndicatorView.stopAnimating()
        self.loadingIndicatorView.isHidden = true
    }
    
    func showLoadingAnimation() {
        self.loadingIndicatorView.startAnimating()
        self.loadingIndicatorView.isHidden = false
    }
    
    //MARK: - DZNEmptyDataSetSource
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let text = "Hey Mr. DJ,"
        let font = UIFont.systemFont(ofSize: 22)
        let textColor = UIColor.lightGray
        let a = NSAttributedStringKey.font
        let b = NSAttributedStringKey.foregroundColor
        guard let attributes = [
            a: font,
            b: textColor
            ] as? [NSAttributedStringKey : Any] else {
                return NSAttributedString.init()
        }
        return NSAttributedString.init(string: text, attributes: attributes)
    }
    
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
       let  text = "Type the name of the song you want to add and hit search!"
        let font = UIFont.systemFont(ofSize: 13.0)
       let  textColor = UIColor.black
        
        guard let attributes = [
            NSAttributedStringKey.font: font,
            NSAttributedStringKey.foregroundColor: textColor,
            ] as? [NSAttributedStringKey : Any] else {
                return NSAttributedString.init()
        }
        return NSAttributedString.init(string: text, attributes: attributes)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return UIImage.init(named: "music-player")
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
        
        let text = "Search Songs";
        let font = UIFont.systemFont(ofSize: 16)
        let textColor = (state == .normal ? UIColor.black : UIColor.darkGray)
        
        guard let attributes = [
            NSAttributedStringKey.font: font,
            NSAttributedStringKey.foregroundColor: textColor
            ] as? [NSAttributedStringKey : Any] else {
                return NSAttributedString.init()
        }
        return NSAttributedString.init(string: text, attributes: attributes)
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
        return false
    }
    
    func emptyDataSetShouldAnimateImageView(_ scrollView: UIScrollView) -> Bool {
        return false
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapView view: UIView) {
        self.validSearchCheck();
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {
            self.validSearchCheck()
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return -300
    }
}

