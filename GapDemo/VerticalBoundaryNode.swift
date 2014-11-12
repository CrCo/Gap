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
        
        let topPoint = CGPoint(x: 0, y: -ballSize-1), bottomPoint = CGPoint(x: 0, y: height + ballSize + 1)
        
        let _path = CGPathCreateMutable()

        CGPathMoveToPoint(_path, nil, topPoint.x, topPoint.y)
        CGPathAddLineToPoint(_path, nil, bottomPoint.x, bottomPoint.y)
        
        path = _path

        physicsBody = SKPhysicsBody(edgeFromPoint: topPoint, toPoint: bottomPoint)
        physicsBody!.dynamic = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
