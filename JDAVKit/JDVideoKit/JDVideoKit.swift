//
//  JDAVKit.swift
//  JDAVKit
//
//  Created by 郭介騵 on 2017/7/25.
//  Copyright © 2017年 james12345. All rights reserved.
//

import UIKit
import AVFoundation

public protocol JDVideoKitDelegate {
    //If return nil means call JDProcessingViewController
    func videoResource(forkit kit:JDVideoKit)->Any?
    //Only will call when above function return nil. Can make some setting for JDProcessingViewController
    func willPresent(cameraViewController vc:JDProcessingViewController)->JDProcessingViewController
    
    //Can make some setting for JDPresentingViewController, if return nil jump to next delegate
    func willPresent(edtingViewController vc:JDPresentingViewController,originVideo:AVAsset,forkit:JDVideoKit)->JDPresentingViewController?
    
    //Set your type
    func ConvertType(forVideo resource:Any,forkit:JDVideoKit)->videoProcessType
    
    //Call When user click save.
    func FinalOutput(final video:AVAsset,url:URL)
}

extension JDVideoKitDelegate
{
    func willPresent(cameraViewController vc:JDProcessingViewController)->JDProcessingViewController
    {
        return vc
    }
    
    func willPresent(edtingViewController vc:JDPresentingViewController,originVideo:AVAsset,forkit:JDVideoKit)->JDPresentingViewController?
    {
        return vc
    }
    
    func ConvertType(forVideo resource:Any,forkit:JDVideoKit)->videoProcessType
    {
        return .Normal
    }
}

public class JDVideoKit:NSObject
{
    private var targetVC:UIViewController!
    
    fileprivate var delegate:JDVideoKitDelegate!
    fileprivate var directProgressClo:(Float)->() = { (progress) in
        return
    }
    
    public init(delegate:JDVideoKitDelegate)
    {
        self.delegate = delegate
    }
    
    
    func getProperVC()->UIViewController
    {
        if let sourcevideo = delegate.videoResource(forkit: self)
        {
            //Skip to Editng
            var asset:AVAsset!
            if let url = sourcevideo as? URL
            {
                asset = AVAsset(url: url)
                let video = VideoOrigin(mediaType: nil, mediaUrl: url, referenceURL: nil)
                targetVC = JDPresentingViewController(nibName: "JDPresentingViewController", bundle: nil,video: video)
            }
            else if let assets = sourcevideo as? AVAsset
            {
                asset = assets
                targetVC = JDPresentingViewController(nibName: "JDPresentingViewController", bundle: nil, video: assets)
            }
            else
            {
                fatalError("Video Only Support URL or AVAsset")
            }
            
            //User May Make Some Setting
            if let presentingVC = delegate.willPresent(edtingViewController: targetVC as! JDPresentingViewController, originVideo: asset, forkit: self)
            {
                targetVC = presentingVC
            }
            else
            {
                fatalError("You have source, and skip editng Scene. Use function getVideoDirectly instead")
            }
        }
        else
        {
            //User don't have Video Source, go to JDProcessingVC First
            let jdprocessingVC = JDProcessingViewController(nibName: "JDProcessingViewController", bundle: nil)
            let processingVC = delegate.willPresent(cameraViewController: jdprocessingVC)
            processingVC.delegate = self
            targetVC = processingVC
        }
        return targetVC
    }
    
}

extension JDVideoKit:VideoFactoryPipeline
{
    public func getVideoDirectly(progress:@escaping (Float)->())
    {
        self.directProgressClo = progress
        guard let source = delegate.videoResource(forkit: self) else {
            fatalError("use getVideoDirectly must give a video source")
        }
        let type = delegate.ConvertType(forVideo: source, forkit: self)
        
        //
        var factory:JDVideoFactory!
        if let url = source as? URL
        {
            factory = JDVideoFactory(type: type, video: VideoOrigin(mediaType: nil, mediaUrl: url, referenceURL: nil))
        }
        else if let assets = source as? AVAsset
        {
            factory = JDVideoFactory(type: type, video: assets)
        }
        else
        {
            fatalError("Video Only Support URL or AVAsset")
        }
        factory.pipeline = self
        factory.assetTOcvimgbuffer()
    }
    
    func bufferHabeBeenTovideo(url:URL,_ factory:JDVideoFactory)
    {
        self.delegate.FinalOutput(final: AVAsset(url: url), url: url)
    }
    
    func reportProgress(_ progress:Progress,_ factory:JDVideoFactory)
    {
        let float:Float = Float(progress.completedUnitCount) / Float(progress.totalUnitCount)
        self.directProgressClo(float)
    }
}

extension JDVideoKit:JDProcessingViewControllerDlegate
{
    func VideoHasBeenSelect(video: VideoOrigin)->JDPresentingViewController?
    {
        //Edting?
        let targetVC = JDPresentingViewController(nibName: "JDPresentingViewController", bundle: nil,video: video)
        let asset = AVAsset(url: video.mediaUrl! as! URL)
        let presentingVC = self.delegate.willPresent(edtingViewController: targetVC, originVideo: asset, forkit: self)
        return presentingVC
    }
}





