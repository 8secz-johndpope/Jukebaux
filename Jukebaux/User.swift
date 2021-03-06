//
//  User.swift
//  Jukebaux
//
//  Created by Adam Moffitt on 5/20/17.
//  Copyright © 2017 Adam's Apps. All rights reserved.
//

import UIKit

class User: NSObject {

    var username : String
    var password : String
    var gender : Character
    var email : String
    var age : Int
    var currentPartyID : Int
    var userID : String
    var isHost : Bool
    
    override init() {
        username = ""
        password = ""
        gender = " "
        email = ""
        age = 0
        currentPartyID = 0
        userID = ""
        isHost = false
    }
    
    convenience init(name: String, email: String) {
        self.init()
        self.username = name
        self.email = email
    }
    
    convenience init(name: String, email: String, password: String) {
        self.init()
        self.username = name
        self.email = email
        self.password = password
    }
    
    convenience init(name: String, email: String, password: String, id: String) {
        self.init()
        self.username = name
        self.email = email
        self.password = password
        self.userID = id
    }
    
    convenience init(name: String, password: String, gender: Character, email: String, age: Int, currentPartyId: Int, userID: String) {
        self.init()
        self.username = name
        self.password = password
        self.gender = gender
        self.email = email
        self.age = age
        self.currentPartyID = currentPartyId
        self.userID = userID
    }
    
    convenience init(id: String, name: String) {
        self.init()
        self.username = name
        self.userID = id
    }
    
    func toAnyObject() -> Any {
        return [
            "username": username,
            "password": password,
            "gender": String(gender),
            "email": email,
            "age": age,
            "currentPartyID": currentPartyID,
            "userID": userID,
            "isHost" : isHost
        ]
    }
}
