//
//  JDPresentingViewController.swift
//  JDAVKit
//
//  Created by 郭介騵 on 2017/7/30.
//  Copyright © 2017年 james12345. All rights reserved.
//

import AVFoundation
import UIKit
import MobileCoreServices

public enum videoProcessType
{
    case Boom
    case Speed
    case Normal
    case Reverse
}

protocol JDPresentingViewControllerDlegate {
    func Converted(video:URL,chooseType:videoProcessType,by:JDPresentingViewController)
}

public class JDPresentingViewController:UIViewController
{
    var delegate:JDPresentingViewControllerDlegate!
    //播放器相關
    var assetitem:AVPlayerItem!
    var BoomVideoItem:AVPlayerItem?
    var BoomVideoUrl:URL?
    let videoLayer:AVPlayerLayer
    let videoPlayer:AVPlayer
    //影片檔案相關
    var videoOrigin:VideoOrigin!
    let videoasset:AVAsset
    //影片產生器相關
    var FinalvideoFactory:JDVideoFactory?
    var BoomPreFactory:JDVideoFactory?
    //參數相關
    var playerItemContext:Int8 = 0
    var trimImgBuffer:[CGImage] = [CGImage]()
    var StratingTouchX:CGFloat = 0
    let imgViewCount:Int = 10
    var ChoosingMode:videoProcessType = .Normal
    var observer:Any!
    //
    @IBOutlet weak var PlayerViewContainer: UIView!
    @IBOutlet weak var trimViewContainer: UIView!
    @IBOutlet weak var SpeedUpButton: UIButton!
    @IBOutlet weak var BoomButton: UIButton!
    @IBOutlet weak var RecerseButton: UIButton!
    @IBOutlet weak var BoomProgressView: UIProgressView!
    //
    var timeLineView:UIView = UIView()
    var LeadingConstraint:NSLayoutConstraint!
    var indicatorView:UIActivityIndicatorView?
    
    func videoHasBeenChoose(url:URL)
    {
        self.delegate.Converted(video: url, chooseType: ChoosingMode, by: self)
    }
    
    ////////////////////////////////////////
    
    init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?,video:AVAsset)
    {
        //Init Video Asset
        videoasset = video
        assetitem = AVPlayerItem(asset: videoasset)
        videoPlayer = AVPlayer(playerItem: assetitem)
        videoLayer = AVPlayerLayer(player: videoPlayer)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?,video:VideoOrigin)
    {
        //Init Video Asset
        self.videoOrigin = video
        if let url = videoOrigin.mediaUrl as? URL
        {
            videoasset = AVAsset(url: url)
        }
        else { fatalError("videoOrigin.mediaUrl == nil") }
        assetitem = AVPlayerItem(asset: videoasset)
        videoPlayer = AVPlayer(playerItem: assetitem)
        videoLayer = AVPlayerLayer(player: videoPlayer)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    
    
    func generateThumb()
    {
        //產生縮圖列
        let assetImgGenerate : AVAssetImageGenerator    = AVAssetImageGenerator(asset: videoasset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.requestedTimeToleranceAfter    = kCMTimeZero
        assetImgGenerate.requestedTimeToleranceBefore   = kCMTimeZero
        assetImgGenerate.appliesPreferredTrackTransform = true
        let thumbTime: CMTime = videoasset.duration
        let thumbtimeSeconds:Double  = Double(CMTimeGetSeconds(thumbTime))
        let thumbAvg:Double  = thumbtimeSeconds/Float64(imgViewCount)
        var startTime:Double = 0.0
        
        for _ in 0...(imgViewCount-1)
        {
            do {
                let time:CMTime = CMTime(seconds: startTime, preferredTimescale: 300)
                let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
                trimImgBuffer.append(img)
            }
            catch
                _ as NSError
            {
                print("Image generation failed with error (error)")
            }
            startTime = startTime + thumbAvg
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad()
    {
        assetitem.addObserver(self,
                              forKeyPath: #keyPath(AVPlayerItem.status),
                              options: [.old, .new],
                              context: &playerItemContext)
        generateThumb()
        self.PlayerViewContainer.layer.addSublayer(videoLayer)
        //
        var lastimgView:UIImageView?
        for img in trimImgBuffer
        {
            let uiimg = UIImage(cgImage: img)
            let uiimgView = UIImageView(image: uiimg)
            uiimgView.translatesAutoresizingMaskIntoConstraints = false
            trimViewContainer.addSubview(uiimgView)
            
            let heightConstant = NSLayoutConstraint(item: uiimgView, attribute: .height, relatedBy: .equal, toItem: trimViewContainer, attribute: .height, multiplier: 1, constant: 0.0)
            let widthConstant = NSLayoutConstraint(item: uiimgView, attribute: .width, relatedBy: .equal, toItem: trimViewContainer, attribute: .width, multiplier: 1/CGFloat(imgViewCount), constant: 0.0)
            var leadingConstant:NSLayoutConstraint!
            if let lastimg = lastimgView
            {
                leadingConstant = NSLayoutConstraint(item: uiimgView, attribute: .leading, relatedBy: .equal, toItem: lastimg, attribute: .trailing, multiplier: 1.0, constant: 0.0)
            }
            else
            {
                leadingConstant = NSLayoutConstraint(item: uiimgView, attribute: .leading, relatedBy: .equal, toItem: trimViewContainer, attribute: .leading, multiplier: 1.0, constant: 0.0)
            }
            
            let verti = NSLayoutConstraint(item: uiimgView, attribute: .centerY, relatedBy: .equal, toItem: trimViewContainer, attribute: .centerY, multiplier: 1, constant: 0.0)
            trimViewContainer.addConstraints([heightConstant,widthConstant,leadingConstant,verti])
            lastimgView = uiimgView
        }
        //
        trimViewContainer.layer.borderWidth = 1.0
        trimViewContainer.layer.borderColor = UIColor.white.cgColor
        trimViewContainer.layer.cornerRadius = 3.0
        let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(self.dragTimeLine(sender:)))
        trimViewContainer.addGestureRecognizer(dragGesture)
        dragGesture.delegate = self
        //
        trimViewContainer.addSubview(timeLineView)
        timeLineView.backgroundColor = UIColor.white
        timeLineView.layer.cornerRadius = 1.0
        timeLineView.translatesAutoresizingMaskIntoConstraints = false
        //
        let width = NSLayoutConstraint(item: timeLineView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 6.0)
        timeLineView.addConstraint(width)
        let timeLineHConstraint = NSLayoutConstraint(item: timeLineView, attribute: .height, relatedBy: .equal, toItem: trimViewContainer, attribute: .height, multiplier: 1.0, constant: 0.0)
        let timeLineHorConstraint = NSLayoutConstraint(item: timeLineView, attribute: .centerY, relatedBy: .equal, toItem: trimViewContainer, attribute: .centerY, multiplier: 1.0, constant: 0.0)
        LeadingConstraint = NSLayoutConstraint(item: timeLineView, attribute: .leading, relatedBy: .equal, toItem: trimViewContainer, attribute: .leading, multiplier: 1, constant: 0)
        trimViewContainer.addConstraints([timeLineHConstraint,timeLineHorConstraint,LeadingConstraint])
        //
        SpeedUpButton.layer.cornerRadius = 10.0
        BoomButton.layer.cornerRadius = 10.0
        RecerseButton.layer.cornerRadius = 10.0
        //PrepareFor Boom
        BoomPreFactory = JDVideoFactory(type: .Boom, video: self.videoOrigin)
        BoomPreFactory?.pipeline = self
        BoomPreFactory?.assetTOcvimgbuffer()
        //
        let interval = CMTime(seconds: 0.1,
                              preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        observer = videoPlayer.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue(label: "PlayerQuene"))
        { [weak self] (time) in
            if(self?.videoPlayer.currentItem?.status == .readyToPlay)
            {
                guard let duration = self?.videoPlayer.currentItem?.asset.duration,let trimview = self?.trimViewContainer,let lineView = self?.timeLineView
                    else{
                        return
                }
                let totalsecond = CMTimeGetSeconds(duration)
                let ratio =  Float(CMTimeGetSeconds(time)) / Float(totalsecond)
                DispatchQueue.main.sync {
                    self?.LeadingConstraint.constant = CGFloat(Double(trimview.frame.width) * Double(ratio))
                    lineView.setNeedsLayout()
                    UIView.animate(withDuration: 0.1, animations: {
                        lineView.updateConstraintsIfNeeded()
                    })
                }
            }
        }
    }
    
    override public func viewDidLayoutSubviews() {
        videoLayer.frame = CGRect(origin: CGPoint.zero, size: PlayerViewContainer.frame.size)
    }
  
    func choosingMethod(newValue:videoProcessType)
    {
        let old = ChoosingMode
        let array = [SpeedUpButton,BoomButton,RecerseButton]
        array.forEach { (button) in
            button?.layer.borderWidth = 0.0
        }
        if(newValue == old)
        {
            self.ChoosingMode = .Normal
            videoPlayer.seek(to: kCMTimeZero) { (bool) in
                self.videoPlayer.rate = 1.0
            }
            return
        }
        var targetBtn:UIButton = BoomButton
        if(newValue == .Speed){ targetBtn = SpeedUpButton }
        else if(newValue == .Reverse) { targetBtn = RecerseButton }
        targetBtn.layer.borderWidth = 5.0
        targetBtn.layer.borderColor = UIColor.red.cgColor
        self.ChoosingMode = newValue
    }
    
    @IBAction func SaveAction(_ sender: Any) {
        if(indicatorView == nil)
        {
            indicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
            indicatorView?.frame = self.view.frame
            indicatorView?.startAnimating()
            self.view.addSubview(indicatorView!)
        }
        self.videoPlayer.pause()
        if(self.ChoosingMode == .Boom)
        {
            guard let boomurl = BoomVideoUrl
            else{
                fatalError()
            }
            self.delegate.Converted(video: boomurl, chooseType: .Boom, by: self)
            return
        }
        FinalvideoFactory = JDVideoFactory(type: self.ChoosingMode, video: self.assetitem.asset)
        FinalvideoFactory?.pipeline = self
        FinalvideoFactory?.assetTOcvimgbuffer()
    }
    

    
    @IBAction func SpeedUpAction(_ sender: Any) {
        if videoPlayer.currentItem! != assetitem
        {
            self.videoPlayer.replaceCurrentItem(with: assetitem)
        }
        videoPlayer.seek(to: kCMTimeZero) { (bool) in
            if(!bool) { print("seek Fail");return }
            self.videoPlayer.rate = 2.0
        }
        choosingMethod(newValue: .Speed)
    }
    
    @IBAction func BoomerangeAction(_ sender: Any) {
        if let item = BoomVideoItem,videoPlayer.currentItem! != item
        {
            self.videoPlayer.replaceCurrentItem(with: item)
            videoPlayer.seek(to: kCMTimeZero) { (bool) in
                if(!bool) { print("seek Fail"); return }
                self.videoPlayer.rate = 1.0
            }
        }
        choosingMethod(newValue: .Boom)
    }
  
    @IBAction func ReverseAction(_ sender: Any)
    {
        if videoPlayer.currentItem! != assetitem
        {
            self.videoPlayer.replaceCurrentItem(with: assetitem)
        }
    
        videoPlayer.seek(to: videoasset.duration) { (bool) in
            if(!bool) { print("seek Fail");return }
            self.videoPlayer.rate = -1.0
        }
        choosingMethod(newValue: .Reverse)
    }
    
    @IBAction func DismissAction(_ sender: Any)
    {
        assetitem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status),context: &playerItemContext)
        self.dismiss(animated: true, completion: {
            
        })
    }
    

    override public func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        // Only handle observations for the playerItemContext
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
            return
        }
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItemStatus
            
            // Get the status change from the change dictionary
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            // Switch over the status
            switch status
            {
            case .readyToPlay:
                videoPlayer.play()
                break
            case .failed:
                break
            case .unknown:
                break
            }
        }
    }
    
}

