import UIKit
import CoreLocation
import FirebaseAuth
import TwitterCore
import TwitterKit

class customCell: UITableViewCell {
    @IBOutlet weak var userimage: UIImageView!
    @IBOutlet weak var screenName: UILabel!
    @IBOutlet weak var usermessage: UILabel!
    @IBOutlet weak var time: UILabel!
}

class repeatCell: UITableViewCell {
    @IBOutlet weak var nextMessage: UILabel!
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

func getTimeAsString() -> String{
    let dformat = DateFormatter(); dformat.dateStyle = .none; dformat.timeStyle = .medium
    return dformat.string(from: Date())
}

class tab1View: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITabBarDelegate  {
    @IBOutlet weak var mainTable: UITableView!
    @IBOutlet weak var messageField: UITextField!
    @IBOutlet weak var roomLabel: UILabel!
    @IBOutlet weak var roomMessage: UILabel!
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var userCount: UILabel!
    @IBOutlet weak var loadingUpGIF: UIActivityIndicatorView!
    
    var distanceTimer: Timer?
    var room: chatRoom?
    var dontLoad = false
    var clearTable = false
    var otherUSER: user? = nil
    
    override func viewDidLoad() {
        if Auth.auth().currentUser == nil || TWTRTwitter.sharedInstance().sessionStore.session() == nil {
            self.dontLoad = true
            return
        }
 
        if let sesh = UserDefaults.standard.value(forKey: "TWTSESH") as? [String: String] {
            TWTRAPIClient(userID: sesh["userID"]).loadUser(withID: sesh["userID"]!) { (user, error) in
                if error != nil || user == nil {
                    self.present(createError(mensaje: "Error loading credentials. Please login again"), animated: true)
                    self.dontLoad = true
                }
                else {
                    print("successfully stored main user!")
                    person = mainUser(user: user!)
                }
            }
        }
        else {
            self.present(createError(mensaje: "Error loading credentials. Please login again"), animated: true)
        }
        
        messageField.textColor = UIColor.black
        self.mainTable.delegate = self
        self.mainTable.dataSource = self
        self.hideKeyboardWhenTappedAround()
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: NSNotification.Name(rawValue: "load"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(clearedRoom), name: NSNotification.Name(rawValue: "clearedRoom"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUserCount) , name: NSNotification.Name(rawValue: "updateUserCount"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pauseRoom) , name: NSNotification.Name(rawValue: "pauseRoom"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(comingBack) , name: NSNotification.Name(rawValue: "comingBack"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(destroy), name: UIApplication.willTerminateNotification, object: nil)
        super.viewDidLoad()
    }
    
    /**
     view immediately checks for authorization errors...
     if none, will push the most current room to holyfuck function or show nothing when there is no room
     checks done in holyfuck for some reason? i think always having checks in viewdidappear was fucked or something
     */
    override func viewDidAppear(_ animated: Bool) {
        if self.dontLoad {
            self.performSegue(withIdentifier: "backToLogin", sender:  self)
        }
        else {
            if let oldRm = UserDefaults.standard.value(forKey: "lastJoinedRoom") as? [String: String] {
                if self.room != nil && self.room!.roomIsPaused() {
                    self.loadInRoom(oldRoom: oldRm, reboot: true)
                }
                else {
                    self.loadInRoom(oldRoom: oldRm, reboot: false)
                }
            }
            else {
                self.showNothingHere()
            }
        }
        super.viewDidAppear(true)
    }
    
    
    /**
     loads room given OldRoom. reboot determines if necesssary to load room in "for first time" or if to just call, on same room, resumeRoom().
        not parsed whole other room object to compare, since checking dict and then creating room seems quicker
     - Parameter oldRoo dict from NSDefaults
     - Parameter reboot will kickstart existing room, regardless if same room
     */
    func loadInRoom(oldRoom: [String: String], reboot: Bool) {
        if reboot {
            self.room?.resumeRoom()
            return
        }
        if self.room?.title != oldRoom["roomName"] {
            self.loadingUpGIF.isHidden = false
            self.room = chatRoom(roomName: oldRoom["roomName"]!, isInMotion: false, city: oldRoom["city"]!)
            self.room?.didLoadUp(finalResult: { (didFinish) in
                if didFinish {
                    person?.listen4Blocked()
                    dataB.addToRoom(roomRef: dataB.hostRoom.locRef)
                    
                    self.roomLabel.text = self.room?.title!
                    self.mainTable.rowHeight = UITableView.automaticDimension
                    self.mainTable.estimatedRowHeight = 60
                    
                    self.messageField.isEnabled = true
                    self.sendButton.isEnabled = false
                }
                else {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "clearedRoom"), object: nil)
                    self.present(createError(mensaje: "Sorry, that room no longer exists."), animated: true)
                    self.showNothingHere()
                }
                self.loadingUpGIF.isHidden = true
            })
        }
    }
    
    
    
