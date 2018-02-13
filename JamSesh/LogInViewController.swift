//
//  LogInViewController.swift
//  JamSesh
//
//  Created by Adam Moffitt on 3/14/17.
//  Copyright © 2017 Adam's Apps. All rights reserved.
//

import UIKit
import SCLAlertView
import FirebaseAuth
import FirebaseDatabase
import Shimmer
import NVActivityIndicatorView

class LogInViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var JamSeshLogo: UIImageView!
    
    @IBOutlet var tapToPartyButton: UIButton!
    
    @IBOutlet var usernameTextField: UITextField!
    
    @IBOutlet var passwordTextField: UITextField!
    
    @IBOutlet var logInButton: UIButton!
    
    @IBOutlet var createAccountButton: UIButton!
    
    @IBOutlet var joinAsGuestButton: UIButton!
    
    @IBOutlet var tapToPartyShimmeringView: FBShimmeringView!
    
    var loadingIndicatorView : NVActivityIndicatorView!
    var overlay : UIView?
    
    //singleton
    let SharedJamSeshModel = JamSeshModel.shared
    let userDefaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        usernameTextField.isHidden=true
        passwordTextField.isHidden=true
        logInButton.isHidden=true
        createAccountButton.isHidden=true
        joinAsGuestButton.isHidden=true
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        tapToPartyShimmeringView.contentView = tapToPartyButton
        tapToPartyShimmeringView.isShimmering = true
        
        // Set up loading view animation
        loadingIndicatorView = NVActivityIndicatorView(frame: CGRect(x:0,y:0,width:100,height:100), type: NVActivityIndicatorType(rawValue: 31), color: UIColor.purple )
        loadingIndicatorView.center = self.view.center
        overlay = UIView(frame: view.frame)
        overlay!.backgroundColor = UIColor.black
        overlay!.alpha = 0.7
        loadingIndicatorView.isHidden = true
        overlay?.isHidden = true
        self.view.addSubview(overlay!)
        self.view.addSubview(loadingIndicatorView!)
    }

    override func viewWillAppear(_ animated: Bool) {
        if( userDefaults.string(forKey: "email") !=  nil ){
            let email = userDefaults.string(forKey: "email")
            let password = userDefaults.string(forKey: "password")
            logIn(email: email!, password: password!)
        }
    }
    
    @IBAction func TapToPartyPressed(_ sender: Any) {
        print("tap to party")
        
        UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut, animations: {
            self.JamSeshLogo.alpha = 0.0
            self.tapToPartyButton.isHidden = true
        }, completion: {_ in
            self.usernameTextField.isHidden=false
            self.passwordTextField.isHidden=false
            self.logInButton.isHidden=false
            self.createAccountButton.isHidden=false
            self.joinAsGuestButton.isHidden=false
        })
            
        /*
        UIView.animate(withDuration: 0.5,delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            let frame = self.JamSeshLogo.frame
            self.JamSeshLogo.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: 100)
            
            /*
            self.usernameTextField.isHidden=false
            self.passwordTextField.isHidden=false
            */
            
            self.tapToPartyButton.isHidden = true
        }, completion: {_ in
            self.usernameTextField.isHidden=false
            self.passwordTextField.isHidden=false
            self.logInButton.isHidden=false
            self.createAccountButton.isHidden=false
            self.joinAsGuestButton.isHidden=false
            
            /*
            UIView.animate(withDuration: 0.5, animations: {
                self.centerXAlignmentPassword.constant += self.view.bounds.width
                self.centerXAlignmentUsername.constant += self.view.bounds.width
            })*/
            
        }) */
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
   
    @IBAction func logInButtonPressed(_ sender: Any) {
        
        let email = self.usernameTextField.text
        let password = self.passwordTextField.text
        self.loadingIndicatorView.isHidden = false
        self.loadingIndicatorView.startAnimating()
        self.overlay?.isHidden = false
        logIn(email: email!, password: password!)
    }
    
    func logIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password, completion: { (user, err) in
            if(err != nil ){
                self.dismissKeyboard()
                self.loadingIndicatorView.stopAnimating()
                self.loadingIndicatorView.isHidden = true
                self.overlay?.isHidden = true
                SCLAlertView().showError("Whoops!", subTitle: err!.localizedDescription)
            }
            else{
                self.userDefaults.setValue(email, forKey: "email")
                self.userDefaults.setValue(password, forKey: "password")
                let uid = Auth.auth().currentUser?.uid
                Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value, with: { (snapshot) in
                    if let dict = snapshot.value as? [String: AnyObject] {
                        let username = (dict["username"] as? String)!
                        let newUser = User(name: username, email:email, password:password)
                        newUser.userID = (dict["userID"] as? String)!
                        newUser.gender = (dict["gender"] as? String)!.characters.first!
                        newUser.age = (dict["age"] as? Int)!
                        
                        self.SharedJamSeshModel.setMyUser(newUser:newUser)
                        self.loadingIndicatorView.stopAnimating()
                        self.loadingIndicatorView.isHidden = true
                        self.overlay?.isHidden = true
                    }
                    
                    self.segueToPartiesScreen()
                }, withCancel: nil)
            }
        })
    }
    
    @IBAction func createAccountButtonPressed(_ sender: Any) {
        
        dismissKeyboard()
        
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton: true
        )
        let alert = SCLAlertView(appearance: appearance)
        let username = alert.addTextField("Username: ")
        let email = alert.addTextField("Email: ")
        let password = alert.addTextField("Password: ")
        alert.addButton("Let's Party!") {
            //if textfields are both not empty, create new user (in firebase and model) and segway to parties
            if(username.text != "" && password.text != "" && email.text != "") {
                Auth.auth().createUser(withEmail: email.text!, password: password.text!) { (user, error) in
                    if(error != nil ){
                        self.dismissKeyboard()
                        SCLAlertView().showError("Whoops!", subTitle: error!.localizedDescription)
                    }
                    else{
                        let newUser = User(name: username.text!, email: email.text!, password: password.text!, id: (user?.uid)!)
                    self.SharedJamSeshModel.addNewUser(newUser: newUser)
                    self.SharedJamSeshModel.setMyUser(newUser: newUser)
                    self.segueToPartiesScreen()
                    }
                }
                
            }
        }
       alert.showInfo("Create an Account", subTitle: "")

    }
    
    @IBAction func joinAsGuestButtonPressed(_ sender: Any) {
        self.loadingIndicatorView.isHidden = false
        self.loadingIndicatorView.startAnimating()
        self.overlay?.isHidden = false
        Auth.auth().signInAnonymously() { (user, error) in
            if(error != nil ){
                self.dismissKeyboard()
                self.loadingIndicatorView.stopAnimating()
                self.loadingIndicatorView.isHidden = true
                self.overlay?.isHidden = true
                SCLAlertView().showError("Whoops!", subTitle: error!.localizedDescription)
            } else {
            print(user)
                let newUser = User(id: user!.uid, name: "Rando \(user!.uid.suffix(5))")
                self.SharedJamSeshModel.addNewUser(newUser: newUser)
                self.SharedJamSeshModel.setMyUser(newUser: newUser)
                self.segueToPartiesScreen()
            }
        }
    }
    
    func segueToPartiesScreen() {
        print("segue to parties screen")
        // KYDrawerController
        let appDel = UIApplication.shared.delegate as! AppDelegate
        
        let mainVC = self.storyboard?.instantiateViewController(withIdentifier: "partiesNavVC")
        let menuVC = self.storyboard?.instantiateViewController(withIdentifier: "menuNavVC")
        appDel.drawerController.mainViewController = mainVC
        appDel.drawerController.drawerViewController = menuVC
        appDel.drawerController.drawerWidth = 150
        
        appDel.window?.rootViewController = appDel.drawerController
        appDel.window?.makeKeyAndVisible()
    }
    
    @IBAction func dismissKeyboardButton(_ sender: Any) {
        dismissKeyboard()
    }
    
    func dismissKeyboard() {
        if self.usernameTextField.isFirstResponder {
                self.usernameTextField.resignFirstResponder()
            } else if self.passwordTextField.isFirstResponder {
                self.passwordTextField.resignFirstResponder()
            }
        //self.dismissKeyboard()
    }
    
}
