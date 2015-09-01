//
//  AppDelegate.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-10-23.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        let vc = window!.rootViewController as! ViewController
        vc.meshConnectionManager.disconnect()
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        let vc = window!.rootViewController as! ViewController
        vc.meshConnectionManager.reconnect()
    }
}
