//
//  Waypoint+Firebase.swift
//  DJISimulatorExample
//
//  Created by CANO-14 on 06/06/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//
import Foundation

public struct DJIWaypoinyProducts {
  
  public static let waypointCloudSyncNonConsumable = "Waypoints123456Cloud"
  
  fileprivate static let productIdentifiers: Set<ProductIdentifier> = [DJIWaypoinyProducts.waypointCloudSyncNonConsumable]

  public static let store = IAPHelper(productIds: DJIWaypoinyProducts.productIdentifiers)
}

func resourceNameForProductIdentifier(_ productIdentifier: String) -> String? {
  return productIdentifier.components(separatedBy: ".").last
}
