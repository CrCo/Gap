//
//  AppDelegate.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-10-23.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import UIKit

enum OperationMode {
    case Broadcaster
    case Listener
}

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
        
        if NSUserDefaults.standardUserDefaults().boolForKey("role") {
            vc.mode = .Listener
        } else {
            vc.mode = .Broadcaster
        }
    }
}