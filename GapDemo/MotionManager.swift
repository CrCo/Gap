//
//  MotionManager.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-11-04.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import CoreMotion

protocol MotionManagerDelegate: NSObjectProtocol {
    func motionManager(manager: MotionManager, didDetectContact: ContactEvent)
}

class MotionManager: NSObject {
    
    let motionManager = CMMotionManager()
    var motionHandlingQueue: NSOperationQueue
    weak var delegate: MotionManagerDelegate!
    
    init(queue: NSOperationQueue) {
        self.motionHandlingQueue = queue
        super.init()
        
        // 1/100 of second is pretty much the best we can do for most devices
        motionManager.accelerometerUpdateInterval = 0.01
    }
    
    func startMotionUpdates() {
        NSLog("💥👂 STARTED")
        motionManager.startAccelerometerUpdatesToQueue(motionHandlingQueue, withHandler: accelerometerUpdateHandler())
    }
    
    func stopMotionUpdates() {
        NSLog("💥👂 STOPPED")

        motionManager.stopAccelerometerUpdates()
    }
    
    func accelerometerUpdateHandler() -> (data: CMAccelerometerData!, err: NSError!) -> Void {
        let idleThreshold = 0.025
        let boundarySize = 50
        
        var log = [Double]()
        
        var samplingCountdown: Int = 0
        var lastNonThreshold: Double = 0
        var lastNonThresholdTimestamp: NSTimeInterval = 0

        return { (data: CMAccelerometerData!, err: NSError!) -> Void in
            
            if abs(data.acceleration.x) > idleThreshold {
                //Some event is happening
                if log.count == 0 {
                    //Add context
                    log.append(lastNonThreshold)
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        let diff = data.timestamp - lastNonThresholdTimestamp
                        NSLog("💥👀")
                    })
                }
                
                log.append(data.acceleration.x)
                samplingCountdown = boundarySize
            } else {
                //Below threshold
                if samplingCountdown > 0 {
                    //If we haven't already
                    log.append(data.acceleration.x)
                    samplingCountdown--
                } else if log.count > 0 {
                    //Counted down and we've captured results
                    
                    self.motionManager.stopAccelerometerUpdates()
                    var arrayCopy: Slice<Double>
                    
                    if log.count >= boundarySize {
                        arrayCopy = log[0..<log.count - boundarySize]
                    } else {
                        arrayCopy = log[0..<log.count]
                    }
                    
                    self.performAnalysis(arrayCopy)
                    self.motionManager.startAccelerometerUpdatesToQueue(self.motionHandlingQueue, withHandler: self.accelerometerUpdateHandler())
                } else {
                    lastNonThreshold = data.acceleration.x
                    lastNonThresholdTimestamp = data.timestamp
                }
            }
        }
    }

    
    func performAnalysis(log: Slice<Double>) {

        let eventThreshold = 0.3
        let powerThreshold = 1.0
        
        var sum: Double = 0
        for i in 0..<log.count {
            let val = log[i]
            if abs(val) < eventThreshold {
                sum += val
            } else {
                var event: ContactEvent
                if abs(sum) > powerThreshold {
                    if sum > 0 {
                        NSLog("💥👈")
                        event = ContactEvent(initiationWithContactDirection: .Left)
                    } else {
                        NSLog("💥👉")
                        event = ContactEvent(initiationWithContactDirection: .Right)
                    }
                } else {
                    NSLog("💥✋")
                    event = ContactEvent()
                }
                self.delegate.motionManager(self, didDetectContact: event)
                return
            }
        }
        NSLog("💥❌")
    }
}