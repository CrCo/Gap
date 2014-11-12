//
//  Request.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-11-02.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import MultipeerConnectivity

class GlobalTopologyDefinitionRepresentation: NSCoder, NSCoding {
    let topology: [MCPeerID]
    
    init(topology: [MCPeerID]) {
        self.topology = topology
    }
    
    required init(coder aDecoder: NSCoder) {
        let tempArray = aDecoder.decodeObjectForKey("topology") as [MCPeerID]
        
        var newArray = [MCPeerID]()
        
        for peer in tempArray {
            newArray.append(peer)
        }
        
        self.topology = newArray
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(topology, forKey: "topology")
    }
}

class RelativeTopologyAssertionRepresentation: NSObject, NSCoding {
    let side: Side
    
    init(side: Side) {
        self.side = side
    }
    
    required init(coder aDecoder: NSCoder) {
        self.side = Side(rawValue: aDecoder.decodeObjectForKey("side") as String)!
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(side.rawValue, forKey: "side")
    }
}

enum BallType: Int {
    case Finance = 0
    case Communication = 1
    case User = 2
}

class BallTransferRepresentation: NSObject, NSCoding {
    let type: BallType
    let position: CGPoint
    let velocity: CGVector
    
    init(type: BallType, position: CGPoint, velocity: CGVector)  {
        self.type = type
        self.position = position
        self.velocity = velocity
    }
    
    required init(coder aDecoder: NSCoder) {
        type = BallType(rawValue: aDecoder.decodeObjectForKey("type") as Int)!
        position = aDecoder.decodeCGPointForKey("position")
        velocity = aDecoder.decodeCGVectorForKey("velocity")
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(type.rawValue, forKey: "type")
        aCoder.encodeCGPoint(position, forKey: "position")
        aCoder.encodeCGVector(velocity, forKey: "velocity")
    }
}

class RelativePositionRequest: NSObject, NSCoding {
    
    override init() {
    }

    required init(coder aDecoder: NSCoder) {
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
    }
}