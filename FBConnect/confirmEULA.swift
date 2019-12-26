//
//  confirmEULA.swift
//  FBConnect
//
//  Created by user158771 on 10/22/19.
//  Copyright © 2019 Kevin Peralta. All rights reserved.
//

import SwiftUI


class confirmEULA: UIViewController {
    var tempPrsn: mainUser?
    var tmpToken: String?
    var tmpSecret: String?
    
    @IBAction func didAgree(_ sender: UIButton) {
        dataB.addUserToDB(person: tempPrsn!)
        saveTwitterSesh(token: tmpToken!, secret: tmpSecret!, UID: ((tempPrsn?.getUserUID())!)) { (didSave) in
            if didSave {
                self.performSegue(withIdentifier: "freshLogin", sender: self)
            }
        }
    }
    
    @IBAction func didNotAgree(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet var buttons: [UIButton]!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "freshLogin" {
            let tabs = segue.destination as! UITabBarController
            let dest = tabs.viewControllers![0] as! tab1View
            dest.room = nil
        }
        
    }
    override func viewDidAppear(_ animated: Bool) {
        for button in self.buttons {
            button.layer.cornerRadius = 5
            button.layer.masksToBounds = true
        }
    }
}
