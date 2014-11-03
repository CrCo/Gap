//
//  Ball.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-11-01.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import UIKit

enum BallType: String {
    case Red = "red"
    case Blue = "blue"
    case Green = "green"
}

struct Ball: Serializeable {
    let type: BallType
    let position: CGPoint
    let velocity: CGVector
    
    func toJSON() -> [String: AnyObject] {
        return [
            "type": type.rawValue,
            "position": [
                "x": Float(position.x),
                "y": Float(position.y)
            ],
            "velocity": [
                "dx": Float(velocity.dx),
                "dy": Float(velocity.dy)
            ]
        ]
    }
    
    init(type: BallType, position: CGPoint, velocity: CGVector) {
        self.type = type
        self.position = position
        self.velocity = velocity
    }
    
    init(fromJSON json: [String: AnyObject]) {
        if let type = BallType(rawValue: json["type"] as String) {
            self.type = type
        } else {
            fatalError("Enum conversion of node type failed")
        }
        
        let positionJSON = json["position"] as [String: Float]
        
        self.position = CGPoint(x: CGFloat(positionJSON["x"]!), y: CGFloat(positionJSON["y"]!))
        
        let velocityJSON = json["velocity"] as [String: Float]
        
        self.velocity = CGVector(dx: CGFloat(velocityJSON["dx"]!), dy: CGFloat(velocityJSON["dy"]!))
    }
    
}