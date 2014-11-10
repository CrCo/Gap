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
    
    var type: BallType {
        get {
            return BallType(rawValue: NSUserDefaults.standardUserDefaults().integerForKey("type") as Int)!
        }
        set {
            NSUserDefaults.standardUserDefaults().setInteger(newValue.rawValue, forKey: "type")
            changeBallType(newValue)
        }
    }

    override init() {
        
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
        let pointB = CGPoint(x: self.size.width + ballSize, y: 0)
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
            left.position = CGPoint(x: -1, y: 0)
            left.name = "left"
            self.addChild(left)
        }
        
        if !openings.right {
            let right = createVerticalBoundary()
            right.position = CGPoint(x: self.size.width+1, y: 0)
            right.name = "right"
            self.addChild(right)
        }
            
        let top = createHorizontalBoundary()
        top.position = CGPoint(x: 0, y: -1)
        top.name = "top"
        self.addChild(top)

        let bottom = createHorizontalBoundary()
        bottom.position = CGPoint(x: 0, y: self.size.height+1)
        bottom.name = "bottom"
        self.addChild(bottom)
    }
    
    override func didMoveToView(view: SKView) {
        let panGS = UIPanGestureRecognizer(target:self, action: "didPan:")
        view.addGestureRecognizer(panGS)
        
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
    
    func createNode(position: CGPoint) -> SKShapeNode {
        var color: SKColor = colorForType(type)
        
        var node = SKShapeNode(circleOfRadius: ballSize)
        node.strokeColor = SKColor.clearColor()
        node.fillColor = color
        node.position = position
        node.name = "ball"
        
        let body = SKPhysicsBody(circleOfRadius: ballSize)
        body.affectedByGravity = false
        body.dynamic = false
        body.friction = 0
        body.linearDamping = 0.0
        body.restitution = 1.0
        
        node.physicsBody = body
        self.addChild(node)
        return node
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
    
    //MARK: Touch delegate
    var swipingNode: SKShapeNode!
    
    func didPan(gesture: UIPanGestureRecognizer) {
        let v = self.view!
        
        let _location = gesture.locationInView(v)
        
        let x = Double(_location.x * self.size.width / v.frame.width)
        let y = Double((v.frame.height - _location.y) * self.size.height / v.frame.height)
        
        let _velocity =  gesture.velocityInView(v)
        
        let dx = Double(_velocity.x * self.size.width / v.frame.width)
        let dy = Double(-_velocity.y * self.size.height / v.frame.height)

        
        switch gesture.state {
        case .Began:
            let point = CGPoint(x:x, y:y)
            let node = self.nodeAtPoint(point)
            
            if node != self {
                node.physicsBody!.dynamic = false
                swipingNode = node as SKShapeNode
                //Center based on where it was grabbed
                node.position = point
            } else {
                let tests = [(x, dx), (Double(self.size.width) - x, -dx), (y, dy), (Double(self.size.height) - y, -dy)]
                if tests.filter({ $0.0 < 10 && $0.1 > 25 }).count > 0 {
                    swipingNode = self.createNode(point)
                }
            }
        case .Changed:
            if let sn = swipingNode {
                let location = gesture.locationInView(v)
                
                let yPos = (v.frame.height - location.y) * self.size.height / v.frame.height
                let xPos = location.x * self.size.width / v.frame.width
                sn.position = CGPoint(x: xPos, y: yPos)
            }
        case .Ended, .Cancelled:
            if let sn = swipingNode {
                let physicsBody = sn.physicsBody!
                
                physicsBody.dynamic = true
                
                let velocityPoint =  gesture.velocityInView(v)
                let dx = velocityPoint.x * self.size.width / v.frame.width
                let dy = -velocityPoint.y * self.size.height / v.frame.height
                
                physicsBody.velocity = CGVector(dx: dx, dy: dy)
            }
            swipingNode = nil
        default:
            break
        }
    }

}