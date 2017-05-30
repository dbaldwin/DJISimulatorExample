//
//  ViewController.swift
//  DJISimulatorExample
//
//  Created by Dennis Baldwin on 4/25/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit
import DJISDK
import VideoPreviewer
import GoogleMaps
import FirebaseDatabase
import FirebaseAuth

class ViewController: UIViewController {
    
    @IBOutlet weak var googleMapView: GMSMapView!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var debugLabel: UILabel!
    
    var aircraftMarker: GMSMarker!
    var camera: DJICamera?
    var markers : [GMSMarker] = []
    var waypoints : [WaypointModel] = []
    
    var filePath : String {
        let manager = FileManager.default
        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
        return url.appendingPathComponent("WaypointModel")!.path
    }
    
    fileprivate var _isSimulatorActive: Bool = false
    
    public var isSimulatorActive: Bool {
        get {
            return _isSimulatorActive
        }
        set {
            _isSimulatorActive = newValue
            self.simulatorButton.titleLabel?.text = _isSimulatorActive ? "Stop Simulator" : "Start Simulator"
        }
    }
    
    @IBOutlet weak var simulatorButton: UIButton!
    @IBOutlet weak var startMissionButton: UIButton!
    @IBOutlet weak var checklistButton: UIButton!
    @IBOutlet weak var shootPhotoButton: UIButton!
    @IBOutlet weak var locationLabel: UILabel!
    
    var isStoringPhoto: Bool = false {
        didSet {
            checkPhotoSaved()
        }
    }
    
    //Firebase Storage Initialization
    var ref = Database.database().reference()
    let userID = Auth.auth().currentUser?.uid

