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
 

class JDPresentingViewController:UIViewController
{
    var pipeline:VideoFactoryPipeline?
    var videoOrigin:VideoOrigin!
    let videoasset:AVAsset
    var videoFactory = JDVideoFactory()
    let videoLayer:AVPlayerLayer
    let videoPlayer:AVPlayer
    var playerItemContext:Int8 = 0
    var trimImgBuffer:[CGImage] = [CGImage]()
    var StratingTouchX:CGFloat = 0
    let imgViewCount:Int = 10
    
    @IBOutlet weak var PlayerViewContainer: UIView!
    @IBOutlet weak var trimViewContainer: UIView!
    @IBOutlet weak var SpeedUpButton: UIButton!
    @IBOutlet weak var BoomButton: UIButton!
    @IBOutlet weak var RecerseButton: UIButton!
    
    
    var timeLineView:UIView = UIView()
    var LeadingConstraint:NSLayoutConstraint!
    
    init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?,video:VideoOrigin) {
        self.videoOrigin = video
        if let url = videoOrigin.mediaUrl as? URL
        {
            videoasset = AVAsset(url: url)
        }
        else { fatalError("videoOrigin.mediaUrl == nil") }
        let assetitem = AVPlayerItem(asset: videoasset)
        videoPlayer = AVPlayer(playerItem: assetitem)
        videoLayer = AVPlayerLayer(player: videoPlayer)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        assetitem.addObserver(self,
                              forKeyPath: #keyPath(AVPlayerItem.status),
                              options: [.old, .new],
                              context: &playerItemContext)
        
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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad()
    {
        self.pipeline?.setDoneClosure(clo: { (url) in
            print(url)
            //self.videoHasBeenChoose(url: url)
        })
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
        
    }
    
    override func viewDidLayoutSubviews() {
        videoLayer.frame = CGRect(origin: CGPoint.zero, size: PlayerViewContainer.frame.size)
        print(#function)
    }
    
    func videoHasBeenChoose(url:URL)
    {
        PhotoAlbum.shared.save(url) { (success, error) in
            
        }
    }
    
    
    @IBAction func SpeedUpAction(_ sender: Any) {
        videoPlayer.seek(to: kCMTimeZero) { (bool) in
            self.videoPlayer.rate = 2.0
        }
    }
    
    @IBAction func BoomerangeAction(_ sender: Any) {
        
        
    }
  
    @IBAction func ReverseAction(_ sender: Any) {
        videoPlayer.seek(to: videoasset.duration) { (bool) in
            self.videoPlayer.rate = -1.0
        }
    }
    
    
    
    override func observeValue(forKeyPath keyPath: String?,
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
            switch status {
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

extension JDPresentingViewController:UIGestureRecognizerDelegate
{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool
    {
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
            LeadingConstraint.constant = StratingTouchX + translation.x
            self.trimViewContainer.updateConstraints()
        }
        else
        {
             panG.setTranslation(CGPoint.zero, in: self.trimViewContainer)
        }
        
    }
    
}
