//
//  dbBrain.swift
//  FBConnect
//
//  Created by Kevin fsPeralta on 6/10/19.
//  Copyright © 2018 Kevin Peralta. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase
import CoreLocation
import TwitterKit

func isAppropriate(msg: String) -> Bool {
    var uhoh = true
    for word in ["asshole", "bitch", "fag", "faggot", "nigger", "nigga",
                 "pussy", "dick", "penis", "niggers", "niga", "cock", "cum", "liberals",
                 "liberal", "gay", "n1gga", "n1gg3r", "fuck"] {
                    if msg.contains(word) {
                        uhoh = false
                    }
    }
    return uhoh
    
}

func saveTwitterSesh(token: String, secret: String, UID: String, completion: @escaping (Bool) -> ()) {
    TWTRTwitter.sharedInstance().sessionStore.saveSession(withAuthToken: token, authTokenSecret: secret) { (sesh, error) in
        if let good = sesh {
            UserDefaults.standard.setValue(["token": good.authToken,"secret": good.authTokenSecret, "userID": UID], forKey: "TWTSESH")
            completion(true)
        }
        else {
            completion(false)
        }
    }
}

struct temporaryName {
    var city: String? //only need for chcks when room changes
    var doUpdate = false
    var locRef: DatabaseReference?
    var messageRef: DatabaseReference?
    var userCreated: Bool?
    var userCount = 0
}

var person: mainUser?


class dbBrain {
    let rootRef = Database.database().reference()
    var hostRoom = temporaryName(city: nil, doUpdate: false, locRef: nil, messageRef: nil, userCreated: false)
    var roomName: String?
    var lastRecentLocRef: DatabaseReference? = nil
    var lastTime: Date? = nil
    
    func userExists(id: String, completion: @escaping (Bool) -> ()) {
        rootRef.child("users").child(id).observeSingleEvent(of: .value, with: { (snapshot) in
            completion(snapshot.exists())
        })
    }
    
    func blockPerson(otherUID: String, completion: @escaping (Bool) -> ()) {
        if let userUID = UserDefaults.standard.value(forKey: "UID") as? String {
            rootRef.child("users").child(otherUID).child("blockedBy").observeSingleEvent(of: .value) { (currentList) in
                var temp: [String: Int]?
                if currentList.hasChildren() {
                    var copy = currentList.value as! [String: Int]
                    copy[otherUID] = 1 //override or set new val for otherUID
                    temp = copy
                }
                else {
                    temp = [userUID: 1] //person's creating new list, only set otherUID
                }
                
                self.rootRef.child("users").child(otherUID).child("blockedBy").setValue(temp!)
                self.rootRef.child("users").child(userUID).child("iBlocked").observeSingleEvent(of: .value, with: { (result) in
                    var newVal = [String: Int]()
                    if result.exists() {
                        if var val = result.value as? [String: Int] {
                            val[otherUID] = 1
                        }
                    }
                    else {
                        newVal = [otherUID: 1]
                    }
                    
                    self.rootRef.child("users").child(userUID).child("iBlocked").setValue(newVal)
                    completion(true)
                })
            }
        }
        else {
            completion(false)
        }
    }
    
    func unblockPerson(otherUID: String, completion: @escaping (Bool) -> ()) {
        if let userUID = UserDefaults.standard.value(forKey: "UID") as? String {
            self.rootRef.child("users").child(otherUID).child("blockedBy").child(userUID).removeValue()
            self.rootRef.child("users").child(userUID).child("iBlocked").child(otherUID).removeValue()
            completion(true)
        }
        else {
            completion(false)
        }
    }
    
    func storeLastSavedRoom(roomDict: [String: Any]) {
        UserDefaults.standard.setValue(roomDict, forKey: "lastJoinedRoom")
    }
    
