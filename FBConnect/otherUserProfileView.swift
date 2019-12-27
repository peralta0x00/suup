//
//  otherUserProfileView.swift
//  FBConnect
//
//  Created by user157153 on 7/11/19.
//  Copyright © 2019 Kevin Peralta. All rights reserved.
//

import UIKit

class otherUserProfileView: UIViewController {
    var otherUser: user?
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var usersImage: UIImageView!
    @IBOutlet weak var usersActualName: UILabel!
    @IBOutlet weak var hometownLabel: UILabel!
    @IBOutlet weak var blockedDescript: UIButton!
    @IBOutlet var buttonsToRound: [UIButton]!
    
    @IBAction func returnBack(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func blockingAction(_ sender: UIButton) {
        if var current = UserDefaults.standard.value(forKey: "blockedList") as? [String] {
            if current.contains(self.otherUser!.getUserUID()) { //bc blocked, will unblock user
                if let index = current.firstIndex(of: self.otherUser!.getUserUID()) {
                    dataB.unblockPerson(otherUID: self.otherUser!.getUserUID()) { (isDone) in
                        if isDone {
                            current.remove(at: index)
                            UserDefaults.standard.set(current, forKey: "blockedList")
                            self.blockedDescript.setAttributedTitle(NSAttributedString(string: "Block"), for: .normal)
                        }
                        else {
                            self.present(createError(mensaje: "Failed to block user, please try again."), animated: true)
                        }
                    }
                    
                }
            }
            else { //bc unblocked, you will block user
                dataB.blockPerson(otherUID: self.otherUser!.getUserUID()) { (isDone) in
                    if isDone {
                        current.append(self.otherUser!.getUserUID())
                        UserDefaults.standard.set(current, forKey: "blockedList")
                        self.blockedDescript.setAttributedTitle(NSAttributedString(string: "Unblock"), for: .normal)
                    }
                    else {
                        self.present(createError(mensaje: "Failed to unblock user, please try again."), animated: true)
                    }
                }
            }
        }
    }
    
    
    override func viewDidLoad() {
        
        for button in self.buttonsToRound {
            button.layer.cornerRadius = 5
        }
        if let person = self.otherUser {
            self.usersActualName.text = person.getUsersName()
            person.getPic(completionHandler: { (result) in
                DispatchQueue.main.async {
                    self.usersImage.image = result
                    if let blocked =  UserDefaults.standard.value(forKey: "blockedList") as? [String] {
                        if blocked.contains(person.getUserUID()) {
                            self.blockedDescript.setAttributedTitle(NSAttributedString(string: "Unblock"), for: .normal)
                        }
                        else {
                            self.blockedDescript.setAttributedTitle(NSAttributedString(string: "Block"), for: .normal)
                        }
                    }
                }
            })
            if let town = person.getTown() {
                self.hometownLabel.text = "From: \(town)"
            }
            else {
                self.hometownLabel.text = "From: Earth (default)"
            }
            
        }
        super.viewDidLoad()
    }
        
        
        
    
    override func viewDidAppear(_ animated: Bool) {
        /**
        
 **/
            super.viewDidAppear(true)
            
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
