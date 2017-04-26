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
    
    let bridgeMode = true
    let bridgeIP = "10.0.1.18"
    
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
        
        DJISDKManager.registerApp(with: self)
        
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
                
                self.batteryLabel.text = "Battery: \(newValue!.unsignedIntegerValue) %"
                
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
    override func viewWillAppear(_ animated: Bool) {
        
        guard let connectedKey = DJIProductKey(param: DJIParamConnection) else {
            return;
        }
        
        
        DJISDKManager.keyManager()?.startListeningForChanges(on: connectedKey, withListener: self, andUpdate: { (oldValue: DJIKeyedValue?, newValue : DJIKeyedValue?) in
            if newValue != nil {
                if newValue!.boolValue {
                    
                    // At this point, a product is connected so we can show it.
                    print("we are in here")
                    self.productConnected()
                    
                }
            }
        })
        
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
            print("Connecting via bridge")
            
        } else {
            
            DJISDKManager.startConnectionToProduct()
            
        }
        
    }
    
}
