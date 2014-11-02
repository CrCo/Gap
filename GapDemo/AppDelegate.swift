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

    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didChangeDefaults", name: NSUserDefaultsDidChangeNotification, object: nil)
        
        didChangeDefaults()
        
        return true
    }
    
    func didChangeDefaults() {
        var vc = window?.rootViewController as ViewController
        
        switch UIApplication.sharedApplication().role {
        case .Middle:
            vc.meshConnectionManager.mode = .Listener
        default:
            vc.meshConnectionManager.mode = .Broadcaster
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