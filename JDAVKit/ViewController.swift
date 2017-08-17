//
//  ViewController.swift
//  JDAVKit
//
//  Created by 郭介騵 on 2017/7/23.
//  Copyright © 2017年 james12345. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        let vk = JDVideoKit(delegate: self).getProperVC()
        self.present(vk, animated: true, completion: nil)
        
        let vk2 = JDVideoKit(delegate: self)
        vk2.getVideoDirectly { (progress) in
            
        }
    }
}
extension ViewController:JDVideoKitDelegate
{
    func videoResource(forkit kit: JDVideoKit) -> Any? {
        return nil
    }
    func FinalOutput(final video:AVAsset,url:URL)
    {
        
    }
    func ConvertType(forVideo resource: Any, forkit: JDVideoKit) -> videoProcessType {
        return .Boom
    }
}
