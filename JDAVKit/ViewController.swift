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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let vk = JDVideoKit(delegate: self).getProperVC()
        self.present(vk, animated: true, completion: nil)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
}
