//
//  chatroom.swift
//  FBConnect
//
//  Created by Kevin Peralta on 6/19/19.
//  Copyright © 2018 Kevin Peralta. All rights reserved.
//

import Foundation
import FirebaseDatabase
import Mapbox
import UIKit

/**
 will always provide these values? don't need them in memory... set type
 */
class multipleUsers {
    private var users = [String: user]()
    private var activeUserCount: Int = 0 //look up and get count for full count..
    private var roomRefListener: DatabaseReference? = nil
    /**
     initializer - asks for database reference of location of room (aka, the hostroom.locRef)
     */
    init(usersReference: DatabaseReference) { //don't include .child("users")
        self.activeUserCount = 0
        self.loadUsers(roomRef: usersReference)
    }
    
    func loadUsers(roomRef: DatabaseReference) {
        self.roomRefListener = roomRef
        roomRef.child("users").observe(.value, with: { (snapshot) in
            if let users = snapshot.value as? [String: [String: String]]{
                for (key, inf) in users { //key is represented as UID
                    if !self.users.keys.contains(key) && inf["active"]  == "true" {
                        self.activeUserCount += 1
                        dataB.hostRoom.userCount += 1
                        self.users[key] = user(picURL: inf["picURL"]!, messagePICURL: inf["messagePICURL"]!, screenName: inf["name"]!, userUID: key, activityIsOn: true)
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateUserCount"), object: nil)
                    }
                    else if self.users.keys.contains(key) && inf["active"] != self.users[key]!.isActiveAsString(){
                        switch inf["active"] {
                        case "false": //went away
                            dataB.hostRoom.userCount -= 1
                            self.activeUserCount -= 1
                        case "true":
                            dataB.hostRoom.userCount += 1
                            self.activeUserCount += 1
                        default:
                            print("don't change")
                        }
                        
                        self.users[key]?.flipActivity() //knows user is already there, so safe to switch... or can create fallback in user class?
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateUserCount"), object: nil)
                    }
                }
            }
        })
    }
    func shutOff() {
        print("turned off listening for people!")
        self.roomRefListener?.removeAllObservers()
    }
    
    func getUser(UID: String) -> user? {
        if self.contains(usersID: UID) {
            return self.users[UID]
        }
        return nil
    }
    
    func printOut() {
        for (x,y) in self.users {
            print("------\(x)-----\(y.self)\n")
        }
    }
    
    func getActiveUserCount() -> Int {
        return self.activeUserCount
    }
    
    private func contains(usersID: String) -> Bool {
        return self.users.keys.contains(usersID)
    }
    
}

class chatRoom {
    private var isPaused = false
    
    var title: String?
    var users: multipleUsers?
    var messages = [[String: String]]()
    var wasSetup = false
    var latestIndex: String? = nil
    
    var usedObservers = [DatabaseReference]()
    
    init(roomName: String, isInMotion: Bool, city: String) {
        dataB.setRefs(city: city, roomName: roomName, doUpdate: isInMotion) //should the refs be in the room? then can't access from anywhere
        self.title = roomName
        self.checkIfEverDestroyed()
    }
    
    func listen4Messages() {
        self.usedObservers.append(dataB.hostRoom.messageRef!)
        dataB.hostRoom.messageRef?.observe(.childAdded) { (snapshot) in
            if self.latestIndex != nil && snapshot.key > self.latestIndex! || self.latestIndex == nil { //when manually downloaeding at startup
                if let messageInfo = snapshot.value as? [String: String] {
                    if messageInfo.keys.count != 1 && !self.messages.contains(messageInfo) && self.notFromBlocked(UID: messageInfo["id"]!) {
                        self.messages.append(messageInfo)
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
                    }
                }
            }
        }
    }
    
    func mostRecentFive(completion: @escaping ([String: Any]) -> Void) {
        dataB.hostRoom.messageRef?.observeSingleEvent(of: .value, with: { (messageData) in
            if messageData.exists() {
                if let downloaded = messageData.value as? [String:Any] {
                    completion(downloaded)
                }
            }
            completion([String: Any].init())
        })
    }
    
    /**
     attempts to grab latest messages... if not enough, returns nil to ignore.. bad name... probably bad function..
     **/
    func latestMessages(completion: @escaping ([String: Any]?) -> Void) {
        print("here's my messageref: \(dataB.hostRoom)")
        dataB.hostRoom.messageRef?.observeSingleEvent(of: .value, with: { (dataPieces) in
            if dataPieces.exists() {
                if let formatted = dataPieces.value as? [String: Any] {
                    completion(formatted) //subtracting two for initial nil message, "users" node
                }
            }
            else {
                completion(nil)
            }
        })
    }
    
    func didLoadUp(finalResult: @escaping (Bool) -> Void) { //assumes no errors... can break onbviously...
        self.users = multipleUsers(usersReference: dataB.hostRoom.locRef!)
        self.latestMessages(completion: { (messageData) in
            if let messages = messageData { // && messageData.keys.count >= 7 {
                if messages.keys.count >= 7 {
                    for index in (messages.keys.count-7...messages.keys.count-1) {
                        let key = messages.keys.sorted()[index]
                        if key != "nil" && key != "users", let message = messages[key] as? [String: String] {
                            if !(self.messages.contains(message)) {
                                self.messages.append(message)
                                self.latestIndex = key //NECESSARY TO PREVENT LOADING BAD, OLD MESSAGES IN OBSERVE(:) FOR MESSAGEREF
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
                            }
                        }
                    }
                }
                else {
                    self.latestIndex = nil
                }
                self.listen4Messages()
                finalResult(true)
            }
            else  {
                finalResult(false)
            }
        })
        
    }
    
    /**
     observes if room ever gets destroyed... will alert function to clear room, notify with error
     message to user
     **/
    private func checkIfEverDestroyed() {
        self.usedObservers.append(dataB.hostRoom.locRef!)
        dataB.hostRoom.locRef?.observe(.value, with: { (snap) in
            if !snap.exists(){
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "clearedRoom"), object: nil)
                }
            }
        })
    }
    
    /**
     dont really know how to handle osbervers and to cleanly remove them :(
     */
    func shutDownObservers() {
        for observer in self.usedObservers {
            observer.removeAllObservers()
        }
    }
    
    
    //---------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------ really uygly functions below ---------------------------------------------------------
    //---------------------------------------------------------------------------------------------------------------------------------------
    private func notFromBlocked(UID: String) -> Bool {
        return !(UserDefaults.standard.value(forKey: "blockedList") as! [String]).contains(UID) && !(UserDefaults.standard.value(forKey: "blockedBy") as! [String]).contains(UID)
        //need to do it from the p[ersepective of someone who themselves was vblocked
    }
    
    //turn into struct based on Status?
    func pauseRoom() {
        self.shutDownObservers()
        self.isPaused = true
        dataB.hostRoom.locRef?.child("users").child(UserDefaults.standard.value(forKey: "UID") as! String).child("active").setValue("false")
    }
    func resumeRoom() { //turns on active status when re-adding to room
        self.isPaused = false
        dataB.hostRoom.locRef?.child("users").child(UserDefaults.standard.value(forKey: "UID") as! String).child("active").setValue("true")
        NotificationCenter.default.post(name: NSNotification.Name("updateUserCount"), object: nil)
        self.listen4Messages()
    }
    func roomIsPaused() -> Bool {
        return self.isPaused
    }
}
