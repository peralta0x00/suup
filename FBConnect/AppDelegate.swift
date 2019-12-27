//
//  AppDelegate.swift
//  FBConnect
//
//  Created by Kevin Peralta on 6/8/19.
//  Copyright © 2018 Kevin Peralta. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import TwitterCore
import TwitterKit

import CoreLocation


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var locManager = CLLocationManager()
    var city: String?
    var exitTime: Date?
    override init() {
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        sleep(3)
        TWTRTwitter.sharedInstance().start(withConsumerKey:"octcrjgYtJDinXo2BlWolQBtY", consumerSecret:"dt9zSGl0FrVZSso4fSfwvUkRK5esPmAmkt8g5Q0X2zx4aTXauX")
        return true
    }
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        var valueTwitter: Bool = true
        
 
        
        valueTwitter =  TWTRTwitter.sharedInstance().application(app, open: url, options: options)
        
        
        return valueTwitter
    }
    
    func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        if (extensionPointIdentifier == UIApplication.ExtensionPointIdentifier.keyboard) {
            return false
        }
        return true
    }
    
   
    
    func application(_ application: UIApplication,
                     open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        var handle: Bool = true
        
        
        let options: [String: AnyObject] = [UIApplication.OpenURLOptionsKey.sourceApplication.rawValue: sourceApplication as AnyObject, UIApplication.OpenURLOptionsKey.annotation.rawValue: annotation as AnyObject]
        
        handle = TWTRTwitter.sharedInstance().application(application, open: url, options: options)
        
        
        
        return handle
    }
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        /**
         if room exists....
         if they own the room and people exist, will remove from room...
         
         if they own room and no one else exists, will delte whole room
         
         if they dont own room, will remove room only if they come back and its been more than 60s
        **/
        
        if UserDefaults.standard.value(forKey: "lastJoinedRoom") != nil {
            self.exitTime = Date()
            if let fuck = dataB.hostRoom.locRef {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "pauseRoom"), object: nil)
            }
        }
    }

    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    func applicationWillEnterForeground(_ application: UIApplication) {
        if self.exitTime != nil { //then they were a part of something...
            let diff = Int(Date().timeIntervalSince(exitTime!)) //should be good???
            //check is to allow tab1 to load room... checks done later, kinda bad?
            if diff >= 60 {
                if dataB.hostRoom.userCount == 1 { //regarldess if they made the room, if they come back after 60s they're gone
                    dataB.deleteRoom() //?????? //will remove userdefaults in datab!!!!
                }
                else if dataB.hostRoom.userCount > 1 {
                    dataB.leaveRoom()
                }
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "clearedRoom"), object: nil)
                }
            }
            else {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "comingBack"), object: nil)
                }
            }
        }
        
    }
}

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    //have to create error messag efor when person leaves room
    func applicationWillTerminate(_ application: UIApplication) {
        
    print("person wants to leave!!!! :\(dataB.hostRoom.userCount)")
    if dataB.hostRoom.userCount == 1 {
            print("have to delete room")
            dataB.deleteRoom() // completely destrosy room /will remove userdefaults in datab!!!!
        }
        else {
                
            dataB.leaveRoom() //will remove userdefaults in datab!!!!
        }
    }

