//
//  userClass.swift
//  FBConnect
//
//  Created by Kevin Peralta on 9/27/19.
//  Copyright © 2018 Kevin Peralta. All rights reserved.
//

import Foundation
import UIKit
import TwitterKit

/**
 for main user; class extends user class by setting values "internally" in userdefaults
 - needs to be loaded in everytime? hacky
 */
class mainUser: user {
    private var uDefaults: UserDefaults = UserDefaults.standard
    
    init(user: TWTRUser) {
        /**
                subclassing helps for access purposes. mainUser sets at userDefaults level every login, for freshest info
         */
        super.init(picURL: user.profileImageLargeURL, messagePICURL: user.profileImageMiniURL, screenName: user.screenName, userUID: user.userID, activityIsOn: false)
        uDefaults.setValue(user.screenName, forKey: "username")
        uDefaults.setValue(user.profileImageLargeURL, forKey: "URLSTRING")
        uDefaults.setValue(user.profileImageURL, forKey: "messagePICURL")
        uDefaults.setValue(user.userID, forKey: "UID")
        uDefaults.setValue(user.name, forKey: "name")
        uDefaults.setValue([String](), forKey: "blockedList")
        uDefaults.setValue([String](), forKey: "blockedBy")
        self.loadBlockInfo(userUID: self.getUserUID()) { (list) in
            print("done!")
        }
        self.setTown()
    }
    
    func updateMood(newMood: String?) {
        if newMood != nil {
            dataB.rootRef.child("users").child(self.getUserUID()).child("mood").setValue(newMood!)
            self.setMood(new: newMood)
         }
         else {
            dataB.rootRef.child("users").child(self.getUserUID()).child("mood").removeValue()
         }
     }
        
    func getTownAsString() -> String? {
        return uDefaults.value(forKey: "hometown") as? String
    }
    
    /**
     helper function for listen4Blocked... observes removed values
    **/
    private func listen4unblock(UID: String, blockedBy: [String]) {
        dataB.rootRef.child("users").child(UID).child("blockedBy").observe(.childRemoved) {(result) in
            let removed = result.key
            if blockedBy.count != 0 {
                var copy = blockedBy
                if let index = copy.firstIndex(of: removed) {
                    copy.remove(at: index)
                    self.uDefaults.set(copy, forKey: "blockedBy")
                }
            }
        }
        dataB.rootRef.child("users").child(UID).observe(.childRemoved) { (result) in
            if result.key == "blockedBy" { //destroying list
                self.uDefaults.set([String](), forKey: "blockedBy") //happens at login... just resetrting....  i already  know this is extraordinarily poor coding technqieu
            }
        }
    }
    
    /**
        find users who this user has blocked... needed to be added to database
       **/

       private func loadWhoIBlocked(userUID: String, blocked: @escaping ([String]?) -> ()){
           dataB.rootRef.child("users").child(userUID).child("iBlocked").observeSingleEvent(of: .value) { (snapshot) in
               if snapshot.exists() {
                   blocked(Array((snapshot.value as! [String: Double]).keys))
               }
               else {
                   blocked(nil)
               }
           }
       }
    /**
                   neeed to load inblocked list on login... may be the case that someone logs out
                   and resets bloocked list. also cgheck hometown function because it scans for value at very
                   first login, so dragging old values... reset at logout, fix
    
       **/
    
       
       func loadBlockInfo(userUID: String, result: @escaping (Bool) -> ()) {
           self.loadBlockedBy()
           self.loadWhoIBlocked(userUID: userUID) { (blocked) in
               if blocked != nil {
                self.uDefaults.set(blocked!, forKey: "blockedList")
               }
               else{
                self.uDefaults.set([String](), forKey: "blockedList")
               }
               result(true)
           }
       }
       
    
    /**
     runs on startup of chatroom to see who has blocked this user...
    **/
    func listen4Blocked() {
        let blockedBy = uDefaults.value(forKey: "blockedBy") as! [String]
        self.listen4unblock(UID: self.getUserUID(), blockedBy: blockedBy)
        dataB.rootRef.child("users").child(self.getUserUID()).child("blockedBy").observe(.value) { (result) in
            if result.exists() {
                var copy = blockedBy
                if let formatted = (result.value as? [String: Double])?.keys {
                    for fuck in formatted where !copy.contains(fuck){
                        copy.append(fuck)
                    }
                    self.uDefaults.set(copy, forKey: "blockedBy")
                }
            }
        }
    }
    
