//
//  MeshDisplayManagerSpoke.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-10-25.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import MultipeerConnectivity

protocol SessionManagerDelegate : NSObjectProtocol {
    func wallDidOpenToSide(side: SpatialPosition)
    func wallDidCloseToSide(side: SpatialPosition)
}

class SessionManager : NSObject, MCSessionDelegate {
    
    var session: MCSession?
    
    weak var delegate:  SessionManagerDelegate!
    
    func addSessionForPeer(peerID: MCPeerID, atPosition position: SpatialPosition) -> MCSession? {
        NSLog("The position is \(position.rawValue)")
        session = MCSession(peer: MCPeerID(displayName: UIDevice.currentDevice().name))
        return session
    }
    
    
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        switch (state) {
        case .Connected:
            NSLog("💏 \(peerID.displayName)")
            delegate.wallDidOpenToSide(session.position)
        case .NotConnected:
            NSLog("💔 \(peerID.displayName)")
            delegate.wallDidCloseToSide(session.position)
            //removeSession(session)
        case .Connecting:
            NSLog("💗")
        }
    }

    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        let string = NSString(data: data, encoding: NSUTF8StringEncoding)
        NSLog("Got message: \(string)")
    }
    
    
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
    }
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
    }
    
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
    }
    
}


