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

class ViewController: UIViewController, SessionManagerDelegate {
    
    var sessionManager: DiscoveryManager!
    var scene: BallScene!
    var openSides: (Bool, Bool) = (false, false)
    
    @IBOutlet weak var spriteView: SKView!
    @IBAction func shouldAdvertise(sender: AnyObject) {
        sessionManager.browseAgain()
    }
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        
        scene = BallScene()
        let size = self.view.frame.size
        scene.aspectRatio = CGFloat(size.width/size.height)
        scene.transferDelegate = sessionManager
        spriteView.presentScene(scene)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func wallDidOpenToSide(side: Side) {
        switch side {
        case .Left: openSides = (true, openSides.1)
        case .Right: openSides = (openSides.0, true)
        }
        scene.setPhysicsBodyOpenings(openSides.0, right: openSides.1)
    }
    
    func wallDidCloseToSide(side: Side) {
        switch side {
        case .Left: openSides = (false, openSides.1)
        case .Right: openSides = (openSides.0, false)
        }
        scene.setPhysicsBodyOpenings(openSides.0, right: openSides.1)
    }
    
    func shouldAddNewNode(data: [String : AnyObject], fromSide side: Side) {
        scene.addNeighborNode(data, fromSide: side)
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        let size = self.view.frame.size
        scene.aspectRatio = CGFloat(size.width/size.height)
    }
    
}

