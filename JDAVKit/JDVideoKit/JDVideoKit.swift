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
    func willPresent(cameraViewController vc:JDProcessingViewController,forkit:JDVideoKit)->JDProcessingViewController
    
    //Can make some setting for JDPresentingViewController, if return nil jump to next delegate
    func willPresent(edtingViewController vc:JDPresentingViewController,lastVC:UIViewController?,forkit:JDVideoKit)->JDPresentingViewController?
    
    //Set your type
    func ConvertType(forVideo resource:Any,forkit:JDVideoKit)->videoProcessType
    
    //Call When user click save.
    func FinalOutput(final video:AVAsset,url:URL)
}

public extension JDVideoKitDelegate
{
    func willPresent(cameraViewController vc:JDProcessingViewController,forkit:JDVideoKit)->JDProcessingViewController
    {
        return vc
    }
    
    func willPresent(edtingViewController vc:JDPresentingViewController,lastVC:UIViewController?,forkit:JDVideoKit)->JDPresentingViewController?
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
    
    
    public func getProperVC()->UIViewController
    {
        let processingBundle = Bundle(for:JDProcessingViewController.classForCoder())
        let presentingBundle = Bundle(for:JDPresentingViewController.classForCoder())
        
        if let sourcevideo = delegate.videoResource(forkit: self)
        {
            //Skip to Editng
            if let url = sourcevideo as? URL
            {
                let video = VideoOrigin(mediaType: nil, mediaUrl: url, referenceURL: nil)
                targetVC = JDPresentingViewController(nibName: "JDPresentingViewController", bundle: presentingBundle,video: video)
            }
            else if let assets = sourcevideo as? AVAsset
            {
                targetVC = JDPresentingViewController(nibName: "JDPresentingViewController", bundle: presentingBundle, video: assets)
            }
            else
            {
                fatalError("Video Only Support URL or AVAsset")
            }
            //User May Make Some Setting
            if let presentingVC = delegate.willPresent(edtingViewController: targetVC as! JDPresentingViewController, lastVC: nil, forkit: self)
            {
                presentingVC.delegate = self
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
            
            let jdprocessingVC = JDProcessingViewController(nibName: "JDProcessingViewController", bundle: processingBundle)
            let processingVC = delegate.willPresent(cameraViewController: jdprocessingVC, forkit: self)
            processingVC.delegate = self
            targetVC = processingVC
        }
        return targetVC
    }
    
}

extension JDVideoKit:JDProcessingViewControllerDlegate
{
    func VideoHasBeenSelect(video: VideoOrigin,processingVC:UIViewController)->JDPresentingViewController?
    {
        //Edting?
        let presentingBundle = Bundle(for:JDPresentingViewController.classForCoder())
        let editingVC = JDPresentingViewController(nibName: "JDPresentingViewController", bundle: presentingBundle,video: video)
        if let presentingVC = self.delegate.willPresent(edtingViewController: editingVC, lastVC: processingVC, forkit: self)
        {
            presentingVC.delegate = self
            return presentingVC
        }
        self.CapturingTheVideo(video: video.mediaUrl! as! URL)
        return nil
    }
    
    //Will Call When Capturing Finish, but not go to editing.
    func CapturingTheVideo(video:URL)
    {
        let Type = self.delegate.ConvertType(forVideo: video, forkit: self)
        if(Type == . Normal)
        {
            self.delegate.FinalOutput(final: AVAsset(url: video), url: video)
        }
        else
        {
           let factory = JDVideoFactory(type: Type, video: VideoOrigin(mediaType: nil, mediaUrl: video, referenceURL: nil))
            factory.pipeline = self
            factory.assetTOcvimgbuffer()
        }
        
    }
}

extension JDVideoKit:JDPresentingViewControllerDlegate
{
    func Converted(video: URL, chooseType: videoProcessType, by: JDPresentingViewController) {
        self.delegate.FinalOutput(final: AVAsset(url: video), url: video)
    }
}


//////////////////////////
////
////
////
//////////////////////////
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







