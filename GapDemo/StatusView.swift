//
//  StatusView.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-10-23.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import UIKit

enum StatusOption {
    case Good
    case Bad
}

let _badColor = UIColor.redColor()
let _goodColor = UIColor.greenColor()

class StatusView : UIView {
    
    var status : StatusOption? {
        didSet {
            if let actualStatus = status {
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    switch(actualStatus) {
                    case .Good: self.backgroundColor = _goodColor
                    case .Bad: self.backgroundColor = _badColor
                    }
                })
            }
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layer.cornerRadius = 10
    }
}
