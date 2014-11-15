//
//  SpatialOrderManager.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-11-02.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import MultipeerConnectivity
import CoreMotion


protocol OrderStorage {
    func left() -> MCPeerID?
    func right() -> MCPeerID?
}

class SpatialOrderManager: NSObject, OrderStorage {
    
    var me: MCPeerID
    var count: Int = 0
    
    var leftDevice: MCPeerID?
    var rightDevice: MCPeerID?
    
    var order: [MCPeerID] {
        get {
            let _a: [MCPeerID?] = [leftDevice, me, rightDevice]
            
            return _a.filter { $0 != nil } .map { $0! }
        }
        set {
            leftDevice = newValue[0]
            rightDevice = newValue[1]
        }
    }
    
    func removeSpot(peer: MCPeerID) {
        if leftDevice == peer {
            leftDevice = nil
        }
        
        if rightDevice == peer {
            rightDevice = nil
        }
    }
    
    func reset() {
        self.leftDevice = nil
        self.rightDevice = nil
    }
    
    func left() -> MCPeerID? {
        return leftDevice
    }

    func right() -> MCPeerID? {
        return rightDevice
    }

    func addInference(inference: RelativeTopologyAssertionRepresentation, forPeer peer: MCPeerID) {
        switch inference.side {
        case .Left: leftDevice = peer
        case .Right: rightDevice = peer
        }
    }
    
    override var description: String {
        get {
            return  "|".join(order.map { $0.displayName })
        }
    }
    
    
    init(peerID: MCPeerID) {        
        me = peerID
    }
}

class SpatialOrderContainer: NSObject, OrderStorage {
    
    var order: [MCPeerID] = [MCPeerID]()
    var me: MCPeerID
    
    init(me: MCPeerID) {
        self.me = me
    }
    
    func clear() {
        order.removeAll(keepCapacity: true)
    }
    
    func left() -> MCPeerID? {
        if let index = find(order, me) {
            if index > 0 {
                return order[index - 1]
            }
        }
        return nil
    }
    
    func right() -> MCPeerID? {
        if let index = find(order, me) {
            if index < order.count - 1 {
                return order[index + 1]
            }
        }
        return nil
    }
}