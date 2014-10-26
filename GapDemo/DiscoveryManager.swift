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
    
    let positionKey = "position"
    
    var browser: MCNearbyServiceBrowser!
    var advertiser: MCNearbyServiceAdvertiser!
    var sessionManager: SessionManager
    let serviceType = "dft-gapdemo"


    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }
    
    var mode: OperationMode = .Listener {
        didSet {

            browser = MCNearbyServiceBrowser(peer: sessionManager.peerID, serviceType: serviceType);
            advertiser = MCNearbyServiceAdvertiser(peer: sessionManager.peerID, discoveryInfo: [positionKey: UIApplication.sharedApplication().role.rawValue], serviceType: serviceType)
            
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
    
    func browseAgain() {
        if mode == .Listener {
            browser.stopBrowsingForPeers()
            browser = MCNearbyServiceBrowser(peer: sessionManager.peerID, serviceType: serviceType);
            browser.delegate = self
            browser.startBrowsingForPeers()
            NSLog("👂")
        }
    }

    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        
        let position = info[positionKey] as String
        
        NSLog("👉 (no connections with peer) \(peerID.displayName) @ \(position)")
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
        
        if let peers = sessionManager.session.connectedPeers as? [MCPeerID] {
            if let result = find(peers, peerID) {
                sessionManager.reset()
                NSLog("👍 (after flushing the session) \(peerID.displayName)")
                invitationHandler(true, sessionManager.session)
            } else {
                NSLog("👍 (no matching connections) \(peerID.displayName)")
                invitationHandler(true, sessionManager.session)
            }
        } else {
            NSLog("👍 (no connections) \(peerID.displayName)")
            invitationHandler(true, sessionManager.session)
        }
    }
}
