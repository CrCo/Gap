//
//  MeshDisplayManagerSpoke.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-10-25.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import MultipeerConnectivity

enum Side: String {
    case Left = "left"
    case Right = "right"
}

protocol SessionManagerDelegate : NSObjectProtocol {
    func wallDidOpenToSide(Side)
    func wallDidCloseToSide(Side)
    func shouldAddNewNode(data: [String: AnyObject], fromSide side: Side)
}

enum SessionManagerState {
    case Connecting
    case Connected
    case Disconnected
}

class SessionManager : NSObject, MCSessionDelegate {
    var state: SessionManagerState = .Disconnected
    var discoveryManager: DiscoveryManager
    weak var delegate:  SessionManagerDelegate!

    init(discoveryManager: DiscoveryManager) {
        self.discoveryManager = discoveryManager
        super.init()
    }
    
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        switch (state) {
        case .Connected:
            self.state = .Connected
            NSLog("💏 \(peerID.displayName)")
            
            if let side = discoveryManager.convertToSide(peerID) {
                delegate.wallDidOpenToSide(side)
            }
            switch UIApplication.sharedApplication().role {
            case .Middle:
                if session.connectedPeers.count == 2 {
                    NSLog("❌👂")
                discoveryManager.browser.stopBrowsingForPeers()
                }
            default:
                if peerID == discoveryManager.hubPeer! {
                    NSLog("❌🎵")
                    discoveryManager.advertiser.stopAdvertisingPeer()
                }
            }
        case .NotConnected:
            NSLog("💔 \(peerID.displayName)")

            
            switch UIApplication.sharedApplication().role {
            case .Middle:
                //Helps to have a delay
                //NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: "enableBrowser", userInfo: nil, repeats: false)
                enableBrowser()
            default:
                if peerID == discoveryManager.hubPeer! {
                    NSLog("🎵")
                    discoveryManager.advertiser.startAdvertisingPeer()
                }
            }
            
            self.state = .Disconnected
        
            if let side = discoveryManager.convertToSide(peerID) {
                delegate.wallDidCloseToSide(side)
            }

        case .Connecting:
            self.state = .Connecting
            NSLog("💗")
        }
    }
    
    func enableBrowser () {
        NSLog("👂")
        discoveryManager.browser.startBrowsingForPeers()

    }
    
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        let string = NSString(data: data, encoding: NSUTF8StringEncoding)
        
        var err: NSError? = nil
        let obj = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &err) as [String: AnyObject]
        if err == nil {
            if let side = discoveryManager.convertToSide(peerID) {
                delegate.shouldAddNewNode(obj, fromSide: side)
            }
        }
    }
    
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
    }
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
    }
    
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
    }
}


