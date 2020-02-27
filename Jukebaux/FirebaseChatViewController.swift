///*
// * Copyright (c) 2015 Razeware LLC
// *
// * Permission is hereby granted, free of charge, to any person obtaining a copy
// * of this software and associated documentation files (the "Software"), to deal
// * in the Software without restriction, including without limitation the rights
// * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// * copies of the Software, and to permit persons to whom the Software is
// * furnished to do so, subject to the following conditions:
// *
// * The above copyright notice and this permission notice shall be included in
// * all copies or substantial portions of the Software.
// *
// * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// * THE SOFTWARE.
// */
//
//import UIKit
//import Photos
//import Firebase
//import JSQMessagesViewController
//import FLAnimatedImage
//import SCLAlertView
//
//final class FirebaseChatViewController: JSQMessagesViewController, AMGifPickerDelegate, AMGifViewModelDelegate, UISearchBarDelegate  {
//    
//    
//    // MARK: Properties
//    private let imageURLNotSetKey = "NOTSET"
//    private let gifURLNotSetKey = "GIFNOTSET"
//    
//    var channelRef: DatabaseReference?
//    //let g = Giphy(apiKey: Giphy.PublicBetaAPIKey)
//    private lazy var messageRef: DatabaseReference = self.channelRef!.child("messages")
//    fileprivate lazy var storageRef: StorageReference = Storage.storage().reference()
//    private lazy var userIsTypingRef: DatabaseReference = self.channelRef!.child("typingIndicator").child(self.senderId)
//    private lazy var usersTypingQuery: DatabaseQuery = self.channelRef!.child("typingIndicator").queryOrderedByValue().queryEqual(toValue: true)
//    
//    private var newMessageRefHandle: DatabaseHandle?
//    private var updatedMessageRefHandle: DatabaseHandle?
//    
//    private var messages: [JSQMessage] = []
//    private var photoMessageMap = [String: JSQPhotoMediaItem]()
//    
//    private var localTyping = false
//    
//    var isTyping: Bool {
//        get {
//            return localTyping
//        }
//        set {
//            localTyping = newValue
//            userIsTypingRef.setValue(newValue)
//        }
//    }
//    
//    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
//    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
//    
//    func gifPicker(_ picker: AMGifPicker, didSelected gif: AMGif) {
//        let newGif = gif.translate(preferred: .low)
//        print(newGif.gifUrl)
//        gifModel = AMGifViewModel.init(newGif)
//        gifModel?.delegate = self
//        gifModel?.fetchData()
//        
//        gifHeightConstr.constant = newGif.size.height
//        gifWidthConstr.constant = newGif.size.width
//        
//        prepareGIFForSend(gifURL: newGif.gifUrl, gifKey: newGif.key)
//    }
//    var gifView: AMGifPicker!
//    var gifHeightConstr: NSLayoutConstraint!
//    var gifWidthConstr: NSLayoutConstraint!
//    var imageView = FLAnimatedImageView()
//    var gifModel: AMGifViewModel?
//    var heightConstr: NSLayoutConstraint!
//    var widthConstr: NSLayoutConstraint!
//    var searchField: UITextField!
//    var searchBar : UISearchBar!
//    // MARK: View Lifecycle
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        let configuration = AMGifPickerConfiguration(apiKey: "64RLJtsFr7zEXrFbzsAetbduFJU3qpF6", direction: .horizontal)
//        print(configuration)
//        
//        gifView = AMGifPicker(configuration: configuration)
//        //self.inputToolbar.addGIFtoToolbar()
//        view.addSubview(gifView)
//        gifView.translatesAutoresizingMaskIntoConstraints = false
//        
//        gifView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
//        gifView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
//        gifView.bottomAnchor.constraint(equalTo: self.inputToolbar.topAnchor).isActive = true
//        gifView.heightAnchor.constraint(equalToConstant: 75).isActive = true
//        
//        gifHeightConstr = imageView.heightAnchor.constraint(equalToConstant: 200)
//        gifWidthConstr = imageView.widthAnchor.constraint(equalToConstant: 200)
//        gifHeightConstr.isActive = true
//        gifWidthConstr.isActive = true
//        
//        let yPos = ((view.frame.height-self.inputToolbar.frame.height)-75)-30
//        searchBar = UISearchBar(frame: CGRect(x: 0, y: yPos, width: view.frame.width, height: 30))
//        searchBar.placeholder = "Search GIFs"
//        searchBar.showsSearchResultsButton = true
//        searchBar.showsCancelButton = true
//        searchBar.searchBarStyle = UISearchBarStyle.default
//        searchBar.delegate = self
//        searchBar.clipsToBounds = true
//        searchBar.layer.cornerRadius = 10
//        view.addSubview(searchBar)
//        searchBar.translatesAutoresizingMaskIntoConstraints = false
//        searchBar.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
//        searchBar.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
//        searchBar.bottomAnchor.constraint(equalTo: self.gifView.topAnchor).isActive = true
//        searchBar.heightAnchor.constraint(equalToConstant: 30).isActive = true
//
//        gifView.delegate = self
//        
//        self.senderId = Auth.auth().currentUser?.uid
//        observeMessages()
//        
//        // No avatars
//        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
//        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
//    }
//    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        observeTyping()
//    }
//    
//    deinit {
//        if let refHandle = newMessageRefHandle {
//            messageRef.removeObserver(withHandle: refHandle)
//        }
//        if let refHandle = updatedMessageRefHandle {
//            messageRef.removeObserver(withHandle: refHandle)
//        }
//    }
//    
//    // MARK: Collection view data source (and related) methods
//    
//    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
//        return messages[indexPath.item]
//    }
//    
//    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return messages.count
//    }
//    
//    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
//        let message = messages[indexPath.item] // 1
//        print("1: \(indexPath.row): \(message.media)")
//        if message.senderId == senderId { // 2
//            return outgoingBubbleImageView
//        } else { // 3
//            return incomingBubbleImageView
//        }
//    }
//    
//    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
//        let red:CGFloat = CGFloat(drand48())
//        let green:CGFloat = CGFloat(drand48())
//        let blue:CGFloat = CGFloat(drand48())
//        cell.backgroundColor = UIColor(red:red, green: green, blue: blue, alpha: 1.0)
//        let message = messages[indexPath.item]
//        print("2: \(indexPath.row): \(message.media)")
//        //let view = UIView(frame: x:0,y:0,)
//        //cell.setMediaView(UIImageView(image: (message.media as! JSQPhotoMediaItem).image))
//       if message.senderId == senderId { // 1
//            cell.textView?.textColor = UIColor.white // 2
//        } else {
//            cell.textView?.textColor = UIColor.black // 3
//        }
//        
//        return cell
//    }
//    
//    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
//        return nil
//    }
//    
//    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
//        return 15
//    }
//    
//    override func collectionView(_ collectionView: JSQMessagesCollectionView?, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString? {
//        let message = messages[indexPath.item]
//        switch message.senderId {
//        case senderId:
//            return nil
//        default:
//            guard let senderDisplayName = message.senderDisplayName else {
//                assertionFailure()
//                return nil
//            }
//            return NSAttributedString(string: senderDisplayName)
//        }
//    }
//    
//    // MARK: Firebase related methods
//    
//    private func observeMessages() {
//        if let messageRef = channelRef?.child("messages") {
//            let messageQuery = messageRef.queryLimited(toLast:25)
//            
//            // We can use the observe method to listen for new
//            // messages being written to the Firebase DB
//            newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
//                print("child added")
//                let messageData = snapshot.value as! Dictionary<String, String>
//                
//                if let id = messageData["senderId"] as String!, let name = messageData["senderName"] as String!, let text = messageData["text"] as String!, text.characters.count > 0 {
//                    self.addMessage(withId: id, name: name, text: text)
//                    self.finishReceivingMessage()
//                } else if let id = messageData["senderId"] as String!, let photoURL = messageData["photoURL"] as String! {
//                    if let mediaItem = JSQPhotoMediaItem(maskAsOutgoing: id == self.senderId) {
//                        self.addPhotoMessage(withId: id, key: snapshot.key, mediaItem: mediaItem)
//                        
//                        if photoURL.hasPrefix("gs://") {
//                            self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: nil)
//                        }
//                    }
//                } else if let id = messageData["senderId"] as String!, let gifURL = messageData["gifURL"] as String! {
//                    print("found gif")
//                    if let mediaItem = JSQPhotoMediaItem(maskAsOutgoing: id == self.senderId) {
//                        print("1")
//                        self.addPhotoMessage(withId: id, key: snapshot.key, mediaItem: mediaItem)
//                        print("2")
//                        self.fetchGIFDataAtURL(gifURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: nil)
//                        print("3")
//                    }
//                }
//            })
//            
//            // We can also use the observer method to listen for
//            // changes to existing messages.
//            // We use this to be notified when a photo has been stored
//            // to the Firebase Storage, so we can update the message data
//            updatedMessageRefHandle = messageRef.observe(.childChanged, with: { (snapshot) in
//                let key = snapshot.key
//                let messageData = snapshot.value as! Dictionary<String, String>
//                
//                if let photoURL = messageData["photoURL"] as String! {
//                    // The photo has been updated.
//                    if let mediaItem = self.photoMessageMap[key] {
//                        self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: key)
//                    }
//                } else if let gifURL = messageData["gifURL"] as String! {
//                    // The photo has been updated.
//                    if let mediaItem = self.photoMessageMap[key] {
//                        self.fetchGIFDataAtURL(gifURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: key)
//                    }
//                }
//            })
//        }
//    }
//    
//    private func fetchImageDataAtURL(_ photoURL: String, forMediaItem mediaItem: JSQPhotoMediaItem, clearsPhotoMessageMapOnSuccessForKey key: String?) {
//        let storageRef = Storage.storage().reference(forURL: photoURL)
//        storageRef.getData(maxSize: INT64_MAX, completion: { (data, error) in
//            if let error = error {
//                print("Error downloading image data: \(error)")
//                return
//            }
//            
//            storageRef.getMetadata(completion: { (metadata, metadataErr) in
//                if let error = metadataErr {
//                    print("Error downloading metadata: \(error)")
//                    return
//                }
//                
//                if (metadata?.contentType == "image/gif") {
//                    mediaItem.image = UIImage.gifWithData(data!)
//                } else {
//                    mediaItem.image = UIImage.init(data: data!)
//                }
//                self.collectionView.reloadData()
//                
//                guard key != nil else {
//                    return
//                }
//                self.photoMessageMap.removeValue(forKey: key!)
//            })
//        })
//    }
//    
//    private func fetchGIFDataAtURL(_ gifURL: String, forMediaItem mediaItem: JSQPhotoMediaItem, clearsPhotoMessageMapOnSuccessForKey key: String?) {
//        print ( "fetchGIFDataAtURL")
////            let g = GPHMedia()
////            let newGif = AMGif(g, preferred: .high)
////            newGif.gifURL = gifURL
////            print(newGif.gifUrl)
////            gifModel = AMGifViewModel.init(newGif)
////            gifModel?.delegate = self
////            gifModel?.fetchData()
////            mediaItem.image = UIImage.gifWithData(data!)
//        
//        guard let bundleURL = URL(string: gifURL)
//            else {
//                print("SwiftGif: This image named \"\(gifURL)\" does not exist")
//                return
//        }
//        
//        // Validate data
//        guard let imageData = try? Data(contentsOf: bundleURL) else {
//            print("SwiftGif: Cannot turn image named \"\(gifURL)\" into NSData")
//            return
//        }
//        
//        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else {
//            print("SwiftGif: Source for the image does not exist")
//            return
//        }
//        
//        mediaItem.image = UIImage.animatedImageWithSource(source)
//        self.collectionView.reloadData()
//        guard key != nil else {
//            return
//        }
//        self.photoMessageMap.removeValue(forKey: key!)
//
//        //mediaItem.image = UIImage(named: "party")
//        /* UIImage.gifWithURL(gifURL, completion: {
//                print(" setting image for gif at \(gifURL)")
//                self.collectionView.reloadData()
//                guard key != nil else {
//                    return
//                }
//                //self.photoMessageMap.removeValue(forKey: key!)
//            }) */
//    }
//    
//    private func observeTyping() {
//        let typingIndicatorRef = channelRef!.child("typingIndicator")
//        userIsTypingRef = typingIndicatorRef.child(senderId)
//        userIsTypingRef.onDisconnectRemoveValue()
//        usersTypingQuery = typingIndicatorRef.queryOrderedByValue().queryEqual(toValue: true)
//        
//        usersTypingQuery.observe(.value) { (data: DataSnapshot) in
//            
//            // You're the only typing, don't show the indicator
//            if data.childrenCount == 1 && self.isTyping {
//                return
//            }
//            
//            // Are there others typing?
//            self.showTypingIndicator = data.childrenCount > 0
//            self.scrollToBottom(animated: true)
//        }
//    }
//    
//    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
//        // 1
//        let itemRef = messageRef.childByAutoId()
//        
//        // 2
//        let messageItem = [
//            "senderId": senderId!,
//            "senderName": senderDisplayName!,
//            "text": text!,
//            ]
//        
//        // 3
//        itemRef.setValue(messageItem)
//        
//        // 4
//        JSQSystemSoundPlayer.jsq_playMessageSentSound()
//        
//        // 5
//        finishSendingMessage()
//        isTyping = false
//    }
//    
//    func sendPhotoMessage() -> String? {
//        let itemRef = messageRef.childByAutoId()
//        
//        let messageItem = [
//            "photoURL": imageURLNotSetKey,
//            "senderId": senderId!,
//            ]
//        
//        itemRef.setValue(messageItem)
//        
//        JSQSystemSoundPlayer.jsq_playMessageSentSound()
//        
//        finishSendingMessage()
//        return itemRef.key
//    }
//    
//    func sendGIFMessage() -> String? {
//        let itemRef = messageRef.childByAutoId()
//        
//        let messageItem = [
//            "gifURL": gifURLNotSetKey,
//            "senderId": senderId!,
//            "senderName": senderDisplayName!,
//            ]
//        
//        //itemRef.setValue(messageItem)
//        
//        JSQSystemSoundPlayer.jsq_playMessageSentSound()
//        
//        finishSendingMessage()
//        return itemRef.key
//    }
//    
//    func prepareGIFForSend(gifURL: String, gifKey: String) {
//        print("prepareGIFForSend")
//        let itemRef = messageRef.childByAutoId()
//        
//        let messageItem = [
//            "gifURL": gifURL,
//            "senderId": senderId!,
//            "senderName": senderDisplayName!,
//            ]
//        
//        itemRef.setValue(messageItem)
//        
//        JSQSystemSoundPlayer.jsq_playMessageSentSound()
//        
//        finishSendingMessage()
////        if let key = sendGIFMessage() {
////            self.setGIFURL(gifURL, forGIFMessageWithKey: key)
////        }
//    }
//    
//    func setImageURL(_ url: String, forPhotoMessageWithKey key: String) {
//        let itemRef = messageRef.child(key)
//        itemRef.updateChildValues(["photoURL": url])
//    }
//    
//    // MARK: UI and User Interaction
//    
//    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
//        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
//        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
//    }
//    
//    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
//        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
//        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
//    }
//    
//    override func didPressAccessoryButton(_ sender: UIButton) {
//                let picker = UIImagePickerController()
//                picker.delegate = self as! UIImagePickerControllerDelegate & UINavigationControllerDelegate
//                if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
//                    picker.sourceType = UIImagePickerControllerSourceType.camera
//                } else {
//                    picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
//                }
//        
//                present(picker, animated: true, completion:nil)
//    }
//    
//    private func addMessage(withId id: String, name: String, text: String) {
//        if let message = JSQMessage(senderId: id, displayName: name, text: text) {
//            messages.append(message)
//        }
//    }
//    
//    private func addPhotoMessage(withId id: String, key: String, mediaItem: JSQPhotoMediaItem) {
//        if let message = JSQMessage(senderId: id, displayName: "", media: mediaItem) {
//            messages.append(message)
//            
//            if (mediaItem.image == nil) {
//                photoMessageMap[key] = mediaItem
//            }
//            
//            collectionView.reloadData()
//        }
//    }
//    
//    // MARK: UITextViewDelegate methods
//    
//    override func textViewDidChange(_ textView: UITextView) {
//        super.textViewDidChange(textView)
//        // If the text is not empty, the user is typing
//        isTyping = textView.text != ""
//    }
//    
//}
//
//// MARK: Image Picker Delegate
//extension FirebaseChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
//    func imagePickerController(_ picker: UIImagePickerController,
//                               didFinishPickingMediaWithInfo info: [String : Any]) {
//        
//        picker.dismiss(animated: true, completion:nil)
//        
//        // 1
//        if let photoReferenceUrl = info[UIImagePickerControllerReferenceURL] as? URL {
//            // Handle picking a Photo from the Photo Library
//            // 2
//            let assets = PHAsset.fetchAssets(withALAssetURLs: [photoReferenceUrl], options: nil)
//            let asset = assets.firstObject
//            // 3
//            if let key = sendPhotoMessage() {
//                // 4
//                asset?.requestContentEditingInput(with: nil, completionHandler: { (contentEditingInput, info) in
//                    let imageFileURL = contentEditingInput?.fullSizeImageURL
//                    
//                    // 5
//                    let path = "\(String(describing: Auth.auth().currentUser?.uid))/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/\(photoReferenceUrl.lastPathComponent)"
//                    
//                    // 6
//                    self.storageRef.child(path).putFile(from: imageFileURL!, metadata: nil) { (metadata, error) in
//                        if let error = error {
//                            print("Error uploading photo: \(error.localizedDescription)")
//                            return
//                        }
//                        // 7
//                        self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
//                    }
//                })
//            }
//        } else {
//            // Handle picking a Photo from the Camera - TODO
//        }
//    }
//    
//    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//        picker.dismiss(animated: true, completion:nil)
//    }
//    
//    func giphyModelDidBeginLoadingThumbnail(_ item: AMGifViewModel?) {}
//    func giphyModelDidEndLoadingThumbnail(_ item: AMGifViewModel?) {}
//    func giphyModelDidBeginLoadingGif(_ item: AMGifViewModel?) {}
//    
//    func giphyModel(_ item: AMGifViewModel?, thumbnail data: Data?) {
//    }
//    
//    func giphyModel(_ item: AMGifViewModel?, gifData data: Data?) {
////        let appearance = SCLAlertView.SCLAppearance (
////            showCloseButton: true
////        )
////        let alert = SCLAlertView(appearance: appearance)
////        let imageView = FLAnimatedImageView(frame: CGRect(x: 10, y: 0, width: alert.view.frame.width-20, height: 200))
////        imageView.animatedImage = FLAnimatedImage(animatedGIFData: data)
////        imageView.translatesAutoresizingMaskIntoConstraints = false
////        imageView.leftAnchor.constraint(greaterThanOrEqualTo: alert.view.leftAnchor).isActive = true
////        imageView.rightAnchor.constraint(lessThanOrEqualTo: alert.view.rightAnchor).isActive = true
////        imageView.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor).isActive = true
////        imageView.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 100).isActive = true
////        heightConstr = imageView.heightAnchor.constraint(equalToConstant: gifHeightConstr.constant)
////        widthConstr = imageView.widthAnchor.constraint(equalToConstant: gifWidthConstr.constant)
////
////        alert.customSubview = imageView
////        alert.addButton("Send") {
////
////        }
////        alert.addButton("Cancel") {
////            self.dismiss(animated: true)
////        }
////        alert.showSuccess("Send GIF?", subTitle: "")
//        
//        
//        
//    }
//    
//    func giphyModel(_ item: AMGifViewModel?, gifProgress progress: CGFloat) {}
//    
//    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
//        print("searchbar did end editing")
//        self.searchBar.endEditing(true)
//        self.searchBar.resignFirstResponder()
//    }
//    
//    func searchBarTextShouldEndEditing(_ searchBar: UISearchBar) {
//        print("searchbar did end editing")
//        self.searchBar.endEditing(true)
//        self.searchBar.resignFirstResponder()
//    }
//    
//    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        self.searchBar.endEditing(true)
//        self.searchBar.resignFirstResponder()
//        gifView.search(searchBar.text)
//    }
//}
//
