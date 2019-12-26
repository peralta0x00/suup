//
//  tab3View.swift
//  FBConnect
//
//  Created by Kevin Peralta on 6/10/19.
//  Copyright © 2018 Kevin Peralta. All rights reserved.
//

import UIKit
import CoreLocation



class tab3View: UIViewController {
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profileImageview: UIImageView!
    @IBOutlet weak var editingTownField: UITextField!
    @IBOutlet weak var helperEditButton: UIButton!
    @IBOutlet weak var moodTab: UISegmentedControl!
    
    @IBAction func showInfo(_ sender: UIButton) {
        let info = UIAlertController(title: "Info", message: "Mood will be displayed anonymously on map when sharing your location", preferredStyle: .alert)
        info.addAction(UIAlertAction(title: "Alright", style: .default, handler: nil))
        self.present(info, animated: true)
    }
    
    @IBAction func finishedEditing(_ sender: UITextField) {
        moveTextField(tField: sender, distance: 200, isUp: false)
    }
    @IBAction func editingBegan(_ sender: UITextField) {
        moveTextField(tField: sender, distance: 200, isUp: true)
    }
    
    @IBAction func didStartEditing(_ sender: UITextField) {
        helperEditButton.titleLabel?.textColor = UIColor.white
        if editingTownField.text == nil || editingTownField.text!.count == 0 {
            helperEditButton.setAttributedTitle(NSAttributedString(string: "Cancel"), for: .normal)
            helperEditButton.isUserInteractionEnabled = true
            helperEditButton.backgroundColor = UIColor.red
        }
        else {
            let text = editingTownField.text!
            helperEditButton.setAttributedTitle(NSAttributedString(string: "Save"), for: .normal)
            if text.count < 3 || text.count > 20 {
                helperEditButton.isUserInteractionEnabled = false
                helperEditButton.backgroundColor = UIColor.gray
            }
            else if text.count >= 3 {
                helperEditButton.isUserInteractionEnabled = true
                helperEditButton.backgroundColor = UIColor.green
            }
        }
        
    }
    @IBAction func helperButtonAction(_ sender: UIButton) {
        if helperEditButton.titleLabel?.text == "Cancel" {
            helperEditButton.isHidden = true
            editingTownField.isHidden = true
            helperEditButton.backgroundColor = UIColor.red
        }
        else {
            if let UID = userInf.value(forKey: "UID") as? String {
                if let town = editingTownField.text{
                    dataB.rootRef.child("users").child(UID).child("hometown").setValue(town) //ouch
                    person?.setNewTown(townName: "hometown")
                    townLocation.text = "From: \(town)"
                    helperEditButton.isHidden = true
                    editingTownField.isHidden = true
                    helperEditButton.backgroundColor = UIColor.red
                    helperEditButton.setAttributedTitle(NSAttributedString(string: "Cancel"), for: .normal)
                    editingTownField.text = ""
                }
            } //else, weird error cause teveryone should have uid stored...
        }
    }
    
    func moveTextField(tField: UITextField, distance: Int, isUp: Bool) {
        let movement: CGFloat = CGFloat(isUp ? -distance : distance ) //will select direction
        UIView.beginAnimations("animateTextField", context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        self.view.frame = self.view.frame.offsetBy(dx: 0, dy: movement)
        UIView.commitAnimations()
    }
    
    @IBOutlet weak var townLocation: UILabel!
    
    @IBAction func editingTown(_ sender: UIButton) {
        self.editingTownField.isHidden = false
        self.helperEditButton.isHidden = false
    }
    
    let userInf = UserDefaults.standard
    
    @IBAction func changedVal(_ sender: UISegmentedControl) {
        person?.updateMood(newMood: sender.titleForSegment(at: sender.selectedSegmentIndex))
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    override func viewDidLoad() {
        if let mood = person?.getMoodAsSting(){
            switch mood {
            case "😀":
                self.moodTab.selectedSegmentIndex = 0
            case "😒":
                self.moodTab.selectedSegmentIndex = 1
            case "🧐":
                self.moodTab.selectedSegmentIndex = 2
            default:
                self.moodTab.selectedSegmentIndex = 3
            }
        }
        else {
            self.moodTab.selectedSegmentIndex = 3
        }
        hideKeyboardWhenTappedAround()
        person?.getPic(completionHandler: { (result) in
            if result != nil {
                DispatchQueue.main.async {
                    self.profileImageview.image = result!
                }
                
            }
            else {
                self.profileImageview.image = UIImage(named: "userprofile.png")
            }
        })
        
            if let nameName = person?.getUsersName() {
                nameLabel.text = nameName
            }
            
            if let whereTheyreFrom = person?.getTownAsString() {
                townLocation.text = "From: \(whereTheyreFrom)"
            }
            else {
                townLocation.text = "From: nowhere (N/A)"
            }
            
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
