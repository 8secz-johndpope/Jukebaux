//
//  AddSongViewController.swift
//  TroJams
//
//  Created by Adam Moffitt on 2/3/17.
//  Copyright © 2017 Adam's Apps. All rights reserved.
//

import UIKit
import MediaPlayer
class AddSongViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITabBarDelegate{
    
    
    @IBOutlet var librarySelectionTabBar: UITabBar!
    @IBOutlet var searchSongTextField: UITextField!
    
    @IBOutlet var suggestedSongsTableView: UITableView!
    
    let SharedTrojamsModel = TroJamsModel.shared
    var results: [NSDictionary] = []
    var searchTerm : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        suggestedSongsTableView.delegate = self
        suggestedSongsTableView.dataSource = self
        librarySelectionTabBar.selectedItem = librarySelectionTabBar.items?[0]
        librarySelectionTabBar.delegate = self
    }
    
    
    @IBAction func searchSongButton(_ sender: Any) {
        if(searchTerm != self.searchSongTextField.text){
            searchSongs(completionHandler: {_ in
                print("completion handler 1")
                self.suggestedSongsTableView.reloadData()
                print("completion handler 2")
            })
            self.suggestedSongsTableView.reloadData()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(librarySelectionTabBar.selectedItem?.tag == 1) {
            print("* number of rows for apple music")
            if(results.count < 1){
                return 0
            }
            else {
                return results.count
            }
        }else {
            print("* number of rows for music library")
            let songsQuery = MPMediaQuery.songs()
            print(1)
            print(songsQuery)
            do {
                 let librarySongs = try songsQuery.items
                    print(librarySongs)
                    print(2)
                    if(librarySongs != nil){
                        print(3)
                        return (librarySongs!.count)
                    } else {
                        print("library songs is null, return 0")
                        return 0}
            } catch {
                print ("caught error")
                return 0
            }
        }
    }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            
            print("loading table view data cell for row at indexpath")
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestedSongCell", for: indexPath) as! SuggestedSongTableViewCell
            
            //if apple music is selected
            if librarySelectionTabBar.selectedItem?.tag == 1{
                print("$ apple music selected")
                let suggestedSong = results[indexPath.row] as NSDictionary
                cell.suggestedSongName.text = suggestedSong["trackName"] as? String
                print(suggestedSong["trackName"]! as! String)
                cell.suggestedSongArtist.text = suggestedSong["artistName"] as? String
                print(suggestedSong["artistName"]! as! String)
                
                
                if let data = try? Data(contentsOf: URL(string: suggestedSong["artworkUrl60"] as! String)!)  {//make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                    print("loading image for suggested song cell")
                    cell.suggestedSongImageView.image = UIImage(data: data)!
                    
                }
                
                //
                //        DispatchQueue.global().async {
                //            if let data = try? Data(contentsOf: URL(string: suggestedSong["artworkUrl60"] as! String)!)  {//make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                //                DispatchQueue.main.async {
                //                    print("loading image for suggested song cell")
                //                    cell.suggestedSongImageView.image = UIImage(data: data)!
                //                    self.suggestedSongsTableView.reloadData()
                //                }
                //            }
                //
                
            }
                //if music library is selected.
            else {
                print("$ music library selected")
                do{
                    print("A")
                let songsQuery = MPMediaQuery.songs()
                    print("B")
                let librarySongs = try songsQuery.items
                print("C")
                 if(librarySongs != nil){
                    print("D")
                    let suggestedSong = (librarySongs?[indexPath.row])!
                    print("E")
                    cell.suggestedSongName.text = suggestedSong.title
                    print(suggestedSong.title ?? "title")
                    cell.suggestedSongArtist.text = suggestedSong.artist
                    print(suggestedSong.artist ?? "artist")
                    cell.suggestedSongImageView.image = suggestedSong.artwork?.image(at: CGSize(width: 30, height: 30))
                    }
                 else {}
                }catch {}
                
            }
            return cell
        }
        
        typealias CompletionHandler = (_ success:Bool) -> Void
        
        func searchSongs(completionHandler: @escaping CompletionHandler) {
            
            DispatchQueue.global(qos: .background).async {
                
                let term = self.searchSongTextField.text
                print(term!)
                let url = NSURL(string: "https://itunes.apple.com/search?term=\(term!)&media=music")
                print(url)
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
                                                                        
                                                                        print("-------------------------------------------------------------------------------------------")
                                                                        //print(self.results)
                                                                        print("-------------------------------------------------------------------------------------------")
                                                                        //self.suggestedSongsTableView.reloadData()
                                                                        print("still not reloading?")
                                                                    }
                });
                //self.suggestedSongsTableView.reloadData()
                task.resume()
                completionHandler(true)
            }
        }
        
        
        
        /*
         // MARK: - Navigation
         
         // In a storyboard-based application, you will often want to do a little preparation before navigation
         override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destinationViewController.
         // Pass the selected object to the new view controller.
         }
         */
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            
            let suggestedSong = results[indexPath.row] as NSDictionary
            
            let alert = UIAlertController(title: "Suggest \(suggestedSong["trackName"]! as! String)?",
                message: "by \(suggestedSong["artistName"]! as! String)?",
                preferredStyle: .alert)
            
            let addAction = UIAlertAction(title: "Add to Queue", style: .default)  { _ in
                self.SharedTrojamsModel.parties[self.SharedTrojamsModel.currentPartyIndex].songs.append(Song(songName: (suggestedSong["trackName"] as? String)!, songArtist : (suggestedSong["artistName"] as? String)!, songID : (suggestedSong["trackId"] as? Int)!, songImageUrl : (suggestedSong["artworkUrl60"] as? String)!))
                self.navigationController?.popViewController(animated: true)
            }
            
            let cancelAction = UIAlertAction(title: "Nevermind", style: .default)
            
            alert.addAction(cancelAction)
            alert.addAction(addAction)
            
            
            present(alert, animated: true, completion: nil)
        }
        
        func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
            print("changed library selection")
            self.suggestedSongsTableView.reloadData()
        }
        
}

