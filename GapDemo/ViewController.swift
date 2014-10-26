//
//  ViewController.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-10-23.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, SessionManagerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func wallDidOpenToSide() {
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            self.view.backgroundColor = UIColor.greenColor()
        })
    }
    
    func wallDidCloseToSide() {
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            
            self.view.backgroundColor = UIColor.redColor()
        })
    }
    
}

