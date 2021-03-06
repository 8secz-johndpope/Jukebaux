//
//  HostPartyViewController.swift
//  Jukebaux
//
//  Created by Adam Moffitt on 6/3/18.
//  Copyright © 2018 Adam's Apps. All rights reserved.
//

import UIKit
import SCLAlertView
import StoreKit

class HostPartyViewController: UIViewController {
    
    var cloudServiceController = SKCloudServiceController()
    let imagePicker = UIImagePickerController()
    let SharedJukebauxModel = JukebauxModel.shared
    let playMusicHandler = PlayMusicHandler.shared
    var partyImage:UIImage? = nil
    var partyName = ""
    var partyPassword = ""
    var privateParty = false
    let appearance = SCLAlertView.SCLAppearance( kCircleIconHeight: 45.0, showCircularIcon: true )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        self.appleMusicCheckIfDeviceCanPlayback()
        
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
    
    func createAParty(name: String , partyImage: UIImage, privateParty: Bool, password: String) {
        SharedJukebauxModel.newParty(name: name , partyImage: partyImage, privateParty: privateParty, password: password, numberJoined: 1, hostName: SharedJukebauxModel.myUser.username, hostID: SharedJukebauxModel.myUser.userID)
        SharedJukebauxModel.userIsHosting()
        self.navigationController?.popViewController(animated: true)
    }
    
    // Check if the device is capable of playback
    func appleMusicCheckIfDeviceCanPlayback() {
        cloudServiceController = SKCloudServiceController()
        SKCloudServiceController.requestAuthorization { (status) in
            if status != .authorized { return }
            
            self.cloudServiceController.requestCapabilities { (capability:SKCloudServiceCapability, err:Error?) in
                if capability.contains(SKCloudServiceCapability.musicCatalogPlayback) {
                    print("The user has an Apple Music subscription and can playback music!")
                    DispatchQueue.main.async {
                        self.getTitle()
                    }
                } else if  capability.contains(SKCloudServiceCapability.addToCloudMusicLibrary) {
                    print("The user has an Apple Music subscription, can playback music AND can add to the Cloud Music Library")
                    DispatchQueue.main.async {
                        self.getTitle()
                    }                    } else {
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
            alert.showInfo("Uh-oh!", subTitle: "To host a party you need an Apple Music subscription. Would you like to start a 3 month free trial today?", colorStyle: UInt(self.SharedJukebauxModel.mainJukebauxColorInt), circleIconImage: UIImage(named: "AppIcon"))
        }
    }
    
    func getTitle() {
        let appearanceSettings = SCLAlertView.SCLAppearance (kCircleIconHeight: 45.0, showCloseButton: false, showCircularIcon: true)
        
        let alert = SCLAlertView(appearance: appearanceSettings)
        
        let name = alert.addTextField("Party name")
        alert.addButton("Next") {
            if name.text != nil {
                self.partyName = name.text!
                self.getPublicOrPrivate()
            }
        }
        alert.addButton("Cancel") {
            self.navigationController?.popViewController(animated: true)
        }
        alert.showInfo("Party name?", subTitle: "No pressure just make it good", colorStyle: UInt(self.SharedJukebauxModel.mainJukebauxColorInt), circleIconImage: UIImage(named: "AppIcon"))
    }
    
    func getPublicOrPrivate() {
        let alert = SCLAlertView(appearance: appearance)
        alert.addButton("Public (Anyone can join)") {
            self.getImage()
        }
        alert.addButton("Private (Need password to join)") {
            self.getPassword()
        }
        alert.showInfo("Public or Private?", subTitle: "If you make your party private, users will need to enter a password to join", colorStyle: UInt(self.SharedJukebauxModel.mainJukebauxColorInt),  circleIconImage: UIImage(named: "AppIcon"))
    }
    
    func getPassword() {
        let alert = SCLAlertView(appearance: appearance)
        let password = alert.addTextField("Party password")
        alert.addButton("Next") {
            if password.text != nil {
                self.privateParty = true
                self.partyPassword = password.text!
                self.getImage()
            }
        }
        alert.showInfo("Party password?", subTitle: "Users will need to enter this password to join your party", colorStyle: UInt(self.SharedJukebauxModel.mainJukebauxColorInt), circleIconImage: UIImage(named: "AppIcon"))
    }
    
    func getImage() {
        let alert = SCLAlertView(appearance: appearance)
        alert.addButton("Photo Library") {
            self.getImageFromLibrary()
        }
        alert.addButton("Camera") {
            self.getImageFromCamera()
        }
        alert.showInfo("Choose Party Image", subTitle: "", colorStyle: UInt(self.SharedJukebauxModel.mainJukebauxColorInt), circleIconImage: UIImage(named: "AppIcon"))
    }
    
    func getCreateParty() {
        let alert = SCLAlertView(appearance: appearance)
        alert.addButton("Create Party") {
            self.createAParty(name: self.partyName , partyImage: self.partyImage!, privateParty: self.privateParty, password: self.partyPassword)
        }
        alert.showInfo("Ready?", subTitle: "", colorStyle: UInt(self.SharedJukebauxModel.mainJukebauxColorInt), circleIconImage: UIImage(named: "AppIcon"))
        
    }
    
    
}

//MARK: - UINavigationControllerDelegate
extension HostPartyViewController : UINavigationControllerDelegate {
    
}

//MARK: - UIImagePickerControllerDelegate
extension HostPartyViewController : UIImagePickerControllerDelegate {
    
    func getImageFromLibrary() {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
        present(imagePicker, animated: true, completion: nil)
    }
    
    func getImageFromCamera() {
        takePicture()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let pickedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        partyImage = pickedImage
        getCreateParty()
        dismiss(animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
}

//MARK: - SKCloudServiceSetupViewControllerDelegate
extension HostPartyViewController : SKCloudServiceSetupViewControllerDelegate {
    
    func cloudServiceSetupViewControllerDidDismiss(_ cloudServiceSetupViewController: SKCloudServiceSetupViewController) {
        print(#function)
    }
    
}