    func addUserToDB(person: mainUser)  {
        //let userInf = UserDefaults.standard
        let storageVal = [
            "name": person.getUsersName(),
            "username": person.getUsersUserName(),
            "picURL": person.pictureURL!,
            "messagePICURL": person.messagePICURL!
        ]
        rootRef.child("users").child(person.getUserUID()).setValue(storageVal)
    }
    
    
    /**
     hacky.... but calling when user changes their name/username/pic and have room ref..
     bc existing room, they should have a node under room... which other users look at and need
     **/
    func addToRoom(roomRef: DatabaseReference?) {
        if roomRef != nil {
            let userInf = UserDefaults.standard
            if let UID = userInf.value(forKey: "UID") as? String {
                if let username = userInf.value(forKey: "username") as? String {
                    if let name = userInf.value(forKey: "name") as? String{
                        if let picUrlString = userInf.value(forKey: "URLSTRING") {
                            roomRef!.child("users").child(UID).setValue(
                                [
                                    "name": name,
                                    "username": username,
                                    "picURL": picUrlString,
                                    "messagePICURL": userInf.value(forKey: "messagePICURL")!,
                                    "active":  "true",
                            ])
                        }
                    }
                }
            }
        }
    }
    
    
    func updateRefsData(refs: [DatabaseReference], newCity: String, completionHandler: @escaping (Bool) -> Void) {
        self.setRefs(city: newCity, roomName: self.roomName!, doUpdate: true) //will keep location manager on
        refs[0].observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value != nil { //if for some reason old ref was bad
                let roomInfoCopy = snapshot.value as! [String: Any]
                self.hostRoom.locRef?.setValue(roomInfoCopy)
                refs[0].removeAllObservers()
                refs[0].removeValue()
                
                refs[1].observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.value != nil { //if for some reason old ref was bad
                        let messageInfoCopy = snapshot.value as! [String: [String: String]]
                        self.hostRoom.messageRef?.setValue(messageInfoCopy)
                        refs[1].removeAllObservers()
                        refs[1].removeValue()
                        completionHandler(true)
                    }
                })
            }
            else{
                completionHandler(false)
            }
            
        })
    }
    
    //    func downloadPic(stringURL: String?, completionHandler: @escaping (UIImage?) -> Void) {
    //        if let url = URL(string: stringURL!)  {
    //            URLSession.shared.dataTask(with: url, completionHandler: { (pic, response, error) in
    //                if error != nil {
    //                    completionHandler(UIImage())
    //                }
    //                else{
    //                    completionHandler(UIImage(data: pic!))
    //                }
    //            }).resume()
    //        }
    //    }
    
    
    
    /**
     creates room in db, sets refs to local data somewhere. after, adds user to room
     to initiate
     **/
    func createRoom(city: String, roomName: String, doUpdate: Bool, info: [String: Any]) {
        dataB.hostRoom.userCreated = true
        self.rootRef.child("messages").child(city).child(roomName).setValue(["nil": ["nil" : "nil"]])
        self.rootRef.child("rooms").child(city).child("static").child(roomName).setValue(info)
        self.setRefs(city: city, roomName: roomName, doUpdate: doUpdate)
        self.addToRoom(roomRef: dataB.hostRoom.locRef)
        self.storeLastSavedRoom(roomDict: ["roomName": roomName,
                                           "motion": "no", //!!!!!!!!!!!!!!!!!!!!!!!
            "city": city])
    }
    
    func addUserRecentLoc(cityRef: DatabaseReference?, loc: CLLocationCoordinate2D) {
        let usrInfo = UserDefaults.standard //hmmmmmm
        if self.lastRecentLocRef != nil && self.lastTime != nil && Int(Date().timeIntervalSince(self.lastTime!)) > 60 { //will renew last location regardless if same city ONLY IF ITS BEEN MORE THAN A MINUTE
            self.lastRecentLocRef?.removeValue() //NECESSARY BECAUSE YOU CNA MOVE AROUND... OTHER OPTIONS CLOSED OFF IF DELETED ROOM, ETC
            self.lastRecentLocRef = nil //TRIGGERS BELOW
        }
        if self.lastRecentLocRef == nil {
            if let dbRef = cityRef {
                if let UID = usrInfo.value(forKey: "UID") as? String {
                    var vals = [loc.latitude as Any, loc.longitude as Any, getTimeAsString()] as [Any] //x,y......
                    dataB.findTheirTown(UID: UID) { (townResult) in
                        if townResult != nil {
                            vals.append(townResult!)
                        }
                        if let pref = person?.getMoodAsSting()  {
                            vals.append(pref)
                            dbRef.child("RECENTS").child(UID).setValue(vals) // [0] = LAT, [1] = LONG, [2] = TIME, [3] = HOMETOWN (IF), [4] = MOOD (IF)
                            self.lastRecentLocRef = dbRef.child("RECENTS").child(UID)
                            self.lastTime = Date()
                        }
                    }
                }
            }
        }
    }
    func findTheirTown(UID: String, dataResult: @escaping (String?) -> ()) {
        dataB.rootRef.child("users").child(UID).child("hometown").observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() { //they've set a value before...
                dataResult((snapshot.value as! String)) //ouch
            }
            else {
                dataResult(nil)
            }
            
        }
    }
    
    func findTheirMood(UID: String, moodResult: @escaping (String?) -> ()) {
        dataB.rootRef.child("users").child(UID).child("mood").observeSingleEvent(of: .value) { (result) in
            if result.exists() {
                if let val = result.value as? String {
                    moodResult(val)
                }
            }
            else {
                
                moodResult(nil)
            }
        }
    }
    
    func removeUserRecent(cityLoc: DatabaseReference) {
        //   cityLoc.child("RECENTS").child(UserDefaults.standard.value(forKey: "UID") as! String).removeValue()
        self.lastRecentLocRef?.removeValue()
    }
    
    
    
    
    
    /**
     when joining a room; considers a moving or static room, and will accordingly track the user's location and set
     refs
     **/
    func setRefs(city: String, roomName: String, doUpdate: Bool) {
        self.roomName = roomName
        self.hostRoom.messageRef = self.rootRef.child("messages").child(city).child(roomName)
        self.hostRoom.locRef = self.rootRef.child("rooms").child(city).child(doUpdate ? "moving": "static").child(roomName)
        
        if doUpdate {
            self.hostRoom.doUpdate = true
            self.hostRoom.city = delAccess.city!
        }
        else {
            delAccess.locManager.stopUpdatingLocation()
            delAccess.city = nil //to refresh rooms... but sounds styupidi, isn't there an internal variable to do that? 
        }
    }
    
    /**
     not really working.."
     **/
    func roomExists(ref: DatabaseReference, completion: @escaping (Bool) -> ())  {
        ref.observeSingleEvent(of: .value) { (snapshot) in
            completion(snapshot.exists())
        }
    }
    
    func leaveRoom() { 
        if let uid = UserDefaults.standard.value(forKey: "UID") as? String{
            self.hostRoom.locRef?.child("users").child(uid).child("active").setValue("false")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "clearedRoom"), object: nil)
        }
    }
    
    func deleteRoom() { //removing user is unnecessary since root node is destroyed
        self.hostRoom.locRef?.removeAllObservers()
        self.hostRoom.messageRef?.removeAllObservers()
        
        self.hostRoom.locRef?.removeValue()
        self.hostRoom.messageRef?.removeValue()
        
        //i guess necessary if the room is deleted during session....
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "clearedRoom"), object: nil)
    }
    
}
