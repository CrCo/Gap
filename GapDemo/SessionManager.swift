//
//  MeshDisplayManagerSpoke.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-10-25.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import MultipeerConnectivity

protocol SessionManagerDelegate : NSObjectProtocol {
    func wallDidOpenToSide()
    func wallDidCloseToSide()
}

class SessionManager : NSObject, MCSessionDelegate {
    
    var sessions: [MCSession] = []
    
    weak var delegate:  SessionManagerDelegate!
    
    func addSessionForPeer() -> MCSession? {
        let newSession = MCSession(peer: MCPeerID(displayName: UIDevice.currentDevice().name))
        newSession.delegate = self
        return newSession
    }
    
    func removeSession(session: MCSession) {
        session.disconnect()
        
        if let index = find(sessions, session) {
            sessions.removeAtIndex(index)
        } else {
            NSLog("❌: couldn't find session to remove")
        }
    }
    
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        switch (state) {
        case .Connected:
            NSLog("💏 \(peerID.displayName)")
            delegate.wallDidOpenToSide()
        case .NotConnected:
            NSLog("💔 \(peerID.displayName)")
            delegate.wallDidCloseToSide()
            removeSession(session)
        case .Connecting:
            NSLog("💗")
        }
    }
    
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        let string = NSString(data: data, encoding: NSUTF8StringEncoding)
        NSLog("Did receive data")
    }
    
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
    }
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
    }
    
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
    }
}


