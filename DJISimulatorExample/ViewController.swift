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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Start listening for battery updates
        let batteryLevelKey = DJIBatteryKey(param: DJIBatteryParamChargeRemainingInPercent)
        DJISDKManager.keyManager()?.getValueFor(batteryLevelKey!, withCompletion: { [unowned self] (value: DJIKeyedValue?, error: Error?) in
            guard error == nil && value != nil else {
                
                self.batteryLabel.text = "Error";
                return
                
            }
            
            // DJIBatteryParamChargeRemainingInPercent is associated with a uint8_t value
            self.batteryLabel.text = "\(value!.unsignedIntegerValue) %"
            
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
                                                                    NSLog("Start Simulator Error: \(error.debugDescription)")
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
