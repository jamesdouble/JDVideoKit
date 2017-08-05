//
//  JDAVKit.swift
//  JDAVKit
//
//  Created by 郭介騵 on 2017/7/25.
//  Copyright © 2017年 james12345. All rights reserved.
//

import UIKit

struct VideoOrigin {
    var mediaType:Any?
    var mediaUrl:Any?
    var referenceURL:Any?
}

class JDVideoKit
{
    public var processingVC:JDProcessingViewController!
    
    init()
    {
        processingVC = JDProcessingViewController(nibName: "JDProcessingViewController", bundle: nil)
    }
}

