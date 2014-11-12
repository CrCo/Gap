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
    let leftHandCandidate: MCPeerID
    let rightHandCandidate: MCPeerID
    
    init(leftHandCandidate: MCPeerID, rightHandCandidate: MCPeerID) {
        self.leftHandCandidate = leftHandCandidate
        self.rightHandCandidate = rightHandCandidate

    }
    
    required init(coder aDecoder: NSCoder) {
        self.leftHandCandidate = aDecoder.decodeObjectForKey("left") as MCPeerID
        self.rightHandCandidate = aDecoder.decodeObjectForKey("right") as MCPeerID
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(leftHandCandidate, forKey: "left")
        aCoder.encodeObject(rightHandCandidate, forKey: "right")
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

enum ContactType: String {
    case Passive = "passive"
    case Initiation = "initiation"
}

class ContactEvent: NSObject, NSCoding {
    
    let contactType: ContactType
    let contactSide: Side?
    
    init(initiationWithContactDirection contactDirection: Side) {
        self.contactType = .Initiation
        self.contactSide = contactDirection
    }

    override init() {
        self.contactType = .Passive
    }
    
    required init(coder aDecoder: NSCoder) {
        contactType = ContactType(rawValue: aDecoder.decodeObjectForKey("type") as String)!
        
        if let side =  aDecoder.decodeObjectForKey("side") as String? {
            contactSide = Side(rawValue:side)!
        }
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(contactType.rawValue, forKey: "type")
        if let side = contactSide {
            aCoder.encodeObject(side.rawValue, forKey: "side")
        }
    }
    
    override var description: String {
        get {
            if self.contactType == .Initiation {
                switch self.contactSide! {
                case .Left: return "💥👈"
                case .Right:  return "💥👉"
                }
            } else {
                return "💥✋"
            }
        }
    }
}