//
//  BallNode.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-11-11.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import SpriteKit

class BallNode: SKSpriteNode {
    
    var type: BallType
    
    init(type: BallType) {
        
        self.type = type
        
        var name: String
        switch type {
        case .finance: name = "Dollar"
        case .communication: name = "Message"
        case .user: name = "UserSprite"
        }
        
        super.init(texture: SKTexture(imageNamed: name), color: SKColor.clear, size: CGSize(width: ballSize*2, height: ballSize*2))
        
        texture?.generatingNormalMap()
        
        self.name = "ball"
        
        let body = SKPhysicsBody(circleOfRadius: CGFloat(ballSize))
        body.affectedByGravity = false
        body.friction = 0
        body.linearDamping = 0.0
        body.restitution = 1.0
        
        physicsBody = body
    }
    
    func ballRepresentation(_ direction: Side) -> BallTransferRepresentation {
        return BallTransferRepresentation(type:type, position: position, velocity: physicsBody!.velocity, direction: direction)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Don't call")
    }
}