extension JDPresentingViewController:VideoFactoryPipeline
{
    func bufferHabeBeenTovideo(url:URL,_ factory:JDVideoFactory)
    {
        indicatorView?.removeFromSuperview()
        indicatorView = nil
        if(factory == BoomPreFactory)
        {
            DispatchQueue.main.sync {
                self.BoomProgressView.removeFromSuperview()
            }
            let asset = AVAsset(url: url)
            self.BoomVideoUrl = url
            self.BoomVideoItem = AVPlayerItem(asset: asset)
            self.BoomPreFactory = nil
        }
        else if(factory == FinalvideoFactory)
        {
            self.delegate.Converted(video: url, chooseType: self.ChoosingMode, by: self)
        }
    }
    
    func reportProgress(_ progress:Progress,_ factory:JDVideoFactory)
    {
        if(factory == BoomPreFactory)
        {
            DispatchQueue.main.sync
            {
                let progressfloat = Float(progress.completedUnitCount)/Float(progress.totalUnitCount)
                self.BoomProgressView.progress = progressfloat
            }
        }
        else if(factory == FinalvideoFactory)
        {
            
        }
    }
}

extension JDPresentingViewController:UIGestureRecognizerDelegate
{
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool
    {
        self.videoPlayer.pause()
        //
        let location = touch.location(in: trimViewContainer)
        self.StratingTouchX = location.x
        LeadingConstraint.constant = location.x
        self.trimViewContainer.updateConstraints()
        return true
    }
    
    func dragTimeLine(sender:Any)
    {
        guard let panG = sender as? UIPanGestureRecognizer else {
            return
        }
        let state = panG.state
        if(state == .changed || state == .began)
        {
            let translation = panG.translation(in: self.trimViewContainer)
            let newPosition = StratingTouchX + translation.x
            LeadingConstraint.constant = newPosition
            let ratio = newPosition / self.trimViewContainer.frame.width
            if(self.videoPlayer.currentItem?.status == .readyToPlay)
            {
                guard let duration = self.videoPlayer.currentItem?.asset.duration
                    else{
                        return
                }
                let newtime = CMTime(value: Int64(CGFloat(duration.value) * ratio), timescale: duration.timescale)
                self.videoPlayer.seek(to: newtime)
            }
            self.timeLineView.updateConstraints()
        }
        else if(state == .ended)
        {
            self.videoPlayer.play()
             panG.setTranslation(CGPoint.zero, in: self.trimViewContainer)
        }
        
    }
    
}
