//
//  DiscoveryManager.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-10-25.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import MultipeerConnectivity
import Dispatch

enum OperationMode {
    case Broadcaster
    case Listener
}

class DiscoveryManager: NSObject, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate, BallSceneDelegate  {
    
    let positionKey = "position"
    
    var browser: MCNearbyServiceBrowser!
    var advertiser: MCNearbyServiceAdvertiser!
    var session: MCSession
    let serviceType = "dft-gapdemo"
    var hubPeer: MCPeerID?
    var peerMap: [MCPeerID: MeshDisplayRole] = [MCPeerID: MeshDisplayRole]()

    init(session: MCSession) {
        self.session = session
    }
    
    var mode: OperationMode = .Listener {
        didSet {

            browser = MCNearbyServiceBrowser(peer: session.myPeerID, serviceType: serviceType);
            advertiser = MCNearbyServiceAdvertiser(peer: session.myPeerID, discoveryInfo: [positionKey: UIApplication.sharedApplication().role.rawValue], serviceType: serviceType)
            
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
    
    func convertToSide(peer: MCPeerID) -> Side? {
        switch UIApplication.sharedApplication().role {
        case .Middle:
            if let position = peerMap[peer] {
                switch position {
                case .Left: return .Left
                case .Right: return .Right
                default: break
                }
            }
        case .Right:
            if peer == hubPeer {
                return .Left
            }
        case .Left:
            if peer == hubPeer {
                return .Right
            }
        }
        return nil
    }
    
    func convertFromSide(side: Side) -> MCPeerID? {
        switch UIApplication.sharedApplication().role {
        case .Middle:
            var role: MeshDisplayRole
            switch side {
            case .Left: role = .Left
            case .Right: role = .Right
            }
            for (peer, r) in peerMap {
                if r == role {
                    return peer
                }
            }
        case .Right, .Left:
            return hubPeer
        }
        return nil
    }

    
    func browseAgain() {
        if mode == .Listener {
            browser.stopBrowsingForPeers()
            browser.startBrowsingForPeers()
            NSLog("👂")
        }
    }
    
    
    func sendNextInvitation(peerID: MCPeerID) {
        NSLog("👉 Invite \(peerID.displayName)")

        browser.invitePeer(peerID, toSession: session, withContext: nil, timeout: 0)
    }
    
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        
        peerMap[peerID] = MeshDisplayRole(rawValue: info[positionKey] as String)!

        if let peers = session.connectedPeers as? [MCPeerID] {
            if let result = find(peers, peerID) {
                //sessionManager.reset()
                NSLog("❓ Won't invite \(peerID.displayName) since it is already connected")
            } else {
                sendNextInvitation(peerID)
            }
        } else {
            sendNextInvitation(peerID)
        }
    }

    func browser(browser: MCNearbyServiceBrowser!, didNotStartBrowsingForPeers error: NSError!) {
        NSLog("Error browsing for peers: \(error)")
    }

    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
        NSLog("❓ \(peerID.displayName)")
        
        //peerMap.removeValueForKey(peerID)
    }

    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didNotStartAdvertisingPeer error: NSError!) {
        NSLog("Error advertising for peers: \(error)")
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
        
        if let peers = session.connectedPeers as? [MCPeerID] {
            if let result = find(peers, peerID) {
                //sessionManager.reset()
                NSLog("❓ superflous invitation from \(peerID.displayName)")
                invitationHandler(false, nil)
            } else {
                NSLog("👍 (no matching connections) \(peerID.displayName)")
                hubPeer = peerID
                invitationHandler(true, session)
            }
        } else {
            NSLog("👍 (no connections) \(peerID.displayName)")
            hubPeer = peerID
            invitationHandler(true, session)
        }
    }
    
    func shouldTransferBall(ball: [String: AnyObject], toSide side: Side, error: NSErrorPointer) {
        if let peer: MCPeerID = convertFromSide(side) {
            var err: NSError? = nil
            let data = NSJSONSerialization.dataWithJSONObject(ball, options: nil, error: &err)
            if err == nil {
                session.sendData(data, toPeers: [peer], withMode: MCSessionSendDataMode.Reliable, error: &err)
                if err != nil {
                    error.memory = err
                }
            } else {
               error.memory = err
            }
        } else {
            error.memory = NSError(domain: "DiscoveryManager", code: 1, userInfo: ["NSLocalizedDescription": "Could not convert side \(side.rawValue) for role \(UIApplication.sharedApplication().role.rawValue)"])
        }
    }
}
