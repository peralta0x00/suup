//
//  DataViewController.swift
//  FBConnect
//
//  Created by Kevin Peralta on 6/8/19.
//  Copyright © 2018 Kevin Peralta. All rights reserved.
//
import UIKit
import SafariServices
import Firebase
import FirebaseAuth
import TwitterCore
import TwitterKit

func createError(mensaje: String) -> UIAlertController {
    let errormessage = UIAlertController(title: "Error", message: mensaje, preferredStyle: .alert)
    errormessage.addAction(UIAlertAction(title: "Alright", style: .default, handler: nil))
    return errormessage
}

class loginView: UIViewController {
    var temp: mainUser?
    var tokenSecret: [String]?
    @IBOutlet weak var visitUsLabel: UIButton!
    @IBOutlet weak var afuckinglabel: UILabel!
    @IBOutlet weak var aboutButton: UIButton!
    @IBOutlet weak var updatedLoginButton: UIButton! //can refactor in future..
     let provider = OAuthProvider(providerID: "twitter.com")
    
    @IBAction func updatedLoginAction(_ sender: UIButton) {
       
        provider.getCredentialWith(nil) { (creds, error) in

            if creds != nil {
                Auth.auth().signIn(with: creds!) { (authResult, error) in
                    if let result = authResult {
                        print("here's auth result from updated method: \(result)")
                        TWTRAPIClient(userID: result.user.uid).loadUser(withID: result.user.uid) { (loggedUser, error) in
                            if error != nil {
                                self.present(createError(mensaje: "error loading creds with updated method: \(error!)"), animated: true)
                            }
                            else if loggedUser != nil {
                                person = mainUser(user: loggedUser!)
                            }
                        }
                    }
                }
            }
        }

    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func visitWebsite(_ sender: UIButton) {
        if let website = URL(string: "https://www.suup.us") {
            UIApplication.shared.open(website, options: [:], completionHandler: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func showAboutPage(_ sender: UIButton) {
        performSegue(withIdentifier: "showAboutPage", sender: self)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return TWTRTwitter.sharedInstance().application(app, open: url, options: options)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.aboutButton.layer.cornerRadius = 5
        self.aboutButton.layer.masksToBounds = true
        self.visitUsLabel.layer.cornerRadius = 5
        self.visitUsLabel.layer.masksToBounds = true
        
        
        
        let loginButton = TWTRLogInButton { (result, error) in
            if error != nil {
                self.present(createError(mensaje: error!.localizedDescription), animated: true)
            }
            if let session = result {
                let credentials = TwitterAuthProvider.credential(withToken: session.authToken, secret: session.authTokenSecret)
                self.didLoginIntoFirebase(userCreds: credentials, completion: { (didLogin) in
                    if didLogin {
                        let client = TWTRAPIClient(userID: session.userID)
                        client.loadUser(withID: session.userID, completion: { (prsn, error) in
                            if error != nil || prsn == nil {
                                super.present(createError(mensaje: "Failed to authenticate with Twitter.\nPlease try again."), animated: true)
                            }
                            else {
                                dataB.userExists(id: prsn!.userID, completion: { (doesExist) in
                                    if !doesExist {
                                        self.temp = mainUser(user: prsn!)
                                        self.tokenSecret = [session.authToken, session.authTokenSecret]
                                        self.performSegue(withIdentifier: "goConfirmEULA", sender: self)
                                    }
                                    else {
                                        saveTwitterSesh(token: session.authToken, secret: session.authTokenSecret, UID: session.userID) { (didSave) in
                                            if didSave {
                                                self.performSegue(withIdentifier: "loggedIn", sender: self)
                                            }
                                        }
                                    }
                                })
                            }
                        })
                    }
                    else {
                        super.present(createError(mensaje: "Failed to connect to server.\nPlease try again"), animated: true)
                    }
                })
            }
            else if !(error?.localizedDescription.contains("cancelled login"))! {
                self.temp = nil
                self.tokenSecret = nil
                super.present(createError(mensaje: "Please try logging in again"), animated: true)
            }
        }
        loginButton.center.y = self.afuckinglabel.center.y + 75 //self.aboutButton.center.y - 20
        loginButton.center.x = self.afuckinglabel.center.x
        view.addSubview(loginButton)

    }
    
    
    
    private func didLoginIntoFirebase(userCreds: AuthCredential, completion: @escaping (Bool) -> ()) {
        Auth.auth().signIn(with: userCreds, completion: { (user, error) in
            if error != nil {
                completion(false)
            }
            else {
                completion(true)
            }
        })
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "loggedIn" {
            let tabs = segue.destination as! UITabBarController
            let dest = tabs.viewControllers![0] as! tab1View
            dest.room = nil
        }
        else if segue.identifier == "goConfirmEULA" {
            let dest = segue.destination as! confirmEULA
            dest.tempPrsn = temp!
            dest.tmpToken = self.tokenSecret![0]
            dest.tmpSecret = self.tokenSecret![1]
        }
    }
    
}


