//
//  AppDelegate.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-10-23.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import UIKit
import MultipeerConnectivity


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var session: SessionManager!
    var discoveryManager: DiscoveryManager!
    var window: UIWindow?
    var serviceBrowser: MCNearbyServiceBrowser?
    var serviceAdvertiser: MCNearbyServiceAdvertiser?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        session = SessionManager()
        discoveryManager = DiscoveryManager(sessionManager: session)
        
        let vc = window?.rootViewController as ViewController
        session.delegate = vc
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didChangeDefaults", name: NSUserDefaultsDidChangeNotification, object: nil)
        
        didChangeDefaults()
        
        return true
    }
    
    func didChangeDefaults() {
        switch UIApplication.sharedApplication().role {
        case .Middle:
            discoveryManager.mode = .Listener
        default:
            discoveryManager.mode = .Broadcaster
        }
    }
}


enum MeshDisplayRole : String {
    case Left = "left"
    case Right = "right"
    case Middle = "middle"
}

extension UIApplication {
    
    var role: MeshDisplayRole {
        get {
            let positionSettings = NSUserDefaults.standardUserDefaults().stringForKey("position")
            
            switch positionSettings {
            case let stringVal where stringVal == MeshDisplayRole.Middle.rawValue:
                return .Middle
            case let stringVal where stringVal == MeshDisplayRole.Right.rawValue:
                return .Right
            case let stringVal where stringVal == MeshDisplayRole.Left.rawValue:
                //Default is left
                fallthrough
            default:
                return .Left
            }
        }
    }
}