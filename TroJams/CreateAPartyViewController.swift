//
//  CreateAPartyViewController.swift
//  TroJams
//
//  Created by Adam Moffitt on 1/27/17.
//  Copyright © 2017 Adam's Apps. All rights reserved.
//

import UIKit

class CreateAPartyViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{

    @IBOutlet var partyNameTextField: UITextField!
    @IBOutlet var cameraButton: UIButton!
    @IBOutlet var photoLibraryButton: UIButton!
    @IBOutlet var partyImage: UIImageView!
    @IBOutlet var privatePartySwitch: UISwitch!
    @IBOutlet var choosePasswordLabel: UILabel!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var createPartyButton: UIButton!
    
    
    let imagePicker = UIImagePickerController()
    let SharedTrojamsModel = TroJamsModel.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
    }
    
    @IBAction func imageButtonTapped(_ sender: AnyObject) {
        print("CHOOSE PICTURE")
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
       SharedTrojamsModel.newParty(name: partyNameTextField.text! , partyImage: partyImage.image!, privateParty: privatePartySwitch.isOn, password: passwordTextField.text!)
        self.dismiss(animated: true) {}
        //let sourceController = self.presentingViewController as! PartiesTableViewController
        //sourceController.tableView.reloadData()
        //print("reloading data")
    
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.dismiss(animated: true) {}
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        print("this just might work")
        if let controller = sender as? PartiesTableViewController {
            print("boom shakalaka")
            controller.tableView.reloadData()
        }
    }
    

}
