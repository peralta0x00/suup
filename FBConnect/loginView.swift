//
//  DataViewController.swift
//  FBConnect
//
//  Created by Kevin Peralta on 6/8/18.
//  Copyright © 2018 Kevin Peralta. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit


class DataViewController: UIViewController {

    @IBOutlet weak var dataLabel: UILabel!
    
    let keyID = "com.facebook.sdk.v4.FBSDKAccessTokenInformationKey"
    var dataObject: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        FBSDKProfile.enableUpdates(onAccessTokenChange: true)
        
        if  UserDefaults.standard.string(forKey: keyID) == nil{
            print("had a token")
            print(FBSDKAccessToken.current())
            
            //line below works, but computer simulator does not set accesstoken properly
            
//            FBSDKGraphRequest(graphPath: "/me", parameters: ["fields" : "id, name, picture"]).start { (response, result , error) in
//                if error != nil {
//                    print(error!)
//                }
//                else{
//                    print(result!)
//                }
//            }
            
        }
        else {
            print("gathering user info for first time")
            let login = FBSDKLoginButton()
            login.center = view.center
            login.readPermissions = ["public_profile"]
            view.addSubview(login)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let connection = FBSDKGraphRequestConnection()
        connection.add(FBSDKGraphRequest(graphPath: "/me", parameters:["fields" : "id, name"])) { (httpResponse, result, error) in
            if error != nil {
                print(error as Any)
            }
            else{
                print("no error")
                self.dataLabel.text = ((result as! [String: Any])["name"] as? String)! //set into UserDefaults
                
            }
        }
        connection.start()
        
    }


}

