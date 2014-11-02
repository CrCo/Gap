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

enum Side: String {
    case Left = "left"
    case Right = "right"
}

protocol MeshConnectionManagerDelegate : NSObjectProtocol {
    func wallDidOpenToSide(Side)
    func wallDidCloseToSide(Side)
    func shouldAddNewNode(data: [String: AnyObject], fromSide side: Side)
}

class MeshConnectionManager: NSObject, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate  {
    
    let positionKey = "position"
    
    weak var delegate:  MeshConnectionManagerDelegate!
    
    var browser: MCNearbyServiceBrowser
    var advertiser: MCNearbyServiceAdvertiser
    var session: MCSession = MCSession(peer: MCPeerID(displayName: UIDevice.currentDevice().name))

    let serviceType = "dft-gapdemo"
    var hubPeer: MCPeerID?
    var peerMap: [MCPeerID: MeshDisplayRole] = [MCPeerID: MeshDisplayRole]()
    
    
    var mode: OperationMode = .Listener {
        didSet {
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


    override init() {
        browser = MCNearbyServiceBrowser(peer: session.myPeerID, serviceType: serviceType);
        advertiser = MCNearbyServiceAdvertiser(peer: session.myPeerID, discoveryInfo: [positionKey: UIApplication.sharedApplication().role.rawValue], serviceType: serviceType)
        
        super.init()
        
        browser.delegate = self
        advertiser.delegate = self
        session.delegate = self
    }
    
    //MARK: utility
    
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
    
    func invitePeer(peerID: MCPeerID) {
        NSLog("👉 Invite \(peerID.displayName)")
        browser.invitePeer(peerID, toSession: session, withContext: nil, timeout: 0)
    }
    
    //MARK: Public members
    
    func browseAgain() {
        if mode == .Listener {
            browser.stopBrowsingForPeers()
            browser.startBrowsingForPeers()
            NSLog("👂")
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
    
    //MARK: Browser delegate
    
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        
        peerMap[peerID] = MeshDisplayRole(rawValue: info[positionKey] as String)!

        if let peers = session.connectedPeers as? [MCPeerID] {
            if let result = find(peers, peerID) {
                //sessionManager.reset()
                NSLog("❓ Won't invite \(peerID.displayName) since it is already connected")
            } else {
                invitePeer(peerID)
            }
        } else {
            invitePeer(peerID)
        }
    }

    func browser(browser: MCNearbyServiceBrowser!, didNotStartBrowsingForPeers error: NSError!) {
        NSLog("Error browsing for peers: \(error)")
    }

    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
        NSLog("❓ \(peerID.displayName)")
        
        //peerMap.removeValueForKey(peerID)
    }
    
    //MARK: Advertiser delegate

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
    
    //MARK: Session Delegate
    
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        switch (state) {
        case .Connected:
            NSLog("💏 \(peerID.displayName)")
            
            if let side = self.convertToSide(peerID) {
                delegate.wallDidOpenToSide(side)
            }
            switch UIApplication.sharedApplication().role {
            case .Middle:
                if session.connectedPeers.count == 2 {
                    NSLog("❌👂")
                    self.browser.stopBrowsingForPeers()
                }
            default:
                if peerID == self.hubPeer! {
                    NSLog("❌🎵")
                    self.advertiser.stopAdvertisingPeer()
                }
            }
        case .NotConnected:
            NSLog("💔 \(peerID.displayName)")
            
            switch UIApplication.sharedApplication().role {
            case .Middle:
                //Helps to have a delay
                NSLog("👂")
                self.browser.startBrowsingForPeers()
            default:
                if peerID == self.hubPeer! {
                    NSLog("🎵")
                    self.advertiser.startAdvertisingPeer()
                }
            }
            
            if let side = self.convertToSide(peerID) {
                delegate.wallDidCloseToSide(side)
            }
            
        case .Connecting:
            NSLog("💗")
        }
    }
    
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        let string = NSString(data: data, encoding: NSUTF8StringEncoding)
        
        var err: NSError? = nil
        let obj = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &err) as [String: AnyObject]
        if err == nil {
            if let side = self.convertToSide(peerID) {
                delegate.shouldAddNewNode(obj, fromSide: side)
            }
        }
    }
    
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
        fatalError("Shouldn't receive resource")
    }
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
        fatalError("Shouldn't receive stream")
    }
    
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
        fatalError("Shouldn't receive resource")
    }
}
