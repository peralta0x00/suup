//
//  createRoomView.swift
//  FBConnect
//
//  Created by Kevin Peralta on 6/13/19.
//  Copyright © 2018 Kevin Peralta. All rights reserved.
//

import UIKit

class createRoomView: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var labels: [UILabel]!
    
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var roomName: UITextField!
    @IBOutlet weak var descript: UITextField!
    @IBOutlet weak var inMotion: UISwitch!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var cancelRoom: UIButton!
    
    
    @IBAction func cancelCreation(_ sender: UIButton) {
        performSegue(withIdentifier: "canceledRoomCreation", sender: self)
    }
    
    @IBAction func didEditRoomField(_ sender: UITextField) {
        if roomName.text == nil || roomName.text!.count == 0 {
            createButton.isUserInteractionEnabled = false
            createButton.backgroundColor = UIColor.darkGray
        }
        else {
            let roomsName = roomName.text!
            if roomsName.count < 4 || roomsName.count > 15 {
                createButton.isUserInteractionEnabled = false
                createButton.backgroundColor = UIColor.darkGray
            }
            else if roomsName.count >= 4 {
                if let descriptCount = descript.text?.count {
                    if descriptCount >= 3 {
                        createButton.isUserInteractionEnabled = true
                        createButton.backgroundColor = UIColor.green
                    }
                }
                
            }
        }
    }
    
    
    var usersCurrentLocation: String?
    @IBAction func createRoom(_ sender: Any) {
        if !(roomName.text?.isEmpty)! {
            
            if dataB.hostRoom.messageRef != nil {
                dataB.leaveRoom()
            }
            if !isAppropriate(msg: roomName.text!) || !isAppropriate(msg: descript.text!){
                self.present(createError(mensaje: "Please enter appropriate roomname and/or subject"), animated: true)
            }
            else {
   
                    var dataDict = [String: Any]()
                    dataDict["lat"] = delAccess.locManager.location?.coordinate.latitude
                    dataDict["long"] = delAccess.locManager.location?.coordinate.longitude
                    dataDict["description"] = descript.text!
            
                    dataB.createRoom(city: delAccess.city!, roomName: roomName.text!, doUpdate: inMotion.isOn, info: dataDict)
                    if UserDefaults.standard.value(forKey: "lastJoined") as? [String:String] != nil {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "clearedRoom"), object: nil)
                    }
                    dataB.hostRoom.userCount = 0
                    performSegue(withIdentifier: "createdRoom", sender: self)
            }
        }
        else{
            self.present(createError(mensaje: "Please enter appropriate room name and topic."), animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "canceledRoomCreation" {
            navigationController?.popViewController(animated: true)
            dismiss(animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        descript.delegate = self
        roomName.delegate = self
        location.text = usersCurrentLocation!
        for shit in labels {
            shit.layer.cornerRadius = 5
        }
        createButton.layer.cornerRadius = 5
        cancelRoom.layer.cornerRadius = 5
    }

    internal func textFieldShouldReturn(_ descript: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}
