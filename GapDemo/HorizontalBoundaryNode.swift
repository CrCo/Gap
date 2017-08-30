//
//  HorizontalBoundaryNode.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-11-11.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import SpriteKit

class HorizontalBoundaryNode: SKShapeNode {
    
    init(width: CGFloat) {
        super.init()
        
        let leftPoint = CGPoint(x: CGFloat(-ballSize - 1), y: 0)
        let rightPoint = CGPoint(x: width + CGFloat(ballSize + 1), y: 0)

        let path = CGMutablePath()
        
        path.move(to: CGPoint(x: leftPoint.x, y: leftPoint.y))
        path.addLine(to: CGPoint(x: rightPoint.x, y: rightPoint.y))

        physicsBody = SKPhysicsBody(edgeFrom: leftPoint, to: rightPoint)
        physicsBody!.isDynamic = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

