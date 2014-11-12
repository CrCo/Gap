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
        
        let leftPoint = CGPoint(x: -ballSize-1, y: 0)
        let rightPoint = CGPoint(x: width + ballSize + 1, y: 0)

        let _path = CGPathCreateMutable()
        
        CGPathMoveToPoint(_path, nil, leftPoint.x, leftPoint.y)
        CGPathAddLineToPoint(_path, nil, rightPoint.x, rightPoint.y)
        
        path = _path
        
        physicsBody = SKPhysicsBody(edgeFromPoint: leftPoint, toPoint: rightPoint)
        physicsBody!.dynamic = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