    private func displayAlertError(mssg: String) {
        let alert = UIAlertController(title: "Error.", message: mssg, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Alright", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.clearTable {
            return 0
        }
        if self.room?.messages.count != nil {
            return self.room!.messages.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "label", for: indexPath) as! customCell
        if indexPath.count == 1 || indexPath.count == 0 {
            cell.isHidden = true
        }
        else {
            if let info = self.room?.messages[indexPath.item] {
                if indexPath.item > 0 && info["screenName"] == self.room?.messages[indexPath.item-1]["screenName"] { //could focus on user class, but ehhhhhhhhhhhhhhhhhhhhhh
                    let tmp = tableView.dequeueReusableCell(withIdentifier: "repeat", for: indexPath) as! repeatCell
                    tmp.nextMessage.text = info["text"]
                    tmp.isUserInteractionEnabled = false  //just force tabs only with pictures to share profile link
                    tmp.layoutSubviews()
                    return tmp
                }
                
                if let user = room?.users?.getUser(UID: info["id"]!){
                    if user.getUsersPicMem() == nil {
                        user.getMessagePIC { (image) in
                            DispatchQueue.main.async {
                                cell.userimage.image = image
                            }
                        }
                    }
                    else {
                        DispatchQueue.main.async { //get the image that "is in memory"... could work with caching in v2, etc
                            cell.userimage.image = user.getUsersPicMem()
                        }
                    }
                    cell.userimage.layer.cornerRadius = cell.userimage.bounds.size.width / 2.0
                    cell.usermessage.layer.cornerRadius = 0.5
                    cell.layoutSubviews()
                }
                cell.screenName.text = info["screenName"]
                cell.usermessage.text = info["text"]
                cell.time.text = info["time"]
                DispatchQueue.main.async {
                    tableView.scrollToRow(at: IndexPath(row: (self.room?.messages.count)! - 1, section: 0) , at: .bottom, animated: true)
                }
            }
        }
        return cell
    }
    
    @IBOutlet weak var sendButton: UIButton!
    @IBAction func sendButton(_ sender: Any) {
        if !(messageField.text?.isEmpty)! && messageField.text!.count >= 2 {
            if isAppropriate(msg: messageField.text!) {
                let messageRef = dataB.hostRoom.messageRef?.childByAutoId()
                let userInfo = UserDefaults.standard
                var messageInfo = ["screenName": userInfo.value(forKey: "name") as! String,
                                   "text": messageField.text!,
                                   "id": userInfo.value(forKey: "UID") as! String,
                                   "username": userInfo.value(forKey: "username") as! String]
                messageInfo["time"] = getTimeAsString()
                messageRef?.setValue(messageInfo)
                messageField.text = ""
            }
            else {
                self.displayAlertError(mssg: "Please refrain from using negative language")
            }
            sendButton.isEnabled = false
            sendButton.backgroundColor = UIColor.gray
        }
    }
    
