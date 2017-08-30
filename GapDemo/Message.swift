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
        let tempArray = aDecoder.decodeObject(forKey: "topology") as! [MCPeerID]
        
        var newArray = [MCPeerID]()
        
        for peer in tempArray {
            newArray.append(peer)
        }
        
        self.topology = newArray
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(topology, forKey: "topology")
    }
}

class RelativeTopologyAssertionRepresentation: NSObject, NSCoding {
    let side: Side
    
    init(side: Side) {
        self.side = side
    }
    
    required init(coder aDecoder: NSCoder) {
        self.side = Side(rawValue: aDecoder.decodeObject(forKey: "side") as! String)!
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(side.rawValue, forKey: "side")
    }
}

enum BallType: Int {
    case finance = 0
    case communication = 1
    case user = 2
}

class BallTransferRepresentation: NSObject, NSCoding {
    let type: BallType
    let position: CGPoint
    let velocity: CGVector
    let direction: Side
    
    init(type: BallType, position: CGPoint, velocity: CGVector, direction: Side)  {
        self.type = type
        self.position = position
        self.direction = direction
        self.velocity = velocity
    }
    
    required init(coder aDecoder: NSCoder) {
        type = BallType(rawValue: aDecoder.decodeObject(forKey: "type") as! Int)!
        position = aDecoder.decodeCGPoint(forKey: "position")
        velocity = aDecoder.decodeCGVector(forKey: "velocity")
        direction = Side(rawValue: aDecoder.decodeObject(forKey: "direction") as! String)!
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(type.rawValue, forKey: "type")
        aCoder.encode(position, forKey: "position")
        aCoder.encode(velocity, forKey: "velocity")
        aCoder.encode(direction.rawValue, forKey: "direction")
    }
}

class RelativePositionRequest: NSObject, NSCoding {
    
    override init() {
    }

    required init(coder aDecoder: NSCoder) {
    }
    
    func encode(with aCoder: NSCoder) {
    }
}
