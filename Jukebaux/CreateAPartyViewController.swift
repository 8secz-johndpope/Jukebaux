//
//  CreateAPartyViewController.swift
//  Jukebaux
//
//  Created by Adam Moffitt on 1/27/17.
//  Copyright © 2017 Adam's Apps. All rights reserved.
//

import UIKit
import SCLAlertView
import StoreKit

class CreateAPartyViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, SKCloudServiceSetupViewControllerDelegate {
    
    @IBOutlet var partyNameTextField: UITextField!
    @IBOutlet var cameraButton: UIButton!
    @IBOutlet var photoLibraryButton: UIButton!
    @IBOutlet var partyImage: UIImageView!
    @IBOutlet var privatePartySwitch: UISwitch!
    @IBOutlet var choosePasswordLabel: UILabel!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var createPartyButton: UIButton!
    var cloudServiceController = SKCloudServiceController()
    let imagePicker = UIImagePickerController()
    let SharedJukebauxModel = JukebauxModel.shared
    let playMusicHandler = PlayMusicHandler.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        self.appleMusicCheckIfDeviceCanPlayback()
    }
    
    @IBAction func imageButtonTapped(_ sender: AnyObject) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
        present(imagePicker, animated: true, completion: nil)
    }
    @IBAction func takePhotoTapped(_ sender: AnyObject) {
        takePicture()
    }
    
    //https://makeapppie.com/2016/06/28/how-to-use-uiimagepickercontroller-for-a-camera-and-photo-library-in-swift-3-0/
    func takePicture(){
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.allowsEditing = false
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera
            imagePicker.cameraCaptureMode = .photo
            imagePicker.modalPresentationStyle = .fullScreen
            present(imagePicker,animated: true,completion: nil)
        }else {
            noCamera()
        }
    }
    
    //https://makeapppie.com/2016/06/28/how-to-use-uiimagepickercontroller-for-a-camera-and-photo-library-in-swift-3-0/
    func noCamera(){
        let alertVC = UIAlertController(
            title: "No Camera",
            message: "Sorry, this device has no camera",
            preferredStyle: .alert)
        let okAction = UIAlertAction(
            title: "OK",
            style:.default,
            handler: nil)
        alertVC.addAction(okAction)
        present(
            alertVC,
            animated: true,
            completion: nil)
    }
    
    //MARK: UIPICKERCONTROLLER DELEGATE METHODS
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let pickedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        partyImage.contentMode = .scaleAspectFit
        partyImage
            .image = pickedImage
        
        
        dismiss(animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func createAParty(_ sender: Any) {
        if let partyName = partyNameTextField.text,
            let partyImage = partyImage.image,
            let password = passwordTextField.text {
            var password1 = ""
            if password != nil { password1 = password }
            SharedJukebauxModel.newParty(name: partyName , partyImage: partyImage, privateParty: privatePartySwitch.isOn, password: password1, numberJoined: 1, hostName: SharedJukebauxModel.myUser.username, hostID: SharedJukebauxModel.myUser.userID)
            SharedJukebauxModel.userIsHosting()
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.dismiss(animated: true) {}
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let controller = sender as? PartiesTableViewController {
            controller.tableView.reloadData()
        }
    }
    
    @IBAction func dismissKeyboardButtonPressed(_ sender: Any) {
        
        partyNameTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        view.endEditing(true)
        
    }
    
    // Check if the device is capable of playback
    func appleMusicCheckIfDeviceCanPlayback() {
        cloudServiceController = SKCloudServiceController()
        SKCloudServiceController.requestAuthorization { (status) in
            if status != .authorized { return }
            
            self.cloudServiceController.requestCapabilities { (capability:SKCloudServiceCapability, err:Error?) in
                if capability.contains(SKCloudServiceCapability.musicCatalogPlayback) {
                    print("The user has an Apple Music subscription and can playback music!")
                    
                } else if  capability.contains(SKCloudServiceCapability.addToCloudMusicLibrary) {
                    print("The user has an Apple Music subscription, can playback music AND can add to the Cloud Music Library")
                    
                } else {
                    print("The user doesn't have an Apple Music subscription available. Now would be a good time to prompt them to buy one")
                    if capability.contains(.musicCatalogSubscriptionEligible) &&
                        !capability.contains(.musicCatalogPlayback) {
                        print("you can use SKCloudServiceSetupViewController")
                    }
                    self.promptAppleMusicPurchase()
                    // TOOO hunget got this error but he pays for apple music ...
                }
            }
        }
    }
    
    func promptAppleMusicPurchase() {
        DispatchQueue.main.async {
            let appearance = SCLAlertView.SCLAppearance(
                showCloseButton: false
            )
            let alert = SCLAlertView(appearance: appearance)
            alert.addButton("Start free trial!") {
                print("purchase apple music")
                let controller = SKCloudServiceSetupViewController()
                print(1)
                controller.delegate = self
                
                controller.load(options: [.action : SKCloudServiceSetupAction.subscribe],
                                completionHandler: { (result, error) in
                                    print("loaded")
                                    DispatchQueue.main.async {
                                        print(4)
                                        self.present(controller, animated: true, completion: {
                                            print("presented1")
                                        })
                                    }
                })
                //                DispatchQueue.main.async {
                //                    print(2)
                //                    self.present(controller, animated: true, completion: {
                //                        print("presented2")
                //                    })
                //                }
                print(3)
            }
            alert.addButton("No thanks!") {
                self.navigationController?.popViewController(animated: true)
            }
            alert.showInfo("Whoops! To Host a party you need an Apple Music subscription.", subTitle: "Start a free trial today?")
        }
    }
    
    func cloudServiceSetupViewControllerDidDismiss(_ cloudServiceSetupViewController: SKCloudServiceSetupViewController) {
        print(#function)
    }
    
    func getTitle() {
        let appearance = SCLAlertView.SCLAppearance (showCloseButton: false)
        let alert = SCLAlertView(appearance: appearance)
        let name = alert.addTextField("Party name")
        alert.addButton("Next") {
            self.getImage(name: name.text!)
        }
        alert.addButton("Cancel") {
                self.navigationController?.popViewController(animated: true)
        }
        alert.showInfo("Choose a name for your party", subTitle: "No pressure just make it good")
    }
    
    func getImage(name: String) {
        let alert = SCLAlertView()
        alert.addButton("Create Party") {
            self.SharedJukebauxModel.newParty(name: name , partyImage: UIImage(named: "party")!, privateParty: false, password: "", numberJoined: 1, hostName: self.SharedJukebauxModel.myUser.username, hostID: self.SharedJukebauxModel.myUser.userID)
            self.SharedJukebauxModel.userIsHosting()
        }
        alert.showInfo("Choose an image for your party!", subTitle: "")
    }
}
