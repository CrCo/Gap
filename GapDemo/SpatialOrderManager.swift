//
//  SpatialOrderManager.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-11-02.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import MultipeerConnectivity
import CoreMotion

class SpatialOrderManager: NSObject {
    
    var me: MCPeerID
    var count: Int = 0
    var order: [MCPeerID] = []
    
    var leftDevice: MCPeerID? {
        get {
            if let i = find(order, me) {
                if i > 0 {
                    return order[i - 1]
                }
            }
            return nil
        }
    }
    
    var rightDevice: MCPeerID? {
        get {
            if let i = find(order, me) {
                if i < order.count - 1 {
                    return order[i + 1]
                }
            }
            return nil
        }
    }
    
    func addSpot(count: Int) {
        self.count = count
    }
    
    func removeSpot(peer: MCPeerID) {
        self.count -= 1
        if let index = find(order, peer) {
            order.removeAtIndex(index)
        }
    }
    
    func reset() {
        self.order.removeAll(keepCapacity: true)
    }

    func addInference(inference: RelativeTopologyAssertionRepresentation) {
        let left = inference.leftHandCandidate, right = inference.rightHandCandidate
        
        var indices = (left: find(order, left), right: find(order, right))
        
        if indices.left != nil && indices.right != nil {
            if indices.left > indices.right {
                order.removeAtIndex(indices.left!)
                order.removeAtIndex(indices.right!)
            } else {
                order.removeAtIndex(indices.right!)
                order.removeAtIndex(indices.left!)
            }
            indices = (left: nil, right: nil)
        }
        
        if let ri = indices.right {
            order.insert(left, atIndex: ri)
        } else if let li = indices.left {
            order.insert(right, atIndex: li + 1)
        } else {
            order.append(left)
            order.append(right)
        }
    }
    
    init(peerID: MCPeerID) {        
        me = peerID
    }
}