//
//  HostPartyViewController.swift
//  JamSesh
//
//  Created by Adam Moffitt on 6/3/18.
//  Copyright © 2018 Adam's Apps. All rights reserved.
//

import UIKit
import SCLAlertView
import StoreKit

class HostPartyViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, SKCloudServiceSetupViewControllerDelegate {

    var cloudServiceController = SKCloudServiceController()
    let imagePicker = UIImagePickerController()
    let SharedJamSeshModel = JamSeshModel.shared
    let playMusicHandler = PlayMusicHandler.shared
    var partyImage:UIImage? = nil
    var partyName = ""
    var partyPassword = ""
    var privateParty = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        self.appleMusicCheckIfDeviceCanPlayback()
        
    }
    
    func getImageFromLibrary() {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
        present(imagePicker, animated: true, completion: nil)
    }
   
    func getImageFromCamera() {
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
        
        partyImage = pickedImage
        getCreateParty()
        dismiss(animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func createAParty(name: String , partyImage: UIImage, privateParty: Bool, password: String) {
            SharedJamSeshModel.newParty(name: name , partyImage: partyImage, privateParty: privateParty, password: password, numberJoined: 1, hostName: SharedJamSeshModel.myUser.username, hostID: SharedJamSeshModel.myUser.userID)
            SharedJamSeshModel.userIsHosting()
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
                alert.showInfo("Uh-oh!", subTitle: "To host a party you need an Apple Music subscription. Would you like to start a 3 month free trial today?", colorStyle: UInt(self.SharedJamSeshModel.mainJamSeshColorInt), colorTextButton: UInt(self.SharedJamSeshModel.mainJamSeshColorInt), circleIconImage: UIImage(named: "AppIcon"))
            }
        }
        
        func cloudServiceSetupViewControllerDidDismiss(_ cloudServiceSetupViewController: SKCloudServiceSetupViewController) {
            print(#function)
        }
        
        func getTitle() {
            let alert = SCLAlertView()
            let name = alert.addTextField("Party name")
            alert.addButton("Next") {
                if name.text != nil {
                    self.partyName = name.text!
                    self.getPublicOrPrivate()
                }
            }
            alert.showInfo("Party name?", subTitle: "No pressure just make it good", colorStyle: UInt(self.SharedJamSeshModel.mainJamSeshColorInt), colorTextButton: UInt(self.SharedJamSeshModel.mainJamSeshColorInt), circleIconImage: UIImage(named: "AppIcon"))
        }
    
    func getPublicOrPrivate() {
        let alert = SCLAlertView()
        alert.addButton("Public (Anyone can join)") {
            self.getImage()
        }
        alert.addButton("Private (Need password to join)") {
            self.getPassword()
        }
        alert.showInfo("Party name?", subTitle: "No pressure just make it good", colorStyle: UInt(self.SharedJamSeshModel.mainJamSeshColorInt), colorTextButton: UInt(self.SharedJamSeshModel.mainJamSeshColorInt), circleIconImage: UIImage(named: "AppIcon"))
    }
    
    func getPassword() {
        let alert = SCLAlertView()
        let password = alert.addTextField("Party password")
        alert.addButton("Next") {
            if password.text != nil {
                self.privateParty = true
                self.partyPassword = password.text!
                self.getImage()
            }
        }
        alert.showInfo("Party password?", subTitle: "Users will need to enter this password to join your party", colorStyle: UInt(self.SharedJamSeshModel.mainJamSeshColorInt), colorTextButton: UInt(self.SharedJamSeshModel.mainJamSeshColorInt), circleIconImage: UIImage(named: "AppIcon"))
    }
    
    func getImage() {
            let alert = SCLAlertView()
            alert.addButton("Photo Library") {
                self.getImageFromLibrary()
            }
            alert.addButton("Camera") {
                self.getImageFromCamera()
            }
            alert.showInfo("Choose Party Image", subTitle: "", colorStyle: UInt(self.SharedJamSeshModel.mainJamSeshColorInt), colorTextButton: UInt(self.SharedJamSeshModel.mainJamSeshColorInt), circleIconImage: UIImage(named: "AppIcon"))
        }
    
    func getCreateParty() {
        let alert = SCLAlertView()
        alert.addButton("Create Party") {
            self.createAParty(name: self.partyName , partyImage: self.partyImage!, privateParty: self.privateParty, password: self.partyPassword)
        }
        alert.showInfo("Ready?", subTitle: "", colorStyle: UInt(self.SharedJamSeshModel.mainJamSeshColorInt), colorTextButton: UInt(self.SharedJamSeshModel.mainJamSeshColorInt), circleIconImage: UIImage(named: "AppIcon"))

    }
    

}
