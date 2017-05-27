//
//  ProductCommunicationManager.swift
//  DJISimulatorExample
//
//  Created by Dennis Baldwin on 4/26/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit
import DJISDK

class ProductCommunicationManager: NSObject {
    
    let enableBridgeMode = false
    let bridgeAppIP = "10.0.1.18"
    
    func registerWithSDK() {
        
        DJISDKManager.registerApp(with: self)
        
    }
    
}

extension ProductCommunicationManager : DJISDKManagerDelegate {
    
    func appRegisteredWithError(_ error: Error?) {
        
        if enableBridgeMode {
            
            DJISDKManager.enableBridgeMode(withBridgeAppIP: bridgeAppIP)
            
        } else {
            
            DJISDKManager.startConnectionToProduct()
            
        }
        
    }
    
    func productConnected(_ product: DJIBaseProduct?) {
        
    }
    
    func productDisconnected() {
        
    }
    
    func componentConnected(withKey key: String?, andIndex index: Int) {
        
    }
    
    func componentDisconnected(withKey key: String?, andIndex index: Int) {
        
    }
}

