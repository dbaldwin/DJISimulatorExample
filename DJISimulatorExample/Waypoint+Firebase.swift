//
//  Waypoint+Firebase.swift
//  DJISimulatorExample
//
//  Created by CANO-14 on 30/05/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//

import Foundation
import FirebaseDatabase
import UIKit

extension ViewController {

    // ADD WAYPOINT IN FIREBASE SERVER
    func addWayPointToCloudStoraga(waypoint:WaypointModel) -> Void {
        let waypointRef = ref.child("users").child("\(userID!)").child("waypoints").childByAutoId()
        waypointRef.child(SerializationKeys.latitude).setValue(waypoint.latitude)
        waypointRef.child(SerializationKeys.longitude).setValue(waypoint.longitude)
        waypointRef.child(SerializationKeys.altitude).setValue(waypoint.altitude)
        waypointRef.child(SerializationKeys.heading).setValue(waypoint.heading)
        waypointRef.child(SerializationKeys.actionRepeatTimes).setValue(waypoint.actionRepeatTimes)
        waypointRef.child(SerializationKeys.actionTimeoutInSeconds).setValue(waypoint.actionTimeoutInSeconds)
        waypointRef.child(SerializationKeys.cornerRadiusInMeters).setValue(waypoint.cornerRadiusInMeters)
        waypointRef.child(SerializationKeys.turnMode).setValue(waypoint.turnMode)
        waypointRef.child(SerializationKeys.gimbalPitch).setValue(waypoint.gimbalPitch)
    }
    
    //FETCH ALL WAYPOINTS FROM FIREBASE SERVER
    func fetchAllWaypointsFromCloundStorage(completion:@escaping (([WaypointModel])->Void)){

        let waypointRef = ref.child("users").child("\(userID!)").child("waypoints")
        waypointRef.observeSingleEvent(of: DataEventType.value, with: { (snapshot) in

            var waypoints : [WaypointModel] = []
            
           if let snapDic = snapshot.value as? NSDictionary
           {
            for child in snapDic
            {
            
                let childDic = child.value as? NSDictionary

                let waypoint = WaypointModel(latitude: childDic?[SerializationKeys.latitude] as? Double ?? 0, longitude: childDic?[SerializationKeys.longitude] as? Double ?? 0, altitude: childDic?[SerializationKeys.altitude] as? Float ?? 0, heading: childDic?[SerializationKeys.heading] as? Float ?? 0, actionRepeatTimes: UInt(childDic?[SerializationKeys.actionRepeatTimes] as? Int ?? 0), actionTimeoutInSeconds: childDic?[SerializationKeys.actionTimeoutInSeconds] as? Int32 ?? 0, cornerRadiusInMeters: childDic?[SerializationKeys.cornerRadiusInMeters] as? Float ?? 0, turnMode: UInt(childDic?[SerializationKeys.turnMode] as? Int ?? 0), gimbalPitch: childDic?[SerializationKeys.gimbalPitch] as? Float ?? 0)
                waypoints.append(waypoint)
            }
        }
            completion(waypoints)
            
        })

    }
    
}
