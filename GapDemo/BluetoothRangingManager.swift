//
//  BluetoothRangingManager.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-11-11.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import CoreLocation
import UIKit

class BluetoothRangingManager: NSObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager!
    var mode: OperationMode
    
    init(mode: OperationMode) {
        self.mode = mode
        
        super.init()
        
        switch(CLLocationManager.authorizationStatus()) {
        case .Authorized:
            initializeManager()
        case .Restricted, .Denied:
            showFailureMessage()
        default:
            initializeManager()
            locationManager.requestAlwaysAuthorization()
        }

    }

    func initializeManager () {
        locationManager = CLLocationManager()
        locationManager.delegate = self
    }
    
    func showFailureMessage() {
        UIAlertView(title: "Oh no", message: "You need to allow background monitoring", delegate: self, cancelButtonTitle: "Ok")
    }

    func startMonitoring() {
        if (CLLocationManager.isRangingAvailable()) {
            
            let uuid = NSUUID(UUIDString: " 8DEEFBB9-F738-4297-8040-96668BB44281")
            let region = CLBeaconRegion(proximityUUID: uuid, identifier: "Roximity")
            region.notifyEntryStateOnDisplay = true;
            locationManager?.startMonitoringForRegion(region)
            
            NSLog("Is authorized, starting the monitoring")
        } else {
            showFailureMessage()
        }
    }

    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if (status == CLAuthorizationStatus.Authorized) {
            startMonitoring()
        }
    }
    
    func locationManager(manager: CLLocationManager!, didDetermineState state: CLRegionState, forRegion region: CLRegion!) {
        NSLog("In range, start ranging")
        locationManager?.startRangingBeaconsInRegion(region as CLBeaconRegion)
    }
    
    func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
        if ((beacons.filter { $0.proximity == CLProximity.Immediate }).count > 0) {
            NSLog("In range")
        }
    }
}