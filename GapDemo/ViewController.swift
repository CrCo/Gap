//
//  ViewController.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-10-23.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import UIKit
import MultipeerConnectivity

let _cellIdentifier = "default"

class ViewController: UIViewController, SessionManagerDelegate {

    var sessionManager = SessionManager()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        sessionManager.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func wallDidCloseToSide(side: SpatialPosition) {
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            NSLog("Did fail")
            self.view.backgroundColor = UIColor.greenColor()
        })
    }
    
    func wallDidOpenToSide(side: SpatialPosition) {
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            NSLog("Didn't fail")
            self.view.backgroundColor = UIColor.redColor()
        })
    }
}

