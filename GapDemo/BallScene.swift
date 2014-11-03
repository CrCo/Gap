//
//  BallScene.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-10-26.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import SpriteKit

let ballSize : CGFloat = 30.0
let height: CGFloat = 400

enum Side: String {
    case Left = "left"
    case Right = "right"
}

protocol BallSceneDelegate: NSObjectProtocol {
    func scene(scene: BallScene, ball: Ball, didMoveOffscreen side: Side)
}

class BallScene : SKScene, SKPhysicsContactDelegate {
    
    weak var transferDelegate: BallSceneDelegate!
    
    var gates: (top: SKNode, right: SKNode, bottom: SKNode, left:SKNode)?
    var finger: SKFieldNode!
    
    var aspectRatio: CGFloat? {
        didSet {
            if let a = aspectRatio {
                self.size = CGSize(width: height * a, height: height)
            }
        }
    }
    
    var type: BallType

    init(type: BallType) {
        self.type = type
        
        super.init(size: CGSize(width: height, height: height))
        
        physicsWorld.contactDelegate = self
        self.backgroundColor = SKColor.whiteColor()
        finger = SKFieldNode.springField()
        finger.strength = -0.7
        finger.falloff = 0.0000001
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func moveNodesToGraph() {
        var graphHeight = [0,0,0]
        enumerateChildNodesWithName("ball") { (node, stop) -> Void in
            node.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            
            let colorIndex: Int = find([SKColor.greenColor(), SKColor.blueColor(), SKColor.redColor()], (node as SKShapeNode).fillColor)!
            let width = Int(self.size.width)
            let point = CGPoint(x: CGFloat(width / 2 + (colorIndex - 1) * 30 * 2), y: CGFloat(30 + 30 * 2 * graphHeight[colorIndex]))
            
            node.runAction(SKAction.moveTo(point, duration: 0.4), withKey: "move")
            graphHeight[colorIndex]++
        }
    }
    
    var sortFieldActive: Bool = false {
        didSet {
            if sortFieldActive {
                moveNodesToGraph()
            } else {
                enumerateChildNodesWithName("ball") { (node, stop) -> Void in
                    node.removeActionForKey("move")
                    node.physicsBody!.velocity = CGVector(dx: Int(arc4random_uniform(400)) - 200, dy: Int(arc4random_uniform(400)) - 200)
                }
            }
        }
    }
    
    override func didChangeSize(oldSize: CGSize) {
        var openGates = (top:false, left: false, bottom: false, right:false)
        
        if let g = gates {
            openGates.left = g.left.parent == nil
            openGates.right = g.right.parent == nil
            openGates.top = g.top.parent == nil
            openGates.bottom = g.bottom.parent == nil
            if !openGates.left { g.left.removeFromParent() }
            if !openGates.right { g.right.removeFromParent() }
            if !openGates.top { g.top.removeFromParent() }
            if !openGates.bottom { g.bottom.removeFromParent() }
        }
        
        func createBoundaryBetween(pointA: CGPoint, andPoint pointB: CGPoint) -> SKNode {
            var points = [pointA, pointB]
            let node = SKShapeNode(points: &points, count: 2)
            node.name = "wall"
            node.strokeColor = SKColor.redColor()
            let physicsBody = SKPhysicsBody(edgeFromPoint: pointA, toPoint: pointB)
            physicsBody.dynamic = false
            node.physicsBody = physicsBody
            return node
        }
        
        gates = (
            top: createBoundaryBetween(
                CGPoint(x: -ballSize, y: self.size.height),
                andPoint: CGPoint(x: self.size.width + ballSize, y: self.size.height)
            ),
            right: createBoundaryBetween(
                CGPoint(x: self.size.width, y: self.size.height + ballSize),
                andPoint: CGPoint(x: self.frame.width, y: -ballSize)
            ),
            bottom: createBoundaryBetween(
                CGPoint(x: -ballSize, y: 0),
                andPoint: CGPoint(x: self.size.width + ballSize, y: 0)
            ),
            left: createBoundaryBetween(
                CGPoint(x: 0, y: self.size.height + ballSize),
                andPoint: CGPoint(x: 0, y: -ballSize)
            )
        )
        
        if let g = gates {
            if !openGates.left { self.addChild(g.left) }
            if !openGates.right { self.addChild(g.right) }
            if !openGates.top { self.addChild(g.top) }
            if !openGates.bottom { self.addChild(g.bottom) }
        }
    }
    
    func setGate(node: SKNode, toOpen open: Bool ) {
        if (open) {
            node.runAction(SKAction.removeFromParent())
        } else {
            if node.parent == nil {
                self.addChild(node)
            }
        }
    }
    
    override func didMoveToView(view: SKView) {
        for i in 1...2 {
            self.addNode(generateRandomBall())
        }
    }
    
    func generateRandomBall() -> Ball {
        let randomPosition = CGPoint(x: Int(arc4random_uniform(UInt32(self.frame.width))), y: Int(arc4random_uniform(UInt32(self.frame.height))))
        let randomVelocity = CGVector(dx: Int(arc4random_uniform(400)) - 200, dy: Int(arc4random_uniform(400)) - 200)
        
        return Ball(type: type, position: randomPosition, velocity: randomVelocity)
    }
    
    func addNode(ball: Ball) {
        
        var color: SKColor
        switch ball.type {
        case .Green: color = SKColor.greenColor()
        case .Blue: color = SKColor.blueColor()
        case .Red: color = SKColor.redColor()
        }
        
        var node = SKShapeNode(circleOfRadius: ballSize)
        node.strokeColor = SKColor.clearColor()
        node.fillColor = color
        node.position = ball.position
        node.name = "ball"
        
        let body = SKPhysicsBody(circleOfRadius: ballSize)
        body.affectedByGravity = false
        body.friction = 0
        body.linearDamping = 0.0
        body.restitution = 1.0
        
        node.physicsBody = body
        self.addChild(node)
        
        body.velocity = ball.velocity
    }
    
    func setPhysicsBodyOpenings(left:Bool, right:Bool) {
        NSLog("open left \(left) or right \(right)")
        if let leftGate = self.gates?.left {
            self.setGate(leftGate, toOpen: left)
        }
        if let rightGate = self.gates?.right {
            self.setGate(rightGate, toOpen: right)
        }
    }
    
    override func update(currentTime: NSTimeInterval) {
        
        self.enumerateChildNodesWithName("ball") { (node, shouldStop) -> Void in
            if node.position.x > self.frame.width + ballSize {
                if  self.gates?.right.parent == nil {
                    //send on its way
                    self.moveNode(node, toSide: .Right)
                } else {
                    //this guy is trapped on the wrong side of the wall
                    self.resetBall(node, attemptedSide: .Right)
                }
            } else if node.position.x < -ballSize && self.gates?.left.parent == nil {
                if  self.gates?.left.parent == nil {
                    //send on its way
                    self.moveNode(node, toSide: .Left)
                } else {
                    //this guy is trapped on the wrong side of the wall
                    self.resetBall(node, attemptedSide: .Left)
                }
            }
        }
    }
    
    private func moveNode(node: SKNode, toSide side: Side) {
        if let v = node.physicsBody?.velocity {
            var type: BallType
            
            switch (node as SKShapeNode).fillColor {
            case SKColor.greenColor(): type = .Green
            case SKColor.blueColor(): type = .Blue
            case SKColor.redColor(): type = .Red
            default: fatalError("Node doesn't have normal colour")
            }
            
            var position = node.position
            switch side {
            case .Left:
                position.x = self.frame.width + ballSize
            case .Right:
                position.x = -ballSize
            }
            
            let ball = Ball(type:type, position: position, velocity: v)
            
            var err: NSError? = nil
            transferDelegate.scene(self, ball: ball, didMoveOffscreen: side)
            if err == nil {
                NSLog("🎾 from \(side.rawValue)")
                node.runAction(SKAction.removeFromParent())
            } else {
                NSLog("❌🎾 from \(side.rawValue): \(err?.localizedDescription)")
                resetBall(node, attemptedSide: side)
            }
        }
    }
    
    func resetBall(node: SKNode, attemptedSide side: Side) {
        switch side {
        case .Left:
            node.position.x = ballSize
        case .Right:
            node.position.x = self.frame.width - ballSize
        }
        
        node.physicsBody?.velocity.dx = -node.physicsBody!.velocity.dx
    }

    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        let touch = touches.anyObject() as UITouch
        finger.position = touch.locationInNode(self)
        self.addChild(finger)
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        let touch = touches.anyObject() as UITouch
        finger.position = touch.locationInNode(self)
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        finger.runAction(SKAction.removeFromParent())
    }
}