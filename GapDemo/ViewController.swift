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
    
    var lastEvent: ContactEvent?
    
    var meshConnectionManager: MeshConnectionManager!
    var spatialOrderManager: SpatialOrderManager!
    var motionManager: MotionManager!
    var scene: BallScene!
    var type: BallType {
        get {
            return BallType(rawValue: NSUserDefaults.standardUserDefaults().integerForKey("type") as Int)!
        }
        set {
            NSUserDefaults.standardUserDefaults().setInteger(type.rawValue, forKey: "type")
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        motionHandlingQueue.qualityOfService = NSQualityOfService.UserInitiated
        
        meshConnectionManager = MeshConnectionManager(peer: me)
        meshConnectionManager.delegate = self

        spatialOrderManager = SpatialOrderManager(peerID: me)
        
        motionManager = MotionManager(queue: motionHandlingQueue)
        motionManager.delegate = self
    }
    
    var alertController: UIAlertController!
    
    @IBOutlet weak var spriteView: SKView!
    
    @IBOutlet weak var type0: UIButton!
    @IBOutlet weak var type1: UIButton!
    @IBOutlet weak var type2: UIButton!
    
    
    @IBAction func didChangeType(sender: UIButton) {
        var _type: Int
        
        switch sender {
        case type0: _type = 0
        case type1: _type = 1
        case type2: _type = 2
        default: _type = -1
        }
        
        if let t = BallType(rawValue: _type) {
            type = t
            
            scene.changeBallType(t)
        }
    }
    
    @IBOutlet weak var statusIndicator: UILabel!
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
            self.scene.openings = (left: self.spatialOrderManager.leftDevice != nil, right: self.spatialOrderManager.rightDevice != nil)
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
            let event = message as ContactEvent

            if lastEvent != nil && event.contactType != lastEvent!.contactType {
                NSLog("👂\(event.description)")
                
                var topoAssertion: RelativeTopologyAssertionRepresentation
                
                switch event.contactType {
                case .Initiation:
                    switch event.contactSide! {
                    case .Left:
                        topoAssertion = RelativeTopologyAssertionRepresentation(leftHandCandidate: self.me, rightHandCandidate: peer)
                    case .Right:
                        topoAssertion = RelativeTopologyAssertionRepresentation(leftHandCandidate: peer, rightHandCandidate: self.me)
                    }
                case .Passive:
                    switch lastEvent!.contactSide! {
                    case .Left:
                        topoAssertion = RelativeTopologyAssertionRepresentation(leftHandCandidate: peer, rightHandCandidate: self.me)
                    case .Right:
                        topoAssertion = RelativeTopologyAssertionRepresentation(leftHandCandidate: self.me, rightHandCandidate: peer)
                    }
                }
                
                if let hub = self.meshConnectionManager.hubPeer {
                    var err: NSError?
                    self.meshConnectionManager.sendMessage(topoAssertion, toPeers: [hub], error: &err)
                    
                    if let e = err {
                        NSLog("Couldn't send the contact event message")
                    } else {
                        let order = "|".join([topoAssertion.leftHandCandidate.displayName, topoAssertion.rightHandCandidate.displayName])
                        NSLog("🎵 \(order)")
                    }
                } else {
                    self.peer(self.me, sentMessage: topoAssertion)
                }
            } else {
                NSLog("❌👂\(event.description)")
            }

        default:
            break
        }
    }
    
    func peerDidConnect(peer: MCPeerID) {
        let newItemCount = meshConnectionManager.session.connectedPeers.count + 1
        spatialOrderManager.addSpot(newItemCount)
        motionManager.startMotionUpdates()
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.statusIndicator.text = "💏"
        }

    }
    
    func peerDidDisconnect(peer: MCPeerID) {
        spatialOrderManager.removeSpot(peer)
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in

            self.statusIndicator.text = "💔"
        }
    }
    
    func peerIsConnecting(peer: MCPeerID) {
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.statusIndicator.text = "💗"
        }
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
    
    
    func _startTimer() {
        NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: "_resetContactReception", userInfo: nil, repeats: false)
    }
    
    func motionManager(manager: MotionManager, didDetectContact contactEvent: ContactEvent) {
        
        //Start timer for receptivity
        lastEvent = contactEvent
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self._startTimer()
        }

        //Send message to peer
        var err: NSError?
        self.meshConnectionManager.sendMessage(contactEvent, toPeers: self.meshConnectionManager.session.connectedPeers as [MCPeerID], error: &err)
        if let e = err {
            NSLog("An error occured sending contact information")
        } else {
            NSLog("🎵\(contactEvent.description)")
        }
    }
    
    func _resetContactReception() {
        NSLog("💥👊")
        lastEvent = nil
    }
}

