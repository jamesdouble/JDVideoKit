//
//  JDProcessingViewController.swift
//  JDAVKit
//
//  Created by 郭介騵 on 2017/7/28.
//  Copyright © 2017年 james12345. All rights reserved.
//

import AVFoundation
import UIKit
import MobileCoreServices

class JDProcessingViewController:UIViewController
{
    var imgPickerVC:UIImagePickerController?
    var presetingVC:JDPresentingViewController?
    var preview: AVCaptureVideoPreviewLayer!
    var captureSession:AVCaptureSession!
    var device:AVCaptureDevice!
    //
    fileprivate var buffers = [CVImageBuffer]()
    fileprivate let totalFrames: Int = 120
    fileprivate var recordShallStart: Bool = false
    var camerapostiion:Bool = false
    var flashOn:Bool = false
    var pinchZoomGesture:UIPinchGestureRecognizer!
    //
    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var captureKnob: UIButton!
    @IBOutlet weak var sessionLayer: UIView!
    @IBOutlet weak var SwitchCamVIew: SwitchIconDraw!
    @IBOutlet weak var FlashView: FlashIconDraw!
    
   
    func videoHasBeenSelect(video:VideoOrigin)
    {
        presetingVC = JDPresentingViewController(nibName: "JDPresentingViewController", bundle: nil,video: video)
        self.present(presetingVC!, animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview.frame = sessionLayer.bounds
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PhotoAlbum.shared.getLibraryVideoThumbnail(choose: { (img) in
            if(img != nil)
            {
                self.libraryButton.setImage(UIImage(cgImage: img!), for: .normal)
                self.libraryButton.imageEdgeInsets = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
            }
        })
        pinchZoomGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchToZoom(_:)))
        captureSession = AVCaptureSession()
        prepareSession()
        sessionLayer.addGestureRecognizer(pinchZoomGesture)
        //
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.ChangeCamera(_:)))
        SwitchCamVIew.addGestureRecognizer(tap)
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(self.openFlash(_:)))
        FlashView.addGestureRecognizer(tap2)
    }
    
    func openLibrary(_ sender: Any) {
        imgPickerVC = UIImagePickerController()
        imgPickerVC?.delegate = self
        imgPickerVC?.sourceType = .photoLibrary
        imgPickerVC?.mediaTypes = [(kUTTypeMovie as String),(kUTTypeVideo as String)]
        self.present(imgPickerVC!, animated: true, completion: nil)
    }
    
    func ChangeCamera(_ sender: Any) {
        camerapostiion = !camerapostiion
        switchCamera()
    }
    
    func openFlash(_ sender: Any)
    {
        try?  device.lockForConfiguration()
        flashOn = !flashOn
        if(flashOn)
        {
            device.flashMode = .on
            device.torchMode = .on
        }
        else
        {
            device.flashMode = .off
            device.torchMode = .off
        }
        device.unlockForConfiguration()
    }
    
    func pinchToZoom(_ sender: UIPinchGestureRecognizer) {
        if sender.state == .changed {
            
            let maxZoomFactor = device.activeFormat.videoMaxZoomFactor
            let pinchVelocityDividerFactor: CGFloat = 5.0
            
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                
                let desiredZoomFactor = device.videoZoomFactor + atan2(sender.velocity, pinchVelocityDividerFactor)
                device.videoZoomFactor = max(1.0, min(desiredZoomFactor, maxZoomFactor))
            } catch {
                print(error)
            }
        }
    }

    
    @IBAction func startRecord(_ sender: Any)
    {
        (sender as! UIButton).isUserInteractionEnabled = false
        progressView.alpha = 1.0
        recordShallStart = true
    }
    
  
}

extension JDProcessingViewController: AVCaptureVideoDataOutputSampleBufferDelegate
{
    func switchCamera()
    {
        for input in captureSession.inputs
        {
            if let inputs = input as? AVCaptureInput
            {
                captureSession.removeInput(inputs)
            }
        }
        let input = try? AVCaptureDeviceInput(device: connectedDevice(front: camerapostiion))
        if captureSession.canAddInput(input)
        {
            captureSession.addInput(input)
        }
        
         captureSession.startRunning()
    }
    
    func prepareSession()
    {
        device = connectedDevice(front: camerapostiion)
        let input = try? AVCaptureDeviceInput(device: device)
        if captureSession.canAddInput(input)
        {
            captureSession.addInput(input)
        }
        else { fatalError("captureSession can't add input") }
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
       
        /// 4
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [
            String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
        ]
        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
        }
        else { fatalError("captureSession can't add output") }
        captureSession.commitConfiguration()
        captureSession.startRunning()
        
        let queue: DispatchQueue = DispatchQueue(label: "VideoOutputQueue")
        dataOutput.setSampleBufferDelegate(self, queue: queue)
        dataOutput.connection(withMediaType: AVMediaTypeVideo).videoOrientation = .portrait
        ///
        preview = AVCaptureVideoPreviewLayer(session: captureSession)
        preview?.videoGravity = AVLayerVideoGravityResizeAspectFill
        preview?.connection.videoOrientation = .portrait
        sessionLayer.layer.addSublayer(preview!)
    }
    
    fileprivate func connectedDevice(front:Bool) -> AVCaptureDevice! {
        /// 7
        let postition:AVCaptureDevicePosition = (front) ? .front : .back
        if #available(iOS 10.0, *) {
            return AVCaptureDevice.defaultDevice(withDeviceType: AVCaptureDeviceType.builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: postition)
        }
        else {
            return AVCaptureDevice.devices()
                .map { $0 as! AVCaptureDevice }
                .filter { $0.hasMediaType(AVMediaTypeVideo) && $0.position == postition }.first! as AVCaptureDevice
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        guard let cvBuf = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        if captureOutput is AVCaptureVideoDataOutput, recordShallStart
        {
            /// 3
            let copiedCvBuf = cvBuf.deepcopy()
            buffers.append(copiedCvBuf)
            DispatchQueue.main.async {
                self.progressView.progress = (Float(self.buffers.count) / Float(self.totalFrames))
            }
            /// 4
            if buffers.count >= totalFrames {
                recordShallStart = false
                captureSession.stopRunning()
                
                let factory = JDVideoFactory(withBuffer: buffers)
                factory.setDoneClosure(clo: { (url) in
                    let videoorigin = VideoOrigin(mediaType: nil, mediaUrl: url, referenceURL: nil)
                    self.videoHasBeenSelect(video: videoorigin)
                })
                factory.bufferToVideo()
            }
        }
    }
}

extension JDProcessingViewController:UIImagePickerControllerDelegate,UINavigationControllerDelegate
{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        picker.dismiss(animated: true) { 
            let type = info["UIImagePickerControllerMediaType"]
            let url = info["UIImagePickerControllerMediaURL"]
             let rurl = info["UIImagePickerControllerReferenceURL"]
            let video = VideoOrigin(mediaType: type, mediaUrl: url, referenceURL: rurl)
            self.videoHasBeenSelect(video: video)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        self.dismiss(animated: true, completion: nil)
    }
}
