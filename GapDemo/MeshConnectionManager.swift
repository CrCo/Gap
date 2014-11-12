//
//  DiscoveryManager.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-10-25.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import MultipeerConnectivity

protocol MeshConnectionManagerDelegate : NSObjectProtocol {
    func peer(peer: MCPeerID, sentMessage: AnyObject)
    func peerDidConnect(peer: MCPeerID)
    func peerDidDisconnect(peer: MCPeerID)
    func peerIsConnecting(peer: MCPeerID)
}

enum OperationMode {
    case Broadcaster
    case Listener
}

class MeshConnectionManager: NSObject, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate  {
    
    var mode: OperationMode? {
        didSet {
            if let m = mode {
                shouldResetOperatingMode(m)
            }
        }
    }
    
    weak var delegate:  MeshConnectionManagerDelegate!
    
    var browser: MCNearbyServiceBrowser
    var advertiser: MCNearbyServiceAdvertiser
    var session: MCSession
    let serviceType = "dft-gapdemo"
    var hubPeer: MCPeerID?
    
    init(peer: MCPeerID) {
        session = MCSession(peer: peer)
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: serviceType);
        advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: serviceType)
        
        super.init()
        
        browser.delegate = self
        advertiser.delegate = self
        session.delegate = self
        
    }
    
    //MARK: utility
    
    func shouldResetOperatingMode(mode: OperationMode) {
        switch mode {
        case .Listener:
            browser.stopBrowsingForPeers()
            browser.startBrowsingForPeers()
            advertiser.stopAdvertisingPeer()
            NSLog("👂")
        case .Broadcaster:
            advertiser.stopAdvertisingPeer()
            advertiser.startAdvertisingPeer()
            browser.stopBrowsingForPeers()
            NSLog("🎵")
        }
    }

    func disconnect() {
        session.disconnect()
    }
    
    //MARK: Public members
    
    func sendMessage(message: AnyObject, toPeers peers: [MCPeerID], error: NSErrorPointer) {
        var err: NSError?
        let data = NSKeyedArchiver.archivedDataWithRootObject(message)

        session.sendData(data, toPeers: peers, withMode: MCSessionSendDataMode.Reliable, error: &err)
        if err != nil {
            error.memory = err
        }
    }
    
    //MARK: Browser delegate
    
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        
        NSLog("👉 Invite \(peerID.displayName)")
        
        browser.invitePeer(peerID, toSession: session, withContext: nil, timeout: 0)
        delegate.peerIsConnecting(peerID)
    }

    func browser(browser: MCNearbyServiceBrowser!, didNotStartBrowsingForPeers error: NSError!) {
        NSLog("Error browsing for peers: \(error)")
    }

    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
        NSLog("❓ \(peerID.displayName)")
    }
    
    //MARK: Advertiser delegate

    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didNotStartAdvertisingPeer error: NSError!) {
        NSLog("Error advertising for peers: \(error)")
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
        
        NSLog("👍 \(peerID.displayName)")

        hubPeer = peerID
        invitationHandler(true, session)
        delegate.peerIsConnecting(peerID)
    }
    
    //MARK: Session Delegate
    
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        switch (state) {
        case .Connected:
            NSLog("💏 \(peerID.displayName)")
            
            delegate.peerDidConnect(peerID)
            
            //TODO: if a certain number of peers are connected, the caller should disable ranging
        case .NotConnected:
            NSLog("💔 \(peerID.displayName)")
            
            if let m = mode {
                shouldResetOperatingMode(m)
            }
            
            delegate.peerDidDisconnect(peerID)
        case .Connecting:
            NSLog("💗")
        }
    }
    
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        
        let obj: AnyObject? = NSKeyedUnarchiver.unarchiveObjectWithData(data)
        
        if let o: AnyObject = obj {
            delegate.peer(peerID, sentMessage:o)
        } else {
            NSLog("Object wasn't deserialized properly")
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
