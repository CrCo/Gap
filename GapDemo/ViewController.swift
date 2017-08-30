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

class ViewController: UIViewController, MeshConnectionManagerDelegate, BallSceneDelegate, MotionManagerDelegate {
    
    var me: MCPeerID {
        get {
            let def = UserDefaults.standard
                        
            if let data = def.object(forKey: "me") as! Data? {
                return NSKeyedUnarchiver.unarchiveObject(with: data) as! MCPeerID
            } else {
                let newPeer = MCPeerID(displayName: UIDevice.current.name)
                def.set(NSKeyedArchiver.archivedData(withRootObject: newPeer), forKey: "me")
                return newPeer
            }
        }
    }
    
    var operatingMode: OperationMode {
        get {
            switch UserDefaults.standard.bool(forKey: "role") {
            case true: return .listener
            case false:
                fallthrough
            default: return .broadcaster
            }
        }
    }
    
    var ballType: BallType {
        get {
            return BallType(rawValue: UserDefaults.standard.integer(forKey: "type") as Int)!
        }
    }

    var side: Side {
        get {
            if let s = UserDefaults.standard.string(forKey: "side") {
                return Side(rawValue: s)!
            }
            return .Left
        }
    }
    
    var meshConnectionManager: MeshConnectionManager!
    var spatialOrderManager: OrderStorage!
    var motionManager: MotionManager!
    var scene: BallScene!
    
    @IBOutlet weak var spriteView: SKView!
    @IBOutlet weak var statusIndicator: UILabel!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        
        meshConnectionManager = MeshConnectionManager(peer: me, side: side)
        meshConnectionManager.delegate = self
        meshConnectionManager.mode = operatingMode
        
        switch operatingMode {
        case .listener:
            spatialOrderManager = SpatialOrderManager(peerID: me)

            motionManager = MotionManager()
            motionManager.delegate = self
            motionManager.startMotionUpdates()
        case .broadcaster:
            spatialOrderManager = SpatialOrderContainer(me: me)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.defaultsDidChange(_:)), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    //MARK: View delegates
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scene = BallScene(type: ballType)
        let size = self.view.frame.size
        scene.aspectRatio = CGFloat(size.width/size.height)
        scene.transferDelegate = self
        spriteView.presentScene(scene)
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        let size = self.view.frame.size
        scene.aspectRatio = CGFloat(size.width/size.height)
    }
    
    //MARK: User settings did change handler
    
    func defaultsDidChange(_ notification: Notification) {
        meshConnectionManager.mode = operatingMode
        meshConnectionManager.side = side
        scene.type = ballType
    }
    
    //MARK: utility
    
    func updateAndShareGlobalTopography() {
        OperationQueue.main.addOperation({ () -> Void in
            self.scene.openings = (
                left: self.spatialOrderManager.left() != nil,
                right: self.spatialOrderManager.right() != nil
            )
        })
        
        if spatialOrderManager is SpatialOrderManager {
            //We are the hub, we need to forward our knowledge
            let som = spatialOrderManager as! SpatialOrderManager

            let topoRep = GlobalTopologyDefinitionRepresentation(topology: som.order)
            var err: NSError?
            self.meshConnectionManager.sendMessage(topoRep, toPeers: meshConnectionManager.session.connectedPeers as! [MCPeerID], error: &err)
            if let e = err {
                NSLog("❌🎵🌏: \(som)")
            } else {
                NSLog("🎵🌏: \(som)")
            }
        }
    }

    //MARK: Peer delegates
    func peer(_ peer: MCPeerID, sentMessage message: AnyObject) {
        switch message {
        case is BallTransferRepresentation:
            let ball = message as! BallTransferRepresentation
            NSLog("🎾 from \(ball.position)")
            self.scene.addNode(ball)
        case is RelativeTopologyAssertionRepresentation:
            //Only the hub gets these messages
            (spatialOrderManager as! SpatialOrderManager).addInference(message as! RelativeTopologyAssertionRepresentation, forPeer: peer)
            updateAndShareGlobalTopography()
        case is GlobalTopologyDefinitionRepresentation:
            (spatialOrderManager as! SpatialOrderContainer).order = (message as! GlobalTopologyDefinitionRepresentation).topology
            updateAndShareGlobalTopography()
            
        case is RelativePositionRequest:
            var err: NSError?
            
            let topoAssertion = RelativeTopologyAssertionRepresentation(side: side)
            self.meshConnectionManager.sendMessage(topoAssertion, toPeers: [peer], error: &err)
            
            if let e = err {
                NSLog("Couldn't send the contact event message")
            } else {
                NSLog("🎵 \(side.rawValue)")
            }
        default:
            fatalError("Unknown message")
        }
    }
    
    func peerDidConnect(_ peer: MCPeerID) {
        OperationQueue.main.addOperation { () -> Void in
            self.statusIndicator.text = "💏"
        }
        
        if operatingMode == .listener && motionManager.stable {
            var err: NSError?
            
            meshConnectionManager.sendMessage(RelativePositionRequest(), toPeers: meshConnectionManager.session.connectedPeers as! [MCPeerID], error: &err)
            
            if let e = err {
                NSLog("Could not send request")
            }
        }
    }
    
    func peerDidDisconnect(_ peer: MCPeerID) {
        if spatialOrderManager is SpatialOrderManager {
            (spatialOrderManager as! SpatialOrderManager).removeSpot(peer)
            updateAndShareGlobalTopography()
            //When a client disconnects, the discovery doesn't happen automatically
            //meshConnectionManager.reconnect()
        } else if peer == meshConnectionManager.hubPeer {
            (spatialOrderManager as! SpatialOrderContainer).clear()
            updateAndShareGlobalTopography()
        }

        OperationQueue.main.addOperation { () -> Void in
            self.statusIndicator.text = "💔"
        }
    }
    
    func peerIsConnecting(_ peer: MCPeerID) {
        OperationQueue.main.addOperation { () -> Void in
            self.statusIndicator.text = "💗"
        }
    }
    
    //MARK: Ball scene delegates
    
    func scene(_ scene: BallScene, ball: BallTransferRepresentation, didMoveOffscreen side: Side) {
        var neighbor: MCPeerID?
        switch side {
        case .Left:
            neighbor = spatialOrderManager.left()
        case .Right:
            neighbor = spatialOrderManager.right()
        }        
        
        if let peer = neighbor {
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
    
    //MARK: Motion manager delegate (only for hub)
    func motionManagerDidPickUp() {
        (self.spatialOrderManager as! SpatialOrderManager).reset()
        updateAndShareGlobalTopography()
    }

    func motionManagerDidPutDown() {
        var err: NSError?

        meshConnectionManager.sendMessage(RelativePositionRequest(), toPeers: meshConnectionManager.session.connectedPeers as! [MCPeerID], error: &err)

        if let e = err {
            NSLog("Could not send request")
        }
    }
}

