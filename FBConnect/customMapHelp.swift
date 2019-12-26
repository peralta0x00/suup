//
//  customMapHelp.swift
//  FBConnect
//
//  Created by user158771 on 12/16/19.
//  Copyright © 2019 Kevin Peralta. All rights reserved.
//

import Foundation
import UIKit
import Mapbox
import FirebaseDatabase

class userLocAnnot: MGLPointAnnotation {
    private var custMoodImage: UIImage?
    private var moodAsString: String?
    private var recentTime: String?
    
    init(moodStr: String?, timeStr: String?) {
        super.init()
        if moodStr != nil {
            self.moodAsString = moodStr
            self.custMoodImage = moodStr?.emojiToImage()
        }
        else {
            self.moodAsString = nil
            self.custMoodImage = nil
        }
        if timeStr != nil {
            self.recentTime = timeStr
            self.subtitle = "Last seen at \(timeStr!)"
        }
        else {
            self.recentTime = nil
        }
    }
    func getImage(completion: @escaping (UIImage?) -> Void) {
        if self.moodAsString == nil { //pretty sure there's no image then... unless i'm not actively updating image?
            completion(UIImage(named: "usericon.png"))
        }
        else if self.custMoodImage != nil {
            completion(custMoodImage)
        }
        else { //have mood, but no image.. so just return it
            completion((self.moodAsString?.emojiToImage()))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class roomAnnot: MGLPointAnnotation {
    private var roomTitle: String?
    private var activeUserCount: Int?
    private var dbRef: DatabaseReference?
    
    init(roomName: String, roomRef: DatabaseReference) {
        super.init()
        self.roomTitle = roomName
        self.dbRef = roomRef
        self.activeUserCount = nil //..
        self.updateUserCount()
        self.title = "\(self.roomTitle!)"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    /**
     observers room count by obvserving branch, counting net users by determining if "active" exists
     */
    private func updateUserCount() {
        self.dbRef?.child("users").observe(.value) { (resultingCount) in
            if resultingCount.exists() {
                if let users = resultingCount.value as? [String: [String: Any]] {
                    for (_, dict) in users where dict["active"] != nil {
                        if dict["active"] as? String == "true" {
                            self.activeUserCount = self.activeUserCount == nil ? 1 : (self.activeUserCount! + 1 )
                        }
                    }
                    self.subtitle = "\(self.activeUserCount != nil ? self.activeUserCount! : 0) active users here"
                }
            }
        }
    }
    
    func getRoomName() -> String {
        return self.roomTitle!
    }
}
