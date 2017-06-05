//
//  WaypointModel.swift
//  DJISimulatorExample
//
//  Created by CANO-14 on 29/05/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit
struct SerializationKeys {
    static let latitude = "latitude"
    static let longitude  = "longitude"
    static let altitude = "altitude"
    static let heading   = "heading"
    static let actionRepeatTimes = "actionRepeatTimes"
    static let actionTimeoutInSeconds  = "actionTimeoutInSeconds"
    static let cornerRadiusInMeters = "cornerRadiusInMeters"
    static let turnMode   = "turnMode"
    static let gimbalPitch   = "gimbalPitch"
    static let syncedWithCloud   = "syncedWithCloud"
}

class WaypointModel: NSObject,NSCoding {

    
    var latitude: Double
    var longitude: Double
    var altitude: Float
    var heading: Float
    var actionRepeatTimes: UInt
    var actionTimeoutInSeconds: Int32
    var cornerRadiusInMeters: Float
    var turnMode: UInt
    var gimbalPitch: Float
    var syncedWithCloud: Bool = false
    
    init(latitude:Double,longitude: Double, altitude: Float, heading:Float, actionRepeatTimes:UInt,actionTimeoutInSeconds:Int32,cornerRadiusInMeters:Float,turnMode:UInt,gimbalPitch:Float,syncedWithCloud:Bool) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.heading = heading
        self.actionRepeatTimes = actionRepeatTimes
        self.actionTimeoutInSeconds = actionTimeoutInSeconds
        self.cornerRadiusInMeters = cornerRadiusInMeters
        self.turnMode = turnMode
        self.gimbalPitch = gimbalPitch
        self.syncedWithCloud = syncedWithCloud
    }
    // MARK: NSCoding
    public convenience required init?(coder aDecoder: NSCoder) {
        
        let latitude = aDecoder.decodeDouble(forKey: SerializationKeys.latitude)
        let longitude = aDecoder.decodeDouble(forKey: SerializationKeys.longitude)
        let altitude = aDecoder.decodeFloat(forKey: SerializationKeys.altitude)
        let heading = aDecoder.decodeFloat(forKey: SerializationKeys.heading)
        let actionRepeatTimes = aDecoder.decodeObject(forKey: SerializationKeys.actionRepeatTimes) as! UInt
        let actionTimeoutInSeconds = aDecoder.decodeInt32(forKey: SerializationKeys.actionTimeoutInSeconds)
        let cornerRadiusInMeters = aDecoder.decodeFloat(forKey: SerializationKeys.cornerRadiusInMeters)
        let turnMode = aDecoder.decodeObject(forKey: SerializationKeys.turnMode) as! UInt
        let gimbalPitch = aDecoder.decodeFloat(forKey: SerializationKeys.gimbalPitch)
        let syncedWithCloud = aDecoder.decodeBool(forKey: SerializationKeys.syncedWithCloud)

        self.init(latitude:latitude,longitude:longitude, altitude: altitude, heading:heading, actionRepeatTimes:actionRepeatTimes,actionTimeoutInSeconds:actionTimeoutInSeconds,cornerRadiusInMeters:cornerRadiusInMeters,turnMode:turnMode,gimbalPitch:gimbalPitch,syncedWithCloud:syncedWithCloud)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(latitude, forKey: SerializationKeys.latitude)
        aCoder.encode(longitude, forKey: SerializationKeys.longitude)
        aCoder.encode(altitude, forKey: SerializationKeys.altitude)
        aCoder.encode(heading, forKey: SerializationKeys.heading)
        aCoder.encode(actionRepeatTimes, forKey: SerializationKeys.actionRepeatTimes)
        aCoder.encode(actionTimeoutInSeconds, forKey: SerializationKeys.actionTimeoutInSeconds)
        aCoder.encode(cornerRadiusInMeters, forKey: SerializationKeys.cornerRadiusInMeters)
        aCoder.encode(turnMode, forKey: SerializationKeys.turnMode)
        aCoder.encode(gimbalPitch, forKey: SerializationKeys.gimbalPitch)
        aCoder.encode(syncedWithCloud, forKey: SerializationKeys.syncedWithCloud)
    }

    public func dictionaryRepresentation() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        
        dictionary[SerializationKeys.latitude] = latitude
        dictionary[SerializationKeys.longitude] = longitude
        dictionary[SerializationKeys.altitude] = altitude
        dictionary[SerializationKeys.heading] = heading
        dictionary[SerializationKeys.actionRepeatTimes] = actionRepeatTimes
        dictionary[SerializationKeys.actionTimeoutInSeconds] = actionTimeoutInSeconds
        dictionary[SerializationKeys.cornerRadiusInMeters] = cornerRadiusInMeters
        dictionary[SerializationKeys.turnMode] = turnMode
        dictionary[SerializationKeys.gimbalPitch] = gimbalPitch
        dictionary[SerializationKeys.syncedWithCloud] = syncedWithCloud
        
        return dictionary
    }

}
