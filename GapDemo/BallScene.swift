
//  BallScene.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-10-26.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import SpriteKit

let ballSize = 30
let initialVelocityMagnitude = 100.0

enum Side: String {
    case Left = "left"
    case Right = "right"
}

protocol BallSceneDelegate: NSObjectProtocol {
    func scene(scene: BallScene, ball: BallTransferRepresentation, didMoveOffscreen side: Side)
}

class BallScene : SKScene, SKPhysicsContactDelegate {
    
    weak var transferDelegate: BallSceneDelegate!
    var swipingNode: SKNode!
    var type: BallType
    
    var openings: (left:Bool, right: Bool) = (left:false, right: false) {
        didSet {
            self.didChangeSize(self.size)
        }
    }
    var aspectRatio: CGFloat? {
        didSet {
            let sceneHeight = 400.0

            if let a = aspectRatio {
                self.size = CGSize(width: CGFloat(sceneHeight) * a, height: CGFloat(sceneHeight))
            }
        }
    }
    
    var sortFieldActive: Bool = false {
        didSet {
            if sortFieldActive {
                moveNodesToGraph()
            } else {
                enumerateChildNodesWithName("ball") { (node, stop) -> Void in
                    node.removeActionForKey("move")
                    node.physicsBody!.velocity = self.randomVelocity()
                }
            }
        }
    }
    
    init(type: BallType) {
        self.type = type
        super.init(size: CGSize(width: 0, height: 0))
        self.backgroundColor = SKColor.whiteColor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func moveNodesToGraph() {
        var graphHeight = [0,0,0]
        enumerateChildNodesWithName("ball") { (node, stop) -> Void in
            node.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            
            let colorIndex: Int = find([BallType.Communication, BallType.User, BallType.Finance], (node as! BallNode).type)!
            let width = Int(self.size.width)
            let point = CGPoint(x: CGFloat(width / 2 + (colorIndex - 1) * ballSize * 2), y: CGFloat(ballSize + ballSize * 2 * graphHeight[colorIndex]))
            
            node.runAction(SKAction.moveTo(point, duration: 0.4), withKey: "move")
            graphHeight[colorIndex]++
        }
    }
    
    func randomVelocity() -> CGVector {
        let angle = Double(arc4random()) / Double(UInt32.max) * M_PI * 2
        return CGVector(dx: Int(initialVelocityMagnitude * sin(angle)), dy: Int(initialVelocityMagnitude * cos(angle)))
    }
    
    func randomPoint() -> CGPoint {
        let x = Int(arc4random_uniform(UInt32(self.frame.width - CGFloat(2 * ballSize))))
        let y = Int(arc4random_uniform(UInt32(self.frame.height - CGFloat(2 * ballSize))))
        return CGPoint(x: x + ballSize, y: y + ballSize)
    }
    
    override func didChangeSize(oldSize: CGSize) {
        
        let children = [self.childNodeWithName("left"), self.childNodeWithName("right"), self.childNodeWithName("top"), childNodeWithName("bottom")]
        
        removeChildrenInArray(children.filter { return $0 != nil } .map { $0! })
        
        var left: SKNode
        if openings.left {
            left = SKEmitterNode(fileNamed: "EdgeMagic")
        } else {
            left = VerticalBoundaryNode(height: size.height)
        }
        left.name = "left"
        left.position = CGPoint(x: -1, y: 0)
        addChild(left)

        var right: SKNode
        if openings.right {
            right = SKEmitterNode(fileNamed: "EdgeMagic")
        } else {
            right = VerticalBoundaryNode(height: size.height)
        }
        right.position = CGPoint(x: size.width+1, y: 0)
        right.name = "right"
        addChild(right)

        let top = HorizontalBoundaryNode(width: size.width)
        top.position = CGPoint(x: 0, y: -1)
        top.name = "top"
        addChild(top)

        let bottom = HorizontalBoundaryNode(width: size.width)
        bottom.position = CGPoint(x: 0, y: self.size.height+1)
        bottom.name = "bottom"
        addChild(bottom)
    }
    
    override func didMoveToView(view: SKView) {
        let panGS = UIPanGestureRecognizer(target:self, action: Selector("didPan:"))
        view.addGestureRecognizer(panGS)
        
        let longGS = UILongPressGestureRecognizer(target: self, action: Selector("didHold:"))
        view.addGestureRecognizer(longGS)
        
        for i in 1...2 {
            let node = BallNode(type: type)
            node.position = randomPoint()
            addChild(node)
            node.physicsBody!.velocity = randomVelocity()
        }
    }
    
    override func update(currentTime: NSTimeInterval) {
        
        self.enumerateChildNodesWithName("ball") { (node, shouldStop) -> Void in
            
            let node = node as! BallNode
            
            if node.position.x > self.frame.width + CGFloat(ballSize) {
                if  self.openings.right {
                    //send on its way
                    self.transferDelegate.scene(self, ball: node.ballRepresentation(.Right), didMoveOffscreen: .Right)
                    node.removeFromParent()
                } else {
                    //this guy is trapped on the wrong side of the wall
                    self.resetBall(node, attemptedSide: .Right)
                }
            } else if node.position.x < -CGFloat(ballSize) {
                if  self.openings.left {
                    //send on its way
                    self.transferDelegate.scene(self, ball: node.ballRepresentation(.Left), didMoveOffscreen: .Left)
                    node.removeFromParent()
                } else {
                    //this guy is trapped on the wrong side of the wall
                    self.resetBall(node, attemptedSide: .Left)
                }
            }
        }
    }
    
    //MARK: public
    func addNode(ball: BallTransferRepresentation) {
        var positionX: CGFloat
        
        switch ball.direction {
        case .Left:
            positionX = self.size.width + CGFloat(ballSize)
        case .Right:
            positionX = -CGFloat(ballSize)
        }
        
        let node = BallNode(type: ball.type)
        node.position = CGPoint(x:positionX, y:ball.position.y)
        
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.addChild(node)
            if self.sortFieldActive {
                self.moveNodesToGraph()
            } else {
                node.physicsBody!.velocity = ball.velocity
            }
        }
    }
    
    func resetBall(node: SKNode, attemptedSide side: Side) {
        switch side {
        case .Left:
            node.position.x = CGFloat(ballSize)
        case .Right:
            node.position.x = self.frame.width - CGFloat(ballSize)
        }
        
        node.physicsBody?.velocity.dx = -node.physicsBody!.velocity.dx
    }
    
    //MARK: Touch delegate
    
    func didHold(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .Began: sortFieldActive = true
        case .Ended, .Cancelled: sortFieldActive = false
        default: break
        }
    }
    
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
            
            if node.name == "ball" {
                node.physicsBody!.dynamic = false
                swipingNode = node as SKNode
                //Center based on where it was grabbed
                node.position = point
            } else {
                let tests = [(x, dx), (Double(self.size.width) - x, -dx), (y, dy), (Double(self.size.height) - y, -dy)]
                if tests.filter({ $0.0 < 20 && $0.1 > 25 }).count > 0 {
                    swipingNode = BallNode(type: type)
                    swipingNode.position = position
                    addChild(swipingNode)
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