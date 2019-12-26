//
//  aboutPageView.swift
//  FBConnect
//
//  Created by user157153 on 7/9/19.
//  Copyright © 2019 Kevin Peralta. All rights reserved.
//

import UIKit

class aboutPageView: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.aboutlabel.layer.cornerRadius = 5
        self.aboutlabel.layer.masksToBounds = true
        // Do any additional setup after loading the view.
    }
    
    @IBOutlet weak var descriptionOfAppLabel: UILabel!
    @IBOutlet weak var aboutlabel: UIButton!
    
    @IBAction func sendbackHome(_ sender: UIButton) {
        performSegue(withIdentifier: "backHomeAbout", sender: self)
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
