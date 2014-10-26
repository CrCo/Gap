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
class AppDelegate: UIResponder, UIApplicationDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {

    let SERVICE_TYPE = "dft-gapdemo"
    let PeerID = MCPeerID(displayName: UIDevice.currentDevice().name)
    
    var window: UIWindow?
    var serviceBrowser: MCNearbyServiceBrowser?
    var serviceAdvertiser: MCNearbyServiceAdvertiser?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didChangeDefaults", name: NSUserDefaultsDidChangeNotification, object: nil)
        
        didChangeDefaults()
        
        return true
    }
    
    func didChangeDefaults() {
        switch UIApplication.sharedApplication().operationMode {
        case .Listener:
            serviceBrowser = MCNearbyServiceBrowser(peer: PeerID, serviceType: SERVICE_TYPE);
            serviceBrowser?.delegate = self
            serviceBrowser?.startBrowsingForPeers()
            
            //If settings changed, ensure other mode is stopped
            serviceAdvertiser?.stopAdvertisingPeer()
            NSLog("👂")
        case .Broadcaster:
            serviceAdvertiser = MCNearbyServiceAdvertiser(peer: PeerID, discoveryInfo: nil, serviceType: SERVICE_TYPE)
            serviceAdvertiser?.delegate = self
            serviceAdvertiser?.startAdvertisingPeer()
            
            //If settings changed, ensure other mode is stopped
            serviceBrowser?.stopBrowsingForPeers()
            NSLog("🎵")
        }
    }

    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        NSLog("👉 \(peerID.displayName)")
        browser.invitePeer(peerID, toSession: sessionManager.addSessionForPeer(peerID, atPosition: .Right), withContext: nil, timeout: 0)
    }
    
    func browser(browser: MCNearbyServiceBrowser!, didNotStartBrowsingForPeers error: NSError!) {
        NSLog("Error browsing for peers: \(error)")
    }
    
    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
        NSLog("❓ \(peerID.displayName)")
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didNotStartAdvertisingPeer error: NSError!) {
        NSLog("Error advertising for peers: \(error)")
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
        NSLog("👍 \(peerID.displayName)")
        
        invitationHandler(true, sessionManager.addSessionForPeer(peerID, atPosition: .Left))
    }
    
    var sessionManager: SessionManager {
        get {
            let vc = window?.rootViewController as ViewController
            return vc.sessionManager
        }
    }
}

enum OperationMode {
    case Broadcaster
    case Listener
}

extension UIApplication {
    var operationMode: OperationMode {
        get {
            let positionSettings = NSUserDefaults.standardUserDefaults().stringForKey("position")
            
            switch positionSettings {
            case let stringVal where stringVal == "middle":
                return .Listener
            default:
                return .Broadcaster
            }
        }
    }
}