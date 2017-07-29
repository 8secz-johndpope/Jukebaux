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

class AddAppleMusicViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBAction func keyboardDismissButton(_ sender: Any) {
        self.view.endEditing(true)
        searchSongTextField.resignFirstResponder()
    }

    @IBOutlet var searchSongTextField: UITextField!
    
    @IBOutlet var suggestedSongsTableView: UITableView!
    
    let SharedJamSeshModel = JamSeshModel.shared
    var results: [NSDictionary] = []
    var searchTerm : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        suggestedSongsTableView.delegate = self
        suggestedSongsTableView.dataSource = self
        searchSongTextField.becomeFirstResponder()
        }
    
    
    @IBAction func searchSongButton(_ sender: Any) {
        if(self.searchSongTextField.text != "") {
            if(searchTerm != self.searchSongTextField.text){
                self.searchSongTextField.resignFirstResponder()
                searchTerm = self.searchSongTextField.text!
                searchSongs(string: self.searchSongTextField.text!, completionHandler: {_ in
                    self.suggestedSongsTableView.reloadData()
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
    
            let suggestedSong = results[indexPath.row] as NSDictionary
            cell.suggestedSongName.text = suggestedSong["trackName"] as? String
            cell.suggestedSongArtist.text = suggestedSong["artistName"] as? String
            
            
            if let data = try? Data(contentsOf: URL(string: suggestedSong["artworkUrl60"] as! String)!)  {
                cell.suggestedSongImageView.image = UIImage(data: data)!
            }
        return cell
    }
    
    typealias CompletionHandler = (_ success:Bool) -> Void
    
    func searchSongs(string: String, completionHandler: @escaping CompletionHandler) {
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
                                                                        
                                                                        self.results = (responseDictionary["results"] as?[NSDictionary])!                          }
                                                                    self.suggestedSongsTableView.reloadData()
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
            self.SharedJamSeshModel.updateParty(party: self.SharedJamSeshModel.parties[self.SharedJamSeshModel.currentPartyIndex], completionHandler: {_ in
                //TODO need a completion handler here?
            })
            self.navigationController?.popViewController(animated: true)
        }
        
        let cancelAction = UIAlertAction(title: "Nevermind", style: .default)
        
        alert.addAction(cancelAction)
        alert.addAction(addAction)
        
        
        present(alert, animated: true, completion: nil)
    }
}

