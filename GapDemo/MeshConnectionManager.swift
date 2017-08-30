//
//  DiscoveryManager.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-10-25.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import MultipeerConnectivity

protocol MeshConnectionManagerDelegate : NSObjectProtocol {
    func peer(_ peer: MCPeerID, sentMessage: AnyObject)
    func peerDidConnect(_ peer: MCPeerID)
    func peerDidDisconnect(_ peer: MCPeerID)
    func peerIsConnecting(_ peer: MCPeerID)
}

enum OperationMode {
    case broadcaster
    case listener
}


extension NSObject{
    func find(_ array:[BallType],_ obj:BallType)-> Int?{
        for (index,obj1) in array.enumerated(){
            if (obj1 == obj){
                return index
            }
        }
        return nil
        
    }
    func find(_ array:[MCPeerID],_ obj:MCPeerID)-> Int?{
        for (index,obj1) in array.enumerated(){
            if (obj1 == obj){
                return index
            }
        }
        return nil
        
    }
}

class MeshConnectionManager: NSObject, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate  {
   

    
    var mode: OperationMode? {
        didSet {
            if let m = mode {
                shouldResetOperatingMode(m)
            }
        }
    }
    
    var side: Side
    weak var delegate:  MeshConnectionManagerDelegate!
    
    var browser: MCNearbyServiceBrowser
    var advertiser: MCNearbyServiceAdvertiser
    var session: MCSession
    var hubPeer: MCPeerID?
    
    init(peer: MCPeerID, side: Side) {
        let serviceType = "dft-gapdemo"
        self.side = side
        session = MCSession(peer: peer)
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: serviceType);
        advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: serviceType)
        super.init()
        browser.delegate = self
        advertiser.delegate = self
        session.delegate = self
    }
    
    //MARK: utility
    
    func shouldResetOperatingMode(_ mode: OperationMode) {
        switch mode {
        case .listener:
            browser.stopBrowsingForPeers()
            browser.startBrowsingForPeers()
            advertiser.stopAdvertisingPeer()
            NSLog("👂")
        case .broadcaster:
            advertiser.stopAdvertisingPeer()
            advertiser.startAdvertisingPeer()
            browser.stopBrowsingForPeers()
            NSLog("🎵")
        }
    }

    func disconnect() {
        session.disconnect()
    }
    
    func reconnect() {
        if let h = hubPeer {
            if find(session.connectedPeers , h) == nil {
                NSLog("🎵")
                advertiser.startAdvertisingPeer()
            }
        }
    }
    
    //MARK: Public members
    
    func sendMessage(_ message: AnyObject, toPeers peers: [MCPeerID], error: NSErrorPointer) {
      
        let data = NSKeyedArchiver.archivedData(withRootObject: message)

        do {
            try session.send(data, toPeers: peers.filter { find(self.session.connectedPeers , $0) != nil }, with: .reliable)
            
        } catch let error {
            print("  error:",error.localizedDescription)
        }
        
    
    }
    
    //MARK: Browser delegate
    
   public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?){
        
        if find(session.connectedPeers as! [MCPeerID], peerID) != nil {
            NSLog("❌👉 Already connected to \(peerID.displayName)")
        } else {
            NSLog("👉 Invite \(peerID.displayName)")
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 0)
            delegate.peerIsConnecting(peerID)
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser!, didNotStartBrowsingForPeers error: NSError!) {
        NSLog("Error browsing for peers: \(error)")
    }

    func browser(_ browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
        NSLog("❓ \(peerID.displayName)")
    }
    
    //MARK: Advertiser delegate

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser!, didNotStartAdvertisingPeer error: NSError!) {
        NSLog("Error advertising for peers: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: Data!, invitationHandler: ((Bool, MCSession?) -> Void)!) {
        
        NSLog("👍 \(peerID.displayName)")

        hubPeer = peerID
        invitationHandler(true, session)
        delegate.peerIsConnecting(peerID)
    }
    
    //MARK: Session Delegate
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch (state) {
        case .connected:
            NSLog("💏 \(peerID.displayName)")
            
            switch mode! {
            case .broadcaster:
                if peerID == hubPeer {
                    NSLog("❌🎵")
                    advertiser.stopAdvertisingPeer()
                }
            case .listener:
                if session.connectedPeers.count == 2 {
                    NSLog("❌👂")
                    browser.stopBrowsingForPeers()
                }
            }
            
            delegate.peerDidConnect(peerID)
            
            //TODO: if a certain number of peers are connected, the caller should disable ranging
        case .notConnected:
            NSLog("💔 \(peerID.displayName)")
            
            switch mode! {
            case .broadcaster:
                if UIApplication.shared.applicationState == .active {
                    reconnect()
                }
            case .listener:
                NSLog("👂")
                browser.startBrowsingForPeers()
            }
            
            delegate.peerDidDisconnect(peerID)
        case .connecting:
            NSLog("💗")
        }
    }
    
    func session(_ session: MCSession!, didReceive data: Data, fromPeer peerID: MCPeerID!) {
        
        let obj: AnyObject? = NSKeyedUnarchiver.unarchiveObject(with: data) as AnyObject
        
        if let o: AnyObject = obj {
            delegate.peer(peerID, sentMessage:o)
        } else {
            NSLog("Object wasn't deserialized properly")
        }
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        fatalError("Shouldn't receive resource")
    }
    
    func session(_ session: MCSession!, didReceive stream: InputStream, withName streamName: String!, fromPeer peerID: MCPeerID!) {
        fatalError("Shouldn't receive stream")
    }
    
    func session(_ session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, with progress: Progress) {
        fatalError("Shouldn't receive resource")
    }
}