    override func viewDidLoad() {
        super.viewDidLoad()
        googleMapView.delegate = self
        // Start listening for aircraft location updates
        let locationKey = DJIFlightControllerKey(param: DJIFlightControllerParamAircraftLocation)
        DJISDKManager.keyManager()?.startListeningForChanges(on: locationKey!, withListener: self, andUpdate: { (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
            if newValue != nil {
                // DJIFlightControllerParamAircraftLocation is associated with a DJISDKLocation object
                let aircraftCoordinates = newValue!.value! as! CLLocation
                
                self.locationLabel.text = "Lat: \(aircraftCoordinates.coordinate.latitude) - Lng: \(aircraftCoordinates.coordinate.longitude)"
                
                // Display the aircraft marker on the map
                if (self.aircraftMarker == nil) {
                    
                    self.aircraftMarker = GMSMarker()
                    self.aircraftMarker.map = self.googleMapView
                    
                    let camera = GMSCameraPosition.camera(withLatitude: aircraftCoordinates.coordinate.latitude, longitude: aircraftCoordinates.coordinate.longitude, zoom: 16)
                    self.googleMapView.camera = camera
                    
                }
                
                self.aircraftMarker.position = aircraftCoordinates.coordinate
                
                
            }
        })
        
        // Start listening for battery updates
        /*let batteryLevelKey = DJIBatteryKey(param: DJIBatteryParamChargeRemainingInPercent)
        DJISDKManager.keyManager()?.startListeningForChanges(on: batteryLevelKey!, withListener: self, andUpdate: { (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
            
            if newValue != nil {
                
                self.batteryLabel.text = "Battery: \(newValue!.unsignedIntegerValue) %"
                
            }
            
            
        })*/
        
        // Listen for simulator status updates
        if let isSimulatorActiveKey = DJIFlightControllerKey(param: DJIFlightControllerParamIsSimulatorActive) {
            DJISDKManager.keyManager()?.startListeningForChanges(on: isSimulatorActiveKey, withListener: self, andUpdate: { (oldValue: DJIKeyedValue?, newValue : DJIKeyedValue?) in
                if newValue?.boolValue != nil {
                    self.isSimulatorActive = (newValue?.boolValue)!
                }
            })
        }
        
        // Google Maps
        let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
        googleMapView.camera = camera
        googleMapView.mapType = GMSMapViewType.hybrid
        
        self.waypoints = fetchWaypointsFromLocal()

        // Check Local Waypoinys Added in any previous session
        setupWaypoinys()
        
        // Check Waypoints from Firebase Database
        fetchAllWaypointsFromCloundStorage { (waypoints) in
            for wp in waypoints {

                if self.waypoints.count > 0 {
                // IF there are local Waypoints available then only add which are not here
                    var found = false
                    for wpLocal in self.waypoints {
                    
                        if wpLocal.latitude == wp.latitude && wpLocal.longitude == wp.longitude {
                        
                            found = true
                        }
                    }
                    
                    if !found {
                        self.waypoints.append(wp)
                    }
                }else{
                    // IF No Local Waypoints available then add all fropm cloud storage
                    self.waypoints.append(wp)
                }
            }
            // Draw ON Map
            self.setupWaypoinys()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        guard let connectedKey = DJIProductKey(param: DJIParamConnection) else {
            return;
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            DJISDKManager.keyManager()?.startListeningForChanges(on: connectedKey, withListener: self, andUpdate: { (oldValue: DJIKeyedValue?, newValue : DJIKeyedValue?) in
                if newValue != nil {
                    if newValue!.boolValue {
                        
                        DispatchQueue.main.async {
                            self.productConnected()
                        }
                        
                    }
                }
            })
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        VideoPreviewer.instance().setView(cameraView)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        VideoPreviewer.instance().unSetView()
        DJISDKManager.videoFeeder()?.primaryVideoFeed.remove(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func productConnected() {
        
        guard let newProduct = DJISDKManager.product() else {
            print("Product is connected but DJISDKManager.product is nil -> something is wrong")
            return;
        }
        
        //Updates the product's model
        debugLabel.text = newProduct.model!

        
        //Updates the product's firmware version - COMING SOON
        newProduct.getFirmwarePackageVersion{ (version:String?, error:Error?) -> Void in
            
            print("Firmware package version is: \(version ?? "Unknown")")
        }
        
        // Setup the camera
        camera = fetchCamera()
        
        if camera != nil {
            
            print("Setting up the camera delegate")
            
            debugLabel.text = "Debug: camera is setup"
            
            camera?.delegate = self;
        }
        
        // Setup the video feed
        DJISDKManager.videoFeeder()?.primaryVideoFeed.add(self, with: nil)
        VideoPreviewer.instance().start()
        
    }

    
    @IBAction func startSimulator(_ sender: Any) {
        
        guard let droneLocationKey = DJIFlightControllerKey(param: DJIFlightControllerParamAircraftLocation) else {
            return
        }
        
        guard let droneLocationValue = DJISDKManager.keyManager()?.getValueFor(droneLocationKey) else {
            return
        }
        
        // Get the current location of the aircraft before we launch the simulator
        let droneLocation = droneLocationValue.value as! CLLocation
        let droneCoordinates = droneLocation.coordinate
        
        if let aircraft = DJISDKManager.product() as? DJIAircraft {
            
            if self.isSimulatorActive {
                
                aircraft.flightController?.simulator?.stop(completion: nil)
                
            } else {
                
                aircraft.flightController?.simulator?.start(withLocation: droneCoordinates,
                                                            updateFrequency: 30,
                                                            gpsSatellitesNumber: 12,
                                                            withCompletion: { (error) in
                                                                if (error != nil) {
                                                                    NSLog("Error starting simulator: \(error.debugDescription)")
                                                                }
                })
            }
        }
        
    }
    
    @IBAction func shootPhoto(_ sender: Any) {
        
        let camera: DJICamera? = fetchCamera()
        
        camera!.startShootPhoto(completion: { (error) in
            
            if (error != nil) {
                print("Shoot photo error: \(error.debugDescription)")
            }
            
        })
        
    }
    
    func fetchCamera() -> DJICamera? {
        
        if DJISDKManager.product() == nil {
            return nil
        }
        
        if DJISDKManager.product() is DJIAircraft {
            return (DJISDKManager.product() as! DJIAircraft).camera
        } else if DJISDKManager.product() is DJIHandheld {
            return (DJISDKManager.product() as! DJIHandheld).camera
        }
        
        return nil
    }
    
    // Called from property observer and will trigger the segue to map view
    // Since didgeneratenewmediafile delegate is not being called
    func checkPhotoSaved() {
        
        if isStoringPhoto {
            
            print("Photo is being saved")
            
        }
        
    }
    
    @IBAction func showChecklist(_ sender: Any) {
        
    }
    
    @IBAction func startMission(_ sender: Any) {
        
        DJISDKManager.missionControl()?.scheduleElement(DJITakeOffAction())
        DJISDKManager.missionControl()?.scheduleElement(defaultWaypointMission()!)
        
        let attitude = DJIGimbalAttitude(pitch: 30.0, roll: 0.0, yaw: 0.0)
        DJISDKManager.missionControl()?.scheduleElement(DJIGimbalAttitudeAction(attitude: attitude)!)
        
        DJISDKManager.missionControl()?.startTimeline()
        
    }
    
    func defaultWaypointMission() -> DJIWaypointMission? {
        let mission = DJIMutableWaypointMission()
        mission.maxFlightSpeed = 15
        mission.autoFlightSpeed = 8
        mission.finishedAction = .noAction
        mission.headingMode = .auto
        mission.flightPathMode = .normal
        mission.rotateGimbalPitch = true
        mission.exitMissionOnRCSignalLost = true
        
        guard let droneLocationKey = DJIFlightControllerKey(param: DJIFlightControllerParamAircraftLocation) else {
            return nil
        }
        
        guard let droneLocationValue = DJISDKManager.keyManager()?.getValueFor(droneLocationKey) else {
            return nil
        }
        
        let droneLocation = droneLocationValue.value as! CLLocation 
        let droneCoordinates = droneLocation.coordinate
        
        if !CLLocationCoordinate2DIsValid(droneCoordinates) {
            return nil
        }
        
        mission.pointOfInterest = droneCoordinates
        let offset = 0.0000899322
        
        let loc1 = CLLocationCoordinate2DMake(droneCoordinates.latitude + offset, droneCoordinates.longitude)
        let waypoint1 = DJIWaypoint(coordinate: loc1)
        waypoint1.altitude = 25
        waypoint1.heading = 0
        waypoint1.actionRepeatTimes = 1
        waypoint1.actionTimeoutInSeconds = 60
        waypoint1.cornerRadiusInMeters = 5
        waypoint1.turnMode = .clockwise
        waypoint1.gimbalPitch = 0
        
        let loc2 = CLLocationCoordinate2DMake(droneCoordinates.latitude, droneCoordinates.longitude + offset)
        let waypoint2 = DJIWaypoint(coordinate: loc2)
        waypoint2.altitude = 26
        waypoint2.heading = 0
        waypoint2.actionRepeatTimes = 1
        waypoint2.actionTimeoutInSeconds = 60
        waypoint2.cornerRadiusInMeters = 5
        waypoint2.turnMode = .clockwise
        waypoint2.gimbalPitch = -90
        
        let loc3 = CLLocationCoordinate2DMake(droneCoordinates.latitude - offset, droneCoordinates.longitude)
        let waypoint3 = DJIWaypoint(coordinate: loc3)
        waypoint3.altitude = 27
        waypoint3.heading = 0
        waypoint3.actionRepeatTimes = 1
        waypoint3.actionTimeoutInSeconds = 60
        waypoint3.cornerRadiusInMeters = 5
        waypoint3.turnMode = .clockwise
        waypoint3.gimbalPitch = 0
        
        let loc4 = CLLocationCoordinate2DMake(droneCoordinates.latitude, droneCoordinates.longitude - offset)
        let waypoint4 = DJIWaypoint(coordinate: loc4)
        waypoint4.altitude = 28
        waypoint4.heading = 0
        waypoint4.actionRepeatTimes = 1
        waypoint4.actionTimeoutInSeconds = 60
        waypoint4.cornerRadiusInMeters = 5
        waypoint4.turnMode = .clockwise
        waypoint4.gimbalPitch = -90
        
        let waypoint5 = DJIWaypoint(coordinate: loc1)
        waypoint5.altitude = 29
        waypoint5.heading = 0
        waypoint5.actionRepeatTimes = 1
        waypoint5.actionTimeoutInSeconds = 60
        waypoint5.cornerRadiusInMeters = 5
        waypoint5.turnMode = .clockwise
        waypoint5.gimbalPitch = 0
        
        mission.add(waypoint1)
        mission.add(waypoint2)
        mission.add(waypoint3)
        mission.add(waypoint4)
        mission.add(waypoint5)
        
        return DJIWaypointMission(mission: mission)
    }

}

extension ViewController : DJICameraDelegate {
    
    // Make sure the photo is written to the SD card
    // This does not appears to work in SDK 4.0.1 so we're using didUpdate systemState as a workaround
    func camera(_ camera: DJICamera, didGenerateNewMediaFile newMedia: DJIMediaFile) {
        
        print("Photo was saved successfully")
        
    }
    
    func camera(_ camera: DJICamera, didUpdate systemState: DJICameraSystemState) {
        
        self.isStoringPhoto = systemState.isStoringPhoto
        
        
    }
    
}

extension ViewController : DJIVideoFeedListener {
    
    func videoFeed(_ videoFeed: DJIVideoFeed, didUpdateVideoData videoData: Data) {
        
        videoData.withUnsafeBytes {
            (ptr: UnsafePointer<UInt8>) in
            
            let mutablePointer = UnsafeMutablePointer(mutating: ptr)
            
            VideoPreviewer.instance().push(mutablePointer, length: Int32(videoData.count))
        }
    }
    
}

//MARK:- Private Methods
fileprivate extension ViewController {

    func setupWaypoinys() -> Void {
        for waypoint in self.waypoints {
            
            //ADDING MARKER ON MAP
            let coordinate = CLLocationCoordinate2DMake(waypoint.latitude, waypoint.longitude)
            let marker = GMSMarker(position: coordinate)
            marker.icon = UIImage(named: "map-marker")
            marker.map = googleMapView
            markers.append(marker)

        }
        zoomToPoints()
    }
    
    func zoomToPoints() -> Void {
        
        if markers.count == 0 {return}
        
        var bounds = GMSCoordinateBounds()
        for marker in markers
        {
            bounds = bounds.includingCoordinate(marker.position)
        }
        let update = GMSCameraUpdate.fit(bounds, withPadding: 60)
        googleMapView.animate(with: update)
    }
    
    //MARK:- Save & Fetch Wapoints Form Local
    func saveWaypoints() -> Void {
        let success = NSKeyedArchiver.archiveRootObject(waypoints, toFile: filePath)
        debugPrint(success ? "SAVED" : "ERROR IN SAVING")
    }
    
    func fetchWaypointsFromLocal() -> [WaypointModel] {
        if let array = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as? [WaypointModel] {
            return array
        }
        return []
    }

}

//MARK:- GOOGLE MAP DELEGATE
extension ViewController : GMSMapViewDelegate {

    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        
        //ADDING MARKER ON MAP
        let marker = GMSMarker(position: coordinate)
        marker.icon = UIImage(named: "map-marker")
        marker.map = googleMapView
        markers.append(marker)
        
        //SAVING WAYPOINT IN LOCAL
        let waypoint = WaypointModel(latitude: coordinate.latitude, longitude: coordinate.longitude, altitude: 27, heading: 0, actionRepeatTimes: 1, actionTimeoutInSeconds: 60, cornerRadiusInMeters: 5, turnMode: 0, gimbalPitch: 0)
        waypoints.append(waypoint)
        saveWaypoints()
        
        self.addWayPointToCloudStoraga(waypoint: waypoint)
    }
}
