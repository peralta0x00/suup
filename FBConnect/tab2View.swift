import FirebaseDatabase
import CoreLocation
import Mapbox
import UIKit
import FirebaseAuth

let dataB = dbBrain()
let delAccess = UIApplication.shared.delegate as! AppDelegate

class tab2View: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate {
    @IBOutlet weak var mapView: MGLMapView!
    @IBOutlet weak var citylabel: UILabel!
    @IBOutlet weak var joinable: UIButton!
    @IBOutlet weak var createLabel: UIButton!
    @IBOutlet var allOutlets: [UIButton]!
    @IBOutlet weak var sharelocationlabel: UILabel!
    @IBOutlet weak var userLocPref: UISwitch!
    @IBOutlet weak var usercountlabel: UILabel!
    
    @IBAction func userLocPref(_ sender: UISwitch) {
        if sender.isOn { //OUTLET CHANGING VAL -- ASSOCIATE FUNCTION, MAKE IT AWARE OF WHEN VALUE CHANGES
            let confirm = UIAlertAction(title: "I understand", style: .default, handler: { (okay) in
                self.lastUpdate = nil
                dataB.lastRecentLocRef = nil
                dataB.addUserRecentLoc(cityRef: dataB.rootRef.child("rooms").child(self.lastValidCity!), loc: delAccess.locManager.location!.coordinate)
                UserDefaults.standard.setValue(true, forKey: "locPref")
                
            })
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { (nope) in
                sender.isOn = false
            })
            
            let confirmation = UIAlertController(title: "Sharing location", message: "By turning on, you understand and agree to sharing your recent location to nearby users.", preferredStyle: .alert)
            confirmation.addAction(confirm)
            confirmation.addAction(cancel)
            self.present(confirmation, animated: true)
        }
        else {
            UserDefaults.standard.setValue(false, forKey: "locPref")
            dataB.removeUserRecent(cityLoc: dataB.rootRef.child("rooms").child(self.lastValidCity!))
            self.mapView.removeAnnotation(self.cityLocals[(person?.getUserUID())!]!)
            self.cityLocals.removeValue(forKey: (person?.getUserUID())!)
            self.lastUpdate = nil
        }
    }
    
    @IBAction func createAction(_ sender: UIButton) {
        performSegue(withIdentifier: "goCreateRoom", sender: self)
    }
    //only temporary... could probably add to third tab?
    @IBAction func logout(_ sender: Any) {
        let firauth = Auth.auth()
        do {
            try firauth.signOut()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "clearedRoom"), object: nil)
            dataB.hostRoom = temporaryName(city: nil, doUpdate: false, locRef: nil, messageRef: nil, userCreated: false)
            DispatchQueue.main.async {
                for key in ["hometown", "username", "name", "UID", "URLSTRING", "messagePICURL", "TWTSESH", "blockedList", "blockedBy"] {
                    UserDefaults.standard.removeObject(forKey: key)
                }
            }
            person = nil
            performSegue(withIdentifier: "loggingOut", sender: self)
        } catch let error as NSError {
            self.present(createError(mensaje: "Couldn't sign out. Please try again: \(error.description)"), animated: true)
        }
    }
    
    var staticRooms = [String: roomAnnot]()
    var cityLocals = [String: userLocAnnot]()
    
    var distanceToCoords = [String: Double]() //string name to distance.. do i really need a global var????
    var lastValidCity: String? = nil
    var lastUpdate: Date? = nil
    
    @IBOutlet weak var gpsAccLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        delAccess.locManager.delegate = self
        delAccess.locManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters//ouch
        delAccess.locManager.requestWhenInUseAuthorization()
        mapView.showsUserLocation = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.cleanLabels()
        delAccess.locManager.startUpdatingLocation()
        if let pref = UserDefaults.standard.value(forKey: "locPref") as? Bool { //setting to user pref
            self.userLocPref.isOn = pref //can be false or true, will set, call function
        }
        else {
            self.userLocPref.isOn = false //defaults to false
        }
    }
    
    /**
     processes user location by determining if they've not established a city or changed city; if so, will load in city and associated data
     if not, having already ran in initial phase (when first loading room), will maintain data through persistent functions (new locations don't matter if in same city..)
     */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations[0].verticalAccuracy <= 13 {
            CLGeocoder().reverseGeocodeLocation(locations[0]) { (placemark, error) in
                if error != nil {
                    print("couldn't determine location of provided coords: \(error)")
                }
                else {
                    if delAccess.city == nil || delAccess.city != placemark?[0].locality {
                        delAccess.city != placemark?[0].locality && delAccess.city != nil ? self.resetMapData() : nil //resets when new city
                        delAccess.city = placemark?[0].locality!
                        self.lastValidCity = placemark?[0].locality!
                        self.citylabel.text = placemark?[0].locality!
                        
                        self.gatherAndPresentLocals()
                        self.gatherAndPresentRooms() //maybe have this data popup, but turn off buttons
                        
                        if self.lastUpdate == nil { //gonna update if needed.. may be turned back on
                            if let wantToShare = UserDefaults.standard.value(forKey: "locPref") as? Bool {
                                if wantToShare {
                                    dataB.addUserRecentLoc(cityRef: dataB.rootRef.child("rooms").child(self.lastValidCity!), loc: locations[0].coordinate)
                                    self.lastUpdate = Date() //to compare in future...
                                }
                            }
                            else {
                                self.userLocPref.isOn = false
                            }
                        }
                        else if Int(Date().timeIntervalSince(self.lastUpdate!)) >= 60 { //will wait a minute
                            self.lastUpdate = nil  //will force to reshare loc, assuming they want toff
                        }
                        self.mapView.setCenter(locations[0].coordinate, zoomLevel: 15, animated: true)
                        self.gpsAccLabel.isHidden = true
                        self.createLabel.isEnabled = true
                        self.createLabel.layer.backgroundColor = UIColor.blue.cgColor
                    }
                }
            }
            self.updateDistances(cLoc: locations[0])
        }
        else {
            self.gpsAccLabel.isHidden = false
            self.createLabel.isEnabled = false
            self.createLabel.layer.backgroundColor = UIColor.darkGray.cgColor
            self.mapView.setCenter(locations[0].coordinate, zoomLevel: 11, animated: true)
        }
    }
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        if let recent = annotation as? userLocAnnot { //used to modify image..
            var image: UIImage? = nil
            recent.getImage { (picIcon) in
                DispatchQueue.global(qos: .background).sync {
                    image = picIcon
                }
            }
            return MGLAnnotationImage(image: (image?.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: 0, bottom: (image?.size.height)!/5, right: 0)))!, reuseIdentifier: "userAnnot")
        }
        else if let room = annotation as? roomAnnot {
            var image = UIImage(named: "roomCircle-1.png")
            var roomImage = mapView.dequeueReusableAnnotationImage(withIdentifier: "annotation")
            if room.getRoomName() == dataB.roomName {
                image = UIImage(named: "greenRoom.png") //.....
                image = image?.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: 0, bottom: (image?.size.height)!/2, right: 0))
                roomImage = MGLAnnotationImage(image: image!, reuseIdentifier: "userroom")
            }
            else {
                image = image?.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: 0, bottom: (image?.size.height)!/2, right: 0))
                roomImage = MGLAnnotationImage(image: image!, reuseIdentifier: "annotation")
            }
            return roomImage
        }
        return MGLAnnotationImage(image: UIImage(named: "usericon.png")!, reuseIdentifier: "fuck")
    }
    func mapView(_ mapView: MGLMapView, didSelect annotationView: MGLAnnotation) {
        if annotationView.isKind(of: roomAnnot.self) {
            self.joinable.isUserInteractionEnabled = true
            self.joinable.layer.backgroundColor = UIColor.blue.cgColor
        }
    }
    func mapView(_ mapView: MGLMapView, didDeselect annotationView: MGLAnnotation) {
        if annotationView.isKind(of: roomAnnot.self) {
            self.joinable.isUserInteractionEnabled = false
            self.joinable.layer.backgroundColor = UIColor.darkGray.cgColor
        }
    }
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    private func resetMapData() {
        self.mapView.removeAnnotations( Array(self.staticRooms.keys) as! [MGLAnnotation])
        self.mapView.removeAnnotations(Array(self.cityLocals.values) )
    }
    
    /**
     Checks for users who have recently looked for rooms in database. Calls function to display rooms after finding rooms, if any. Associated presentCityLocals. Will compare fresh localData with storedData and add if needed
     **/
    func gatherAndPresentLocals() {
        dataB.rootRef.child("rooms").child(self.lastValidCity!).child("RECENTS").observe(.value, with: { (snapshot) in
            if snapshot.exists() {
                if let newPPL = snapshot.value as? [String: [Any]] {
                    self.presentCityLocals(userLocs: newPPL)
                }
            }
        })
        dataB.rootRef.child("rooms").child(self.lastValidCity!).child("RECENTS").observe(.childRemoved, with: { (removedPerson) in
            if removedPerson.exists() {
                let UID = removedPerson.key //uhhhh
                if let valid = self.cityLocals[UID] {
                    self.mapView.removeAnnotation(valid) // WOW
                    self.cityLocals.removeValue(forKey: UID)
                }
            }
        })
    }
    
    /**
     Handles data from provided function above. Userlocs assumes [usersUID: [usersLocDict]].
     Definetly are better techniques to stripping information down but oh well
     **/
    func presentCityLocals(userLocs: [String: [Any]]) {
        for (UID, info) in userLocs where !self.cityLocals.keys.contains(UID) {
            let recentUser = userLocAnnot(moodStr: info.count >= 5 ? info[4] as? String : nil, timeStr: info.count >= 2 ? info[2] as? String : nil)
            recentUser.coordinate = CLLocationCoordinate2D(latitude: info[0] as! Double, longitude: info[1] as! Double)
            if let home = info[3] as? String { //gonna assume doesn't change often... but if it doesn't, then update?
                recentUser.title = "From \(home)"
            }
            else {
                recentUser.title = "From Planet Earth (not yet set)"
            }
            self.cityLocals[UID] = recentUser
            self.mapView.addAnnotation(recentUser)
        }
    }
    func gatherAndPresentRooms() {
        dataB.rootRef.child("rooms").child(self.lastValidCity!).observe(.value) { (snapshot) in
            if snapshot.exists() {
                if let tmp = snapshot.value as? [String: [String: Any]] {
                    if tmp["static"] != nil  {
                        self.presentStatic(freshRooms: tmp["static"] as! [String: [String: Any]], dbREF: dataB.rootRef.child("rooms").child(self.lastValidCity!).child("static"))
                    }
                }
            }
        }
        dataB.rootRef.child("rooms").child(self.lastValidCity!).child("static").observe(.childRemoved) { (childRemoved) in
            if childRemoved.exists() {
                if let annot = self.staticRooms[childRemoved.key]  {
                    self.mapView.removeAnnotation(annot)
                    self.staticRooms.removeValue(forKey: childRemoved.key) //askdlfjlsadkf
                    self.distanceToCoords.removeValue(forKey: childRemoved.key)
                }
            }
        }
    }

    private func presentStatic(freshRooms: [String: [String: Any]], dbREF: DatabaseReference) {
        for (roomName, data) in freshRooms { //data left as [any]
            if !self.staticRooms.keys.contains(roomName)  { //not here yet..
                let room = roomAnnot(roomName: roomName, roomRef: dbREF.child(roomName))
                room.coordinate = CLLocationCoordinate2D(latitude: data["lat"] as! Double, longitude: data["long"] as! Double)
                self.staticRooms[roomName] = room
                mapView.addAnnotation(room)
            }
        }
        
    }
    private func updateMapCount() {
        if self.lastValidCity == nil {
            return
        }
        if self.staticRooms.isEmpty || self.staticRooms.count == 0 {
            self.citylabel.text = self.lastValidCity! + "\nNo rooms yet!"
        }
        else if self.staticRooms.count == 1 {
            self.citylabel.text = self.lastValidCity! + "\n\(self.staticRooms.count) room is here"
        }
        else {
            self.citylabel.text = self.lastValidCity! + "\n\(self.staticRooms.count) rooms are here"
        }
        
        self.usercountlabel.text = "\(self.cityLocals.count) recent \(self.cityLocals.count > 1 ? "users" : "user") nearby"
    }
 
    /**
     Sets global annot to calculate or whatever; prior checks in 'didselectannotation' to provide valid selectedAnnotations.count
     **/
    @IBAction func joinRoom(_ sender: Any) {
        if mapView.selectedAnnotations.count == 1 {
            if let requestedRoom = mapView.selectedAnnotations[0] as? roomAnnot {
                if let old = UserDefaults.standard.value(forKey: "lastJoinedRoom") as? [String: String] { //deal with old room, if necessary
                    if requestedRoom.getRoomName() == old["roomName"] { //same room.. what are yo udoing?
                        tabBarController?.selectedIndex = 0
                        return
                    }
                    else if requestedRoom.getRoomName() != old["roomName"] {
                        dataB.hostRoom.userCount == 1 ? dataB.deleteRoom() : dataB.leaveRoom()
                    }
                }
                dataB.storeLastSavedRoom(roomDict: ["roomName": requestedRoom.getRoomName(), "motion": "no", "city": delAccess.city!])
                performSegue(withIdentifier: "joinRoom", sender: self)
            }
        }
    }
    
    /**
     Sets up the global, current room (its name and eventually necessary user profile data, room count)
     Refs are set, potentially overriding current ones (change that??????)s
     **/
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goCreateRoom" {
            let dest = segue.destination as! createRoomView
            dest.usersCurrentLocation = delAccess.city!
        }
    }
    
    func cleanLabels() {
        for butt in self.allOutlets {
            butt.layer.cornerRadius = 5
            butt.layer.masksToBounds = true
        }
        self.citylabel.layer.cornerRadius = 5
        self.citylabel.layer.masksToBounds = true
        self.usercountlabel.layer.cornerRadius = 5
        self.usercountlabel.layer.masksToBounds = true
    }
    
    func getDistance(x1: Double, y1: Double, x2: Double, y2: Double) -> Double {
        return sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2))
    }
    
    func keysForValue(dict: [String: Double], value: Double) ->  [String] {
        return dict.compactMap { (key: String, val: Double) -> String? in
            value == val ? key : nil
        }
    }
    
    /**
     will compare distance to each room and accordingly turn on/off buttons, labels, etc;
     handles no rooms existing
     
     WOULD GREATLY BENEFIT FROM UPDATING ALGO TO GREAT CIRCLE DISTANCE.... please update mee!!~~!!!
     **/
    func updateDistances(cLoc: CLLocation?) {
        if self.lastValidCity == nil {
            return
        }
        self.updateMapCount()
        if self.staticRooms.isEmpty { //want to make sure its tried to load what i can
            self.createLabel.isUserInteractionEnabled = true
            self.createLabel.layer.backgroundColor = UIColor.blue.cgColor
            return
        }
        if let loc = cLoc {
            var dist = 0.0
            for (key, roomData) in self.staticRooms {
                dist =  self.getDistance(x1: roomData.coordinate.latitude, y1: roomData.coordinate.longitude, x2: loc.coordinate.latitude, y2: loc.coordinate.longitude)
                self.distanceToCoords[key] = dist
            }
            
            let sorted = Array(self.distanceToCoords.values).sorted(by: <)
            
            if sorted[0] < 0.0028 { // 0.0007 is completely arbitrary i think
                self.createLabel.isUserInteractionEnabled = false
                self.createLabel.layer.backgroundColor = UIColor.darkGray.cgColor
            }
            else if sorted[0] > 0.0028 && self.createLabel.isUserInteractionEnabled == false { //was too close, but back off... free to create room
                self.createLabel.isUserInteractionEnabled = true
                self.createLabel.layer.backgroundColor = UIColor.blue.cgColor
            }
        }
        else {
            self.createLabel.isUserInteractionEnabled = false
            self.createLabel.layer.backgroundColor = UIColor.darkGray.cgColor
        }
    }
}

