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
    func scene(scene: BallScene, ball: BallTransferRepresentation, didMoveOffscreen side: Side)
}

class BallScene : SKScene, SKPhysicsContactDelegate {
    
    weak var transferDelegate: BallSceneDelegate!
    
    var finger: SKFieldNode!
    var openings: (left:Bool, right: Bool) = (left:false, right: false) {
        didSet {
            self.didChangeSize(self.size)
        }
    }
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
    
    func changeBallType(type: BallType) {
        enumerateChildNodesWithName("ball") { (node, stop) -> Void in
            let n = node as SKShapeNode
            n.fillColor = self.colorForType(type)
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
    
    func createVerticalBoundary() -> SKNode {
        let pointA = CGPoint(x: 0, y: -ballSize)
        let pointB = CGPoint(x: 0, y: self.size.height + ballSize)
        var points = [pointA, pointB]
        let node = SKShapeNode(points: &points, count: 2)
        node.strokeColor = SKColor.redColor()
        let physicsBody = SKPhysicsBody(edgeFromPoint: pointA, toPoint: pointB)
        physicsBody.dynamic = false
        node.physicsBody = physicsBody
        return node
    }
    
    func createHorizontalBoundary() -> SKNode {
        let pointA = CGPoint(x: -ballSize, y: 0)
        let pointB = CGPoint(x: self.size.height + ballSize, y: 0)
        var points = [pointA, pointB]
        let node = SKShapeNode(points: &points, count: 2)
        node.strokeColor = SKColor.redColor()
        let physicsBody = SKPhysicsBody(edgeFromPoint: pointA, toPoint: pointB)
        physicsBody.dynamic = false
        node.physicsBody = physicsBody
        return node
    }

    override func didChangeSize(oldSize: CGSize) {
        
        let children = [self.childNodeWithName("left"), self.childNodeWithName("right"), self.childNodeWithName("top"), childNodeWithName("bottom")]
        
        self.removeChildrenInArray(children.filter { return $0 != nil } .map { $0! })
        
        if !openings.left {
            let left = createVerticalBoundary()
            left.position = CGPoint(x: 0, y: 0)
            left.name = "left"
            self.addChild(left)
        }
        
        if !openings.right {
            let right = createVerticalBoundary()
            right.position = CGPoint(x: self.size.width, y: 0)
            right.name = "right"
            self.addChild(right)
        }
            
        let top = createHorizontalBoundary()
        top.position = CGPoint(x: 0, y: 0)
        top.name = "top"
        self.addChild(top)

        let bottom = createHorizontalBoundary()
        bottom.position = CGPoint(x: 0, y: self.size.height)
        bottom.name = "bottom"
        self.addChild(bottom)
    }
    
    override func didMoveToView(view: SKView) {
        for i in 1...2 {
            _addNode(generateRandomBall())
        }
    }
    
    func generateRandomBall() -> BallTransferRepresentation {
        let randomPosition = CGPoint(x: Int(arc4random_uniform(UInt32(self.frame.width))), y: Int(arc4random_uniform(UInt32(self.frame.height))))
        let randomVelocity = CGVector(dx: Int(arc4random_uniform(400)) - 200, dy: Int(arc4random_uniform(400)) - 200)
        
        return BallTransferRepresentation(type: type, position: randomPosition, velocity: randomVelocity)
    }
    
    func addNode(ball: BallTransferRepresentation) {
        var positionX: CGFloat
        
        if ball.velocity.dx < 0 {
            //Moving left
            positionX = self.size.width + 30
        } else {
            //Moving right
            positionX = -30
        }
        
        _addNode(BallTransferRepresentation(type: ball.type, position: CGPoint(x:positionX, y:ball.position.y), velocity: ball.velocity))
    }
    
    func colorForType(type: BallType) -> SKColor {
        switch type {
        case .Green: return SKColor.greenColor()
        case .Blue: return SKColor.blueColor()
        case .Red: return SKColor.redColor()
        }
    }
    
    func _addNode(ball: BallTransferRepresentation) {
        var color: SKColor = colorForType(ball.type)
        
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
    
    override func update(currentTime: NSTimeInterval) {
        
        self.enumerateChildNodesWithName("ball") { (node, shouldStop) -> Void in
            if node.position.x > self.frame.width + ballSize {
                if  self.openings.right {
                    //send on its way
                    self.moveNode(node, toSide: .Right)
                } else {
                    //this guy is trapped on the wrong side of the wall
                    self.resetBall(node, attemptedSide: .Right)
                }
            } else if node.position.x < -ballSize {
                if  self.openings.left {
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
            
            let ball = BallTransferRepresentation(type:type, position: node.position, velocity: v)
            
            transferDelegate.scene(self, ball: ball, didMoveOffscreen: side)
            node.removeFromParent()
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