//
//  User.swift
//  JamSesh
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
    
    override init() {
        username = ""
        password = ""
        gender = " "
        email = ""
        age = 0
        currentPartyID = 0
        userID = ""
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
    
    func toAnyObject() -> Any {
        return [
            "username": username,
            "password": password,
            "gender": String(gender),
            "email": email,
            "age": age,
            "currentPartyID": currentPartyID,
            "userID": userID
        ]
    }
}