    /** need to hardcore min, max values for a text message*/
    @IBAction func messageEditingStatus(_ sender: UITextField) {
        if (sender.text!.count) >= 2 {
            sendButton.isEnabled = true
            sendButton.backgroundColor = UIColor.blue
        }
        if (sender.text!.count) >= 50 || sender.text!.count == 0 {
            sendButton.isEnabled = false
            sendButton.backgroundColor = UIColor.gray
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        moveTextField(tField: textField, distance: 200, isUp: true)
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        moveTextField(tField: textField, distance: 200, isUp: false)
    }
    func moveTextField(tField: UITextField, distance: Int, isUp: Bool) {
        let movement: CGFloat = CGFloat(isUp ? -distance : distance ) //will select direction
        UIView.beginAnimations("animateTextField", context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        self.view.frame = self.view.frame.offsetBy(dx: 0, dy: movement)
        UIView.commitAnimations()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.messageField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSomeone" {
            if let thisGuy = self.otherUSER {
                let dest = segue.destination as! otherUserProfileView
                dest.otherUser = thisGuy
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let otherUser = self.room?.users?.getUser(UID: (self.room?.messages[indexPath.item]["id"])!)  {
            if otherUser.getUserUID() != (UserDefaults.standard.value(forKey: "UID") as! String) {
                let alert = UIAlertController(title: "User", message: otherUser.getUsersName(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "View Profile", style: .default, handler: { (act) in
                    if let blockedBy = UserDefaults.standard.value(forKey: "blockedBy") as? [String]{
                        if blockedBy.contains(otherUser.getUserUID()) {
                            self.displayAlertError(mssg: "This user has blocked you. You cannot view this profile.")
                            return
                        }
                    }
                    self.otherUSER = otherUser
                    self.performSegue(withIdentifier: "showSomeone", sender: self)
                }))
                alert.addAction(UIAlertAction(title: "Report", style: .default, handler: { (act) in
                    dataB.rootRef.child("users").child(otherUser.getUserUID()).child("REPORTS").childByAutoId().setValue(self.room?.messages[indexPath.item]["text"])
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (act) in
                    
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @objc private func destroy() {
        if let count = room?.users?.getActiveUserCount() { //might be 0 cause in background?
            if count <= 1 {
                dataB.deleteRoom()
            }
                
            else {
                dataB.leaveRoom()
            }
        }
    }
    
    @objc private func clearedRoom() {
        self.clearTable = true
        self.room?.messages.removeAll()
        self.room?.shutDownObservers()
        self.room = nil
        
        dataB.hostRoom = temporaryName(city: nil, doUpdate: false, locRef: nil, messageRef: nil, userCreated: false)
        UserDefaults.standard.setValue(nil, forKey: "lastJoinedRoom")
        self.mainTable.reloadData()
        self.clearTable = false
    }
    @objc func reload() {
        
        if self.room != nil && (self.room?.messages.count)! > 1 {
            self.mainTable.insertRows(at: [IndexPath(row: (self.room?.messages.count)!-1, section: 0)], with: .automatic)
        }
        self.mainTable.reloadData()
    }
    @objc func pauseRoom() {
        if let ref = dataB.hostRoom.locRef {
            dataB.roomExists(ref: ref, completion: { (doesExist) in
                if doesExist {
                    self.room?.pauseRoom()
                }
            })
        }
    }
    @objc func comingBack (){ //only called when they have room they left.. so should be good to call usedaults
        if let someRoom = UserDefaults.standard.value(forKey: "lastJoinedRoom") as? [String: String] {
            self.loadInRoom(oldRoom: someRoom, reboot: true)
        }
    }
    @objc func updateUserCount() {
        if let count = self.room?.users?.getActiveUserCount() {
            self.userCount.text = "\(count) \(count > 1 ? "users are here" : "user is here")"
        }
        super.reloadInputViews()
    }
    private func showNothingHere() {
        roomMessage.isHidden = false
        mainTable.isHidden = true
        roomLabel.isHidden = true
        messageView.isHidden = true
        userCount.isHidden = true
    }
}

