//
//  SpatialOrderManager.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-11-02.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import MultipeerConnectivity

class SpatialOrderManager: NSObject {
    
    var deviceOrder: [MCPeerID]?
    var me: MCPeerID
    
    var leftDevice: MCPeerID? {
        get {
            if let order = deviceOrder {
                if let index = find(order, me) {
                    if index > 0 {
                        return order[index - 1]
                    }
                }
            }
            return nil
        }
    }
    
    var rightDevice: MCPeerID? {
        get {
            if let order = deviceOrder {
                if let index = find(order, me) {
                    if index < order.count - 1 {
                        return order[index + 1]
                    }
                }
            }
            return nil
        }
    }
    
    func reset() {
        self.deviceOrder = nil
    }
    
    init(peerID: MCPeerID) {
        me = peerID
    }
}