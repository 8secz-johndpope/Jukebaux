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
import GoogleSignIn

class LogInViewController: UIViewController, UITextFieldDelegate, GIDSignInUIDelegate, GIDSignInDelegate {
    
    @IBOutlet var gSignInButton: GIDSignInButton!
    @IBOutlet var JamSeshLogo: UIImageView!
    @IBOutlet var tapToPartyButton: UIButton!
    @IBOutlet var joinAsGuestButton: UIButton!
    @IBOutlet var tapToPartyShimmeringView: FBShimmeringView!
    
    let SharedJamSeshModel = JamSeshModel.shared
    let userDefaults = UserDefaults.standard
    var loadingIndicatorView : NVActivityIndicatorView!
    var overlay : UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        joinAsGuestButton.isHidden=true
        tapToPartyShimmeringView.contentView = tapToPartyButton
        tapToPartyShimmeringView.isShimmering = true
        
        // Set up loading view animation
        loadingIndicatorView = NVActivityIndicatorView(frame: CGRect(x:0,y:0,width:100,height:100), type: NVActivityIndicatorType(rawValue: 31), color: SharedJamSeshModel.mainJamSeshColor )
        loadingIndicatorView.center = self.view.center
        overlay = UIView(frame: view.frame)
        overlay!.backgroundColor = UIColor.black
        overlay!.alpha = 0.7
        loadingIndicatorView.isHidden = true
        overlay?.isHidden = true
        self.view.addSubview(overlay!)
        self.view.addSubview(loadingIndicatorView!)
        
//        gSignInButton = GIDSignInButton(frame: CGRect(x: (self.view.frame.width/2)-25,y: 2*self.view.frame.height/3, width: 50,height: 100))
        gSignInButton.isHidden = true
        gSignInButton.colorScheme = GIDSignInButtonColorScheme.dark
        self.view.addSubview(gSignInButton)
        
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        
        if Auth.auth().currentUser != nil { // if user is already logged in, sign in with Google
            print("user already logged in")
            GIDSignIn.sharedInstance().signIn()
            gSignInButton.isEnabled = false
            showLoadingAnimation()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    @IBAction func TapToPartyPressed(_ sender: Any) {
        print("tap to party")
        UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut, animations: {
//            self.JamSeshLogo.alpha = 0.0
            self.tapToPartyButton.isHidden = true
        }, completion: {_ in
            self.gSignInButton.isHidden = false
            self.joinAsGuestButton.isHidden=false
        })
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func googleLogIn(credential: AuthCredential) {
        print("google log in")
        Auth.auth().signIn(with: credential) { (user, error) in
            if let error = error {
                self.hideLoadingAnimation()
                SCLAlertView().showError("Whoops!", subTitle: error.localizedDescription)
            }
            
            print("made it to here")
            self.loadUserFromFirebaseThenSegue()
        }
    }
    
    func loadUserFromFirebaseThenSegue() {
        let uid = Auth.auth().currentUser?.uid
        print(uid!)
        Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()) {
                print("user is in database")
                if let dict = snapshot.value as? [String: AnyObject] {
                    let username = (dict["username"] as? String)!
                    let email = (dict["email"] as? String)!
                    let password = (dict["password"] as? String)!
                    self.userDefaults.setValue(email, forKey: "email")
                    self.userDefaults.setValue(password, forKey: "password")
                    let newUser = User(name: username, email:email, password:password)
                    newUser.userID = (dict["userID"] as? String)!
                    
                    self.SharedJamSeshModel.setMyUser(newUser:newUser)
                    self.hideLoadingAnimation()
                    print("should segue to parties")
                    self.segueToPartiesScreen()
                }
                else {
                    print("load user error" )
                    self.hideLoadingAnimation()
                    SCLAlertView().showError("Whoops!", subTitle: "Error while loading user")
                }
            } else {
                let username = ((Auth.auth().currentUser?.displayName)!).replacingOccurrences(of: " ", with: "")
                let email = (Auth.auth().currentUser?.email)!
                let newUser = User(name: username, email: email)
                newUser.userID = uid!
                self.SharedJamSeshModel.addNewUser(newUser: newUser)
                self.SharedJamSeshModel.setMyUser(newUser:newUser)
                
                // TODO: Onboarding questions
                
                self.hideLoadingAnimation()
                self.segueToPartiesScreen()
            }
        }, withCancel: nil)
        
    }
    
    @IBAction func joinAsGuestButtonPressed(_ sender: Any) {
        print("Join as guest button pressed")
        self.loadingIndicatorView.isHidden = false
        self.loadingIndicatorView.startAnimating()
        self.overlay?.isHidden = false
        Auth.auth().signInAnonymously() { (user, error) in
            if(error != nil ){
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
    
    @available(iOS 9.0, *)
    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any])
        -> Bool {
            return GIDSignIn.sharedInstance().handle(url,
                                                     sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                                     annotation: [:])
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return GIDSignIn.sharedInstance().handle(url,
                                                 sourceApplication: sourceApplication,
                                                 annotation: annotation)
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        if let error = error {
            print("error: \(error)")
            return
        }
        print("google did sign in")
        showLoadingAnimation()
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        googleLogIn(credential: credential)
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
        print("google disconnect")
    }
    
    /*****************************************************************************/
    
    func hideLoadingAnimation() {
        self.loadingIndicatorView.stopAnimating()
        self.loadingIndicatorView.isHidden = true
        self.overlay?.isHidden = true
//        self.view.willRemoveSubview(self.overlay!)
    }
    
    func showLoadingAnimation() {
        self.loadingIndicatorView.startAnimating()
        self.loadingIndicatorView.isHidden = false
        self.overlay?.isHidden = false
//        self.view.addSubview(self.overlay!)
    }
    /*****************************************************************************/
}
