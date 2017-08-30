//
//  VerticalBoundaryNode.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-11-11.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import SpriteKit

class VerticalBoundaryNode: SKShapeNode {
    init (height: CGFloat) {
        super.init()
        
        let topPoint = CGPoint(x: 0, y: -CGFloat(ballSize - 1)), bottomPoint = CGPoint(x: 0, y: CGFloat(ballSize + 1) + height)
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: topPoint.x, y: topPoint.y))
        path.addLine(to: CGPoint(x: bottomPoint.x, y: bottomPoint.y))
        physicsBody = SKPhysicsBody(edgeFrom: topPoint, to: bottomPoint)
        physicsBody!.isDynamic = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