    /**
     runs on login... checks who has blocked user. compared to chatroom, this runs on startup and immediately gives list
    **/
    func loadBlockedBy() {
        let blockedBy = uDefaults.value(forKey: "blockedBy") as! [String]
        self.listen4unblock(UID: self.getUserUID(), blockedBy: blockedBy)
        dataB.rootRef.child("users").child(self.getUserUID()).child("blockedBy").observe(.value) { (result) in
            if result.exists() {
                var copy = blockedBy
                if let formatted = (result.value as? [String: Double])?.keys {
                    for fuck in formatted {
                        if !copy.contains(fuck) {
                            copy.append(fuck)
                        }
                    }
                    self.uDefaults.set(copy, forKey: "blockedBy")
                }
            }
        }
    }
    
    
    override func setTown() {
        super.setTown() //to incapsulate for whatever reason... and set at userdefaults.standard level
        dataB.findTheirTown(UID: self.getUserUID(), dataResult: { (townResult) in
            if townResult != nil {
                self.uDefaults.setValue(townResult!, forKey: "hometown")
            }
        })
    }
    
    func setNewTown(townName: String) {
        self.uDefaults.setValue(townName, forKey: "hometown")
    }
   
    func getUsersUserName() -> String {
        return uDefaults.value(forKey: "username") as! String
    }
}

extension String {
    func emojiToImage() -> UIImage? {
        let size = CGSize(width: 30, height: 35)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.clear.set()
        let rect = CGRect(origin: CGPoint(), size: size)
        UIRectFill(CGRect(origin: CGPoint(), size: size))
        (self as NSString).draw(in: rect, withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 30)])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

class user {
    private var userImage: UIImage?
    private var name: String?
    
    var pictureURL: String?
    var messagePICURL: String?
    var messagePIC: UIImage?
    private var active: Bool?
    private var UID: String
    private var moodString: String?
    private var town: String?
    

    
    init(picURL: String, messagePICURL:String, screenName: String, userUID: String, activityIsOn: Bool?) {
        self.pictureURL = picURL //to observe from afar
        self.messagePICURL = messagePICURL
        self.name = screenName
        self.active = activityIsOn
        self.UID = userUID
        self.setMood(new: nil) //everyone is getting their mood checked?
        self.setTown()
    }
    
    func setTown() {
        dataB.rootRef.child("users").child(self.UID).observeSingleEvent(of: .value) { (usersInfo) in
            if usersInfo.exists() {
                if let info = usersInfo.value as? [String: Any] {
                    if info.keys.contains("hometown") {
                        self.town = (info["hometown"] as! String) //assuming condition above is good enough..
                    }
                    else {
                        self.town = nil
                    }
                }
            }
        }
    }
    func getTown() -> String? {
        return self.town
    }
    
    //..........
    func setMood(new: String?) {
        if new != nil {
            self.moodString = new
            return
        }
        else {
            dataB.findTheirMood(UID: self.getUserUID()) { (varName) in
                self.moodString = varName != nil ? varName : nil //replaces checking if nil and setting nil inline
            }
        }
    }
    
 
    func getMoodAsSting() -> String? {
        return self.moodString
    }
    
    func getUsersName() -> String {
        if self.name != nil {
            return self.name!
        }
        return "noUserNameFuck"
    }
    
    func getUsersPicMem() -> UIImage? {
        return self.userImage
    }
    
    func getUserUID() -> String {
        return self.UID
    }
    func getMessagePIC(completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: URL(string: self.messagePICURL!)!) { (picData, response, error) in
            if error != nil {
                self.messagePIC = nil
                self.userImage = nil
                completion(UIImage(named: "userprofile.png")!)
            }
            else {
                self.messagePIC = UIImage(data: picData!)
                self.userImage = UIImage(data: picData!)
                completion(self.messagePIC)
            }
        }.resume()
    }
    
    func getMoodPic() -> UIImage? {
        if self.moodString == nil {
            return UIImage(named: "usericon.png")
        }
        else {
            return self.moodString?.emojiToImage()
        }
    }
    /**
      checks user's pic
     - returns picture if it exists
     - if not,
        - downloads picture and returns (while setting intnernally.. shouuld i mention that here?)
            - returns default picture if error when downloading
     */
    func getPic(completionHandler: @escaping (UIImage?) -> Void) {
        if self.userImage == nil {
            URLSession.shared.dataTask(with: URL(string: self.pictureURL!)!) { (picData, response, error) in
                if error != nil {
                    self.userImage = nil
                    completionHandler(UIImage(named: "userprofile.png")!)
                }
                else {
                    self.userImage = UIImage(data: picData!)
                    completionHandler(self.userImage)
                }
            }.resume()
        }
        else {
            completionHandler(self.userImage)
        }
        
    }
    
    func flipActivity() {
        if let status = self.active {
            self.active = !status
        }
    }
    func isActive() -> Bool {
        return self.active!
    }
    func isActiveAsString() -> String {
        return self.active! ? "true" : "false"
    }
    
    private func getUsersImage() -> UIImage? {
        return self.userImage
    }
    func printOut() {
        print(self.getUserUID())
        print(self.userImage)
    }
   
    
   
}
