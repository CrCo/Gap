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
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        let vc = window!.rootViewController as! ViewController
        vc.meshConnectionManager.disconnect()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        let vc = window!.rootViewController as! ViewController
        vc.meshConnectionManager.reconnect()
    }
}
