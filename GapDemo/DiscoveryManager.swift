//
//  DiscoveryManager.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-10-25.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import MultipeerConnectivity

enum OperationMode {
    case Broadcaster
    case Listener
}

class DiscoveryManager: NSObject, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate  {
        
    var browser: MCNearbyServiceBrowser!
    var advertiser: MCNearbyServiceAdvertiser!
    var sessionManager: SessionManager

    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }
    
    var mode: OperationMode = .Listener {
        didSet {
            let serviceType = "dft-gapdemo"

            browser = MCNearbyServiceBrowser(peer: sessionManager.peerID, serviceType: serviceType);
            advertiser = MCNearbyServiceAdvertiser(peer: sessionManager.peerID, discoveryInfo: ["position": UIApplication.sharedApplication().role.rawValue], serviceType: serviceType)
            
            browser.delegate = self
            advertiser.delegate = self
            
            switch mode {
            case .Listener:
                browser.startBrowsingForPeers()
                advertiser.stopAdvertisingPeer()
                NSLog("👂")
            case .Broadcaster:
                advertiser.startAdvertisingPeer()
                browser.stopBrowsingForPeers()
                NSLog("🎵")
            }
        }
    }

    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        let position = info["position"] as String

            NSLog("👉 \(peerID.displayName) @ \(position)")
            browser.invitePeer(peerID, toSession: sessionManager.session, withContext: nil, timeout: 0)
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
        invitationHandler(true, sessionManager.session)
    }
}
