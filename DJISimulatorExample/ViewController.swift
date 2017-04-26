//
//  ViewController.swift
//  DJISimulatorExample
//
//  Created by Dennis Baldwin on 4/25/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit
import DJISDK
import GoogleMaps

class ViewController: UIViewController {
    
    @IBOutlet weak var googleMapView: GMSMapView!
    
    var aircraftMarker: GMSMarker!
    
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
    
    
    @IBOutlet weak var locationLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Start listening for aircraft location updates
        let locationKey = DJIFlightControllerKey(param: DJIFlightControllerParamAircraftLocation)
        DJISDKManager.keyManager()?.startListeningForChanges(on: locationKey!, withListener: self, andUpdate: { (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
            if newValue != nil {
                // DJIFlightControllerParamAircraftLocation is associated with a DJISDKLocation object
                let aircraftCoordinates = newValue!.value! as! DJISDKLocation
                
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
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
        print("Model: \((newProduct.model)!)")
        
        //Updates the product's firmware version - COMING SOON
        newProduct.getFirmwarePackageVersion{ (version:String?, error:Error?) -> Void in
            
            print("Firmware package version is: \(version ?? "Unknown")")
        }
        
        //Updates the product's connection status
        print("Product Connected")
    }
    
    func productDisconnected() {
        
        print("Product disconnected")
        
    }

    
    @IBAction func startSimulator(_ sender: Any) {
        
        guard let droneLocationKey = DJIFlightControllerKey(param: DJIFlightControllerParamAircraftLocation) else {
            return
        }
        
        guard let droneLocationValue = DJISDKManager.keyManager()?.getValueFor(droneLocationKey) else {
            return
        }
        
        // Get the current location of the aircraft before we launch the simulator
        let droneLocation = droneLocationValue.value as! DJISDKLocation
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

}
