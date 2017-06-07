//
//  Waypoint+IAP.swift
//  DJISimulatorExample
//
//  Created by Canopus on 6/6/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//

import Foundation
import StoreKit
extension ViewController {

    // FETCH PRODUCTS FROM ITUNES
    func reload() {
        DJIWaypoinyProducts.store.requestProducts{success, products in
            if success {
                if (products?.count ?? 0)! > 0 {
                    self.product = products?.first
                    if self.canPurchaseNow {
                        self.buy(product: self.product!)
                    }
                }else{
                    self.showAlert(title: "Message", message: "Could not fetch product info at moment, please try again later.")
                }
            }else{
                self.showAlert(title: "Message", message: "Could not fetch product info at moment, please try again later.")
            }
        }
    }
    
    // NOTIFICATION AFTER PRODUCT PURCHASED
    func handlePurchaseNotification(_ notification: Notification) {
        guard let productID = notification.object as? String else { return }
        if DJIWaypoinyProducts.store.isProductPurchased(productID) {
            self.showAlert(title: "Message", message: "Product purchased successfully.")
            self.buttonSaveWaypoints.isEnabled = true
            self.buttonBuy.isHidden = true
            self.buttonRestore.isHidden = true

        }else{
            self.showAlert(title: "Message", message: "Could Not Purchase At moment, please try again later.")
        }
    }
    
    // BUY 
    func buy(product:SKProduct) {
        DJIWaypoinyProducts.store.buyProduct(product)
    }
}

