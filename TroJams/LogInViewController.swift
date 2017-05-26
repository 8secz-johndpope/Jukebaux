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

class LogInViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var JamSeshLogo: UIImageView!
    
    @IBOutlet var tapToPartyButton: UIButton!
    
    @IBOutlet var usernameTextField: UITextField!
    
    @IBOutlet var passwordTextField: UITextField!
    
    @IBOutlet var logInButton: UIButton!
    
    @IBOutlet var createAccountButton: UIButton!
    
    @IBOutlet var joinAsGuestButton: UIButton!
    
    //singleton
    let SharedJamSeshModel = JamSeshModel.shared
    let userDefaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameTextField.isHidden=true
        passwordTextField.isHidden=true
        logInButton.isHidden=true
        createAccountButton.isHidden=true
        joinAsGuestButton.isHidden=true
        usernameTextField.delegate = self
        passwordTextField.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        if( userDefaults.string(forKey: "email") !=  nil ){
            let email = userDefaults.string(forKey: "email")
            let password = userDefaults.string(forKey: "password")
            logIn(email: email!, password: password!)
        }
    }
    
    @IBAction func TapToPartyPressed(_ sender: Any) {
        
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
            
        })
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
   
    @IBAction func logInButtonPressed(_ sender: Any) {
        
        let email = self.usernameTextField.text
        let password = self.passwordTextField.text
        logIn(email: email!, password: password!)
    }
    
    func logIn(email: String, password: String) {
        print("logging in")
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, err) in
            if(err != nil ){
                print(err)
                self.dismissKeyboard()
                let alert = SCLAlertView().showError("Whoops!", subTitle: err!.localizedDescription)
            }
            else{
                self.userDefaults.setValue(email, forKey: "email")
                self.userDefaults.setValue(password, forKey: "password")
                let uid = FIRAuth.auth()?.currentUser?.uid
                print("a1 \(uid!)")
                FIRDatabase.database().reference().child("users").child(uid!).observeSingleEvent(of: .value, with: { (snapshot) in
                    print("b2 \(snapshot.value!)")
                    if let dict = snapshot.value as? [String: AnyObject] {
                        print(snapshot.value!)
                        let username = (dict["username"] as? String)!
                        let newUser = User(name: username, email:email, password:password)
                        print("USERNAME: \(username)")
                        newUser.userID = (dict["userID"] as? String)!
                        newUser.gender = (dict["gender"] as? String)!.characters.first!
                        newUser.age = (dict["age"] as? Int)!
                        
                        self.SharedJamSeshModel.setMyUser(newUser:newUser)
                    }
                    
                    print("User signed in correctly")
                    self.performSegue(withIdentifier: "LogInSegue", sender: nil)
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
            print("ummmm")
            //if textfields are both not empty, create new user (in firebase and model) and segway to parties
            if(username.text != "" && password.text != "" && email.text != "") {
                    print("should be logging in now")
                FIRAuth.auth()?.createUser(withEmail: email.text!, password: password.text!) { (user, error) in
                    if(error != nil ){
                        print(error)
                        self.dismissKeyboard()
                        let alert = SCLAlertView().showError("Whoops!", subTitle: error!.localizedDescription)
                    }
                    else{
                    print("user created")
                        let newUser = User(name: username.text!, email: email.text!, password: password.text!, id: (user?.uid)!)
                    self.SharedJamSeshModel.addNewUser(newUser: newUser)
                    self.SharedJamSeshModel.setMyUser(newUser: newUser)
                    self.performSegue(withIdentifier: "LogInSegue", sender: nil)
                    }
                }
                
            }
        }
       alert.showInfo("Create an Account", subTitle: "")

    }
    
    @IBAction func joinAsGuestButtonPressed(_ sender: Any) {
        
    }
    
    @IBAction func dismissKeyboardButton(_ sender: Any) {
        dismissKeyboard()
    }
    
    func dismissKeyboard() {
       print ("dismiss keyboard")
        if self.usernameTextField.isFirstResponder {
                self.usernameTextField.resignFirstResponder()
            } else if self.passwordTextField.isFirstResponder {
                self.passwordTextField.resignFirstResponder()
            }
        //self.dismissKeyboard()
    }
    
}
