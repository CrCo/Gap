//
//  MotionManager.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-11-04.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import CoreMotion

protocol MotionManagerDelegate: NSObjectProtocol {
    func motionManagerDidPickUp()
    func motionManagerDidPutDown()
}

class MotionManager: NSObject {
    
    let motionManager = CMMotionManager()
    var motionHandlingQueue: NSOperationQueue = NSOperationQueue()
    weak var delegate: MotionManagerDelegate!
    var stable: Bool = false
    
    override init() {
        super.init()
        
        motionManager.accelerometerUpdateInterval = 0.2
    }
    
    func startMotionUpdates() {
        NSLog("💥👂 STARTED")
        motionManager.startAccelerometerUpdatesToQueue(motionHandlingQueue, withHandler: accelerometerUpdateHandler())
    }
    
    func stopMotionUpdates() {
        NSLog("💥👂 STOPPED")
        motionManager.stopAccelerometerUpdates()
    }
    
    func startTimer() {
        NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "startMotionUpdates", userInfo: nil, repeats: false)
    }
    
    func accelerometerUpdateHandler() -> (data: CMAccelerometerData!, err: NSError!) -> Void {
        let idleThreshold = 0.1
        
        var log = [Double]()
        
        var samplingCountdown: Int = 0
        
        return { (data: CMAccelerometerData!, err: NSError!) -> Void in
            
            let _stable = abs(data.acceleration.x) < idleThreshold && abs(data.acceleration.y) < idleThreshold && data.acceleration.z < -0.75
                        
            if self.stable != _stable {
                self.stable = _stable
                self.stopMotionUpdates()
                if self.stable {
                    self.delegate.motionManagerDidPutDown()
                } else {
                    self.delegate.motionManagerDidPickUp()
                }
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    self.startTimer()
                })
            }
        }
    }
}