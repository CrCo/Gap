//
//  ViewController.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-10-23.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import SpriteKit

class ViewController: UIViewController, MeshConnectionManagerDelegate, BallSceneDelegate, MotionManagerDelegate, UIGestureRecognizerDelegate {
    
    var me: MCPeerID {
        get {
            let def = NSUserDefaults.standardUserDefaults()
                        
            if let data = def.objectForKey("me") as NSData? {
                return NSKeyedUnarchiver.unarchiveObjectWithData(data) as MCPeerID
            } else {
                let newPeer = MCPeerID(displayName: UIDevice.currentDevice().name)
                def.setObject(NSKeyedArchiver.archivedDataWithRootObject(newPeer), forKey: "me")
                return newPeer
            }
        }
    }
    
    var motionHandlingQueue = NSOperationQueue()
    
    var receptiveToContact: Bool = false
    
    var meshConnectionManager: MeshConnectionManager!
    var spatialOrderManager: SpatialOrderManager!
    var motionManager: MotionManager!
    var scene: BallScene!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        meshConnectionManager = MeshConnectionManager(peer: me)
        meshConnectionManager.delegate = self

        spatialOrderManager = SpatialOrderManager(peerID: me)
        
        motionManager = MotionManager(queue: motionHandlingQueue)
        motionManager.delegate = self
    }
    
    var alertController: UIAlertController!
    
    @IBOutlet weak var spriteView: SKView!
    
    @IBAction func resetTopography(sender: AnyObject) {
        self.spatialOrderManager.reset()
        updateAndShareGlobalTopography(true)
    }
    func didSwipe() {
        NSLog("sdflkj")
    }
    //MARK: View delegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let gestureRecognizer = UISwipeGestureRecognizer(target: self, action: "didSwipe")
        spriteView.addGestureRecognizer(gestureRecognizer)
        
        scene = BallScene(type: .Green)
        let size = self.view.frame.size
        scene.aspectRatio = CGFloat(size.width/size.height)
        scene.transferDelegate = self
        spriteView.presentScene(scene)
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        let size = self.view.frame.size
        scene.aspectRatio = CGFloat(size.width/size.height)
    }
    
    @IBAction func shouldSpew(sender: AnyObject) {
        scene.addNode(scene.generateRandomBall())
    }
        
    //MARK: utilities
    
    func peerForSide(side: Side) -> MCPeerID? {
        switch side {
        case .Left:
            return spatialOrderManager.leftDevice
        case .Right:
            return spatialOrderManager.rightDevice
        }
    }
    
    func considerWhetherToDisableMotion() {
        if spatialOrderManager.order.count == meshConnectionManager.session.connectedPeers.count + 1 {
            //This means all peers have a place in the world
            motionManager.stopMotionUpdates()
        } else {
            motionManager.startMotionUpdates()
        }
    }
    
    func updateAndShareGlobalTopography(shouldBroadcast: Bool) {
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            self.scene.setPhysicsBodyOpenings(self.spatialOrderManager.leftDevice != nil, right: self.spatialOrderManager.rightDevice != nil)
        })
        
        let text = "|".join(spatialOrderManager.order.map { $0.displayName })
        
        if shouldBroadcast {
            let topoRep = GlobalTopologyDefinitionRepresentation(topology: spatialOrderManager.order)
            var err: NSError?
            self.meshConnectionManager.sendMessage(topoRep, toPeers: meshConnectionManager.session.connectedPeers as [MCPeerID], error: &err)
            if let e = err {
                NSLog("❌🎵🌏: \(text)")
            } else {
                NSLog("🎵🌏: \(text)")
            }
        }
        
        considerWhetherToDisableMotion()
    }

    //MARK: Peer delegates
    func peer(peer: MCPeerID, sentMessage message: AnyObject) {
        switch message {
        case is BallTransferRepresentation:
            NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                let ball = message as BallTransferRepresentation
                NSLog("🎾 from \(ball.position)")
                self.scene.addNode(ball)
            }
        case is RelativeTopologyAssertionRepresentation:
            //Only the hub gets these messages
            spatialOrderManager.addInference(message as RelativeTopologyAssertionRepresentation)
            updateAndShareGlobalTopography(true)

        case is GlobalTopologyDefinitionRepresentation:
            
            spatialOrderManager.order = (message as GlobalTopologyDefinitionRepresentation).topology
            updateAndShareGlobalTopography(false)
            
        case is ContactEvent:
            //Looking to slow down the handling since it's common to get notified of another device making
            //contact even before handling our own
            motionHandlingQueue.addOperationWithBlock({ () -> Void in
                let type = (message as ContactEvent).contactSide!

                if self.receptiveToContact {

                    switch type {
                    case .Left: NSLog("👂💥👈")
                    case .Right:  NSLog("👂💥👉")
                    }

                    var topoAssertion: RelativeTopologyAssertionRepresentation
                    
                    switch type {
                    case .Left:
                        topoAssertion = RelativeTopologyAssertionRepresentation(leftHandCandidate: self.me, rightHandCandidate: peer)
                    case .Right:
                        topoAssertion = RelativeTopologyAssertionRepresentation(leftHandCandidate: peer, rightHandCandidate: self.me)
                    }
                    
                    if let hub = self.meshConnectionManager.hubPeer {
                        var err: NSError?
                        self.meshConnectionManager.sendMessage(topoAssertion, toPeers: [hub], error: &err)
                        
                        if let e = err {
                            NSLog("Couldn't send the contact event message")
                        } else {
                            NSLog("🎵 hub I'm on \(type.rawValue)")
                        }
                    } else {
                        self.peer(self.me, sentMessage: topoAssertion)
                    }
                } else {
                    switch type {
                    case .Left: NSLog("❌👂💥👈")
                    case .Right:  NSLog("❌👂💥👉")
                    }
                }
            })
        default:
            break
        }
    }
    
    func peerDidConnect(peer: MCPeerID) {
        let newItemCount = meshConnectionManager.session.connectedPeers.count + 1
        spatialOrderManager.addSpot(newItemCount)
        motionManager.startMotionUpdates()
    }
    
    func peerDidDisconnect(peer: MCPeerID) {
        spatialOrderManager.removeSpot(peer)
    }
    
    //MARK: Ball scene delegates
    
    func scene(scene: BallScene, ball: BallTransferRepresentation, didMoveOffscreen side: Side) {
        //TODO: Determine logic of how to know which peer should transfer to
        if let peer = peerForSide(side) {
            var err: NSError?
            meshConnectionManager.sendMessage(ball, toPeers: [peer], error: &err)
            if let e = err {
                NSLog("An error occured sending message to \(peer.displayName) - \(e.localizedDescription)")
            } else {
                NSLog("🎾 to \(side.rawValue) \(ball.position)")
            }
        } else {
            //Means the scene is out of date with spatial topology
            NSLog("❌🎾 to \(side.rawValue) \(ball.position)")
        }
    }
    
    //MARK: Motion manager delegate
    
    func motionManager(manager: MotionManager, didDetectContact contactEvent: ContactEvent) {
        
        let me = self
        
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            switch contactEvent.contactType {
            case .Passive:
                self.receptiveToContact = true
                
                NSTimer.scheduledTimerWithTimeInterval(0.4, target: me, selector: Selector("_resetContactReception"), userInfo: nil, repeats: false)
            case .Initiation:
                //We need to slow down sending this. That's why we'll add it to the main queue for delivery
                
                var err: NSError?
                
                self.meshConnectionManager.sendMessage(contactEvent, toPeers: self.meshConnectionManager.session.connectedPeers as [MCPeerID], error: &err)
                if let e = err {
                    NSLog("An error occured sending contact information")
                } else {
                    switch contactEvent.contactSide! {
                    case .Left: NSLog("🎵💥👈")
                    case .Right:  NSLog("🎵💥👉")
                    }
                }
            }
        }
    }
    
    func _resetContactReception() {
        NSLog("💥👊")
        self.receptiveToContact = false
    }
}

