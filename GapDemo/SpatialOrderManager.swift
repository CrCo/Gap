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

    func addInference(inference: RelativeTopologyAssertionRepresentation) {
        let left = inference.leftHandCandidate, right = inference.rightHandCandidate
        
        let leftIndex = find(order, left), rightIndex = find(order, right)
        
        if leftIndex != nil && rightIndex != nil {
            fatalError("Both already have inferred locations -- not possible")
        }
        
        if let ri = rightIndex {
            order.insert(left, atIndex: ri)
        } else if let li = leftIndex {
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