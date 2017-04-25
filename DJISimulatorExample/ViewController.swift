//
//  ViewController.swift
//  DJISimulatorExample
//
//  Created by Dennis Baldwin on 4/25/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit
import DJISDK

class ViewController: UIViewController {
    
    let bridgeMode = false
    let bridgeIP = "10.0.1.20"
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

    @IBOutlet weak var batteryLabel: UILabel!
    
    @IBOutlet weak var simulatorButton: UIButton!
    
    
    @IBOutlet weak var locationLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Start listening for aircraft location updates
        let locationKey = DJIFlightControllerKey(param: DJIFlightControllerParamAircraftLocation)
        DJISDKManager.keyManager()?.startListeningForChanges(on: locationKey!, withListener: self, andUpdate: { (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
            if newValue != nil {
                // DJIFlightControllerParamAircraftLocation is associated with a DJISDKLocation object
                let aircraftCoordinates = newValue!.value! as! DJISDKLocation
                
                self.locationLabel.text = "Lat: \(aircraftCoordinates.coordinate.latitude) - Lng: \(aircraftCoordinates.coordinate.longitude)"
                
            }
        })
        
        // Start listening for battery updates
        let batteryLevelKey = DJIBatteryKey(param: DJIBatteryParamChargeRemainingInPercent)
        DJISDKManager.keyManager()?.startListeningForChanges(on: batteryLevelKey!, withListener: self, andUpdate: { (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
            
            if newValue != nil {
                
                self.batteryLabel.text = "\(newValue!.unsignedIntegerValue) %"
                
            }
            
            
        })
        
        // Listen for simulator status updates
        if let isSimulatorActiveKey = DJIFlightControllerKey(param: DJIFlightControllerParamIsSimulatorActive) {
            DJISDKManager.keyManager()?.startListeningForChanges(on: isSimulatorActiveKey, withListener: self, andUpdate: { (oldValue: DJIKeyedValue?, newValue : DJIKeyedValue?) in
                if newValue?.boolValue != nil {
                    self.isSimulatorActive = (newValue?.boolValue)!
                }
            })
        }
    }
    
    // App registration
    override func viewDidAppear(_ animated: Bool) {
        
        DJISDKManager.registerApp(with: self)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

extension ViewController: DJISDKManagerDelegate {
    
    func appRegisteredWithError(_ error: Error?) {
     
        if (error != nil) {
            
            print("Registration error \(error?.localizedDescription)")
            
        } else {
            
            print("Registration success")
            
        }
        
        
        if bridgeMode {
            
            DJISDKManager.enableBridgeMode(withBridgeAppIP: bridgeIP)
            
        } else {
            
            DJISDKManager.startConnectionToProduct()
            
        }
        
    }
    
}
