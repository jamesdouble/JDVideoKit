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

protocol JDProcessingViewControllerDlegate
{
    func VideoHasBeenSelect(video:VideoOrigin)->JDPresentingViewController?
}

public class JDProcessingViewController:UIViewController
{
    var delegate:JDProcessingViewControllerDlegate?
    //
    fileprivate var imgPickerVC:UIImagePickerController?
    fileprivate var preview: AVCaptureVideoPreviewLayer?
    fileprivate var captureSession:AVCaptureSession!
    fileprivate var device:AVCaptureDevice!
    fileprivate var dataOutput:AVCaptureMovieFileOutput?
    //
    fileprivate var filename:String = "RecordVideo.mov"
    fileprivate var camerapostiion:Bool = false
    fileprivate var flashOn:Bool = false
    fileprivate var pinchZoomGesture:UIPinchGestureRecognizer!
    //
    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var captureKnob: UIButton!
    @IBOutlet weak var sessionLayer: UIView!
    @IBOutlet weak var SwitchCamVIew: SwitchIconDraw!
    @IBOutlet weak var FlashView: FlashIconDraw!

    
    func videoHasBeenSelect(video:VideoOrigin)
    {
        if let presenting = delegate?.VideoHasBeenSelect(video: video)
        {
            self.present(presenting, animated: true, completion: nil)
        }
        else
        {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    
    
    override public func viewWillAppear(_ animated: Bool) {
        if(captureSession != nil)
        {
            captureSession.startRunning()
        }
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview?.frame = sessionLayer.bounds
    }
    
    override public func viewDidLoad() {
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
    
    private func openLibrary(_ sender: Any) {
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
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let videoOutputURL = URL(fileURLWithPath: documentsPath.appendingPathComponent(filename))
        do {
            try FileManager.default.removeItem(at: videoOutputURL)
        } catch {}
        dataOutput?.maxRecordedDuration = CMTime(seconds: 6.0, preferredTimescale: 30)
        dataOutput?.startRecording(toOutputFileURL: videoOutputURL, recordingDelegate: self)
    }
}

extension JDProcessingViewController: AVCaptureFileOutputRecordingDelegate
{
    public func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!)
    {
        let queue: DispatchQueue = DispatchQueue(label: "VideoOutputQueue")
        queue.async {
            while(captureOutput.isRecording)
            {
                let duration = captureOutput.recordedDuration
                let second = CMTimeGetSeconds(duration)
                let ratio = second / 6.0
                DispatchQueue.main.sync {
                    self.progressView.progress = Float(ratio)
                }
            }
        }
    }
    
    public func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!)
    {
        let videoorigin = VideoOrigin(mediaType: nil, mediaUrl: outputFileURL, referenceURL: nil)
        self.videoHasBeenSelect(video: videoorigin)
        self.captureKnob.isUserInteractionEnabled = true
        self.progressView.progress = 0
    }
    
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
    
    fileprivate func prepareSession()
    {
        device = connectedDevice(front: camerapostiion)
        let input = try? AVCaptureDeviceInput(device: device)
        if captureSession.canAddInput(input)
        {
            captureSession.addInput(input)
        }
        else { print("captureSession can't add input")
            return}
        
        let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        do {
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            self.captureSession.addInput(audioInput)
        } catch {
            print("Unable to add audio device to the recording.")
            return
        }
        
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
       
        /// 4
        dataOutput = AVCaptureMovieFileOutput()
        
        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
        }
        else { fatalError("captureSession can't add output") }
        captureSession.commitConfiguration()
        captureSession.startRunning()
        dataOutput?.connection(withMediaType: AVMediaTypeVideo).videoOrientation = .portrait
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
}

extension JDProcessingViewController:UIImagePickerControllerDelegate,UINavigationControllerDelegate
{
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        picker.dismiss(animated: true) { 
            let type = info["UIImagePickerControllerMediaType"]
            let url = info["UIImagePickerControllerMediaURL"]
             let rurl = info["UIImagePickerControllerReferenceURL"]
            let video = VideoOrigin(mediaType: type, mediaUrl: url, referenceURL: rurl)
            self.videoHasBeenSelect(video: video)
        }
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        self.dismiss(animated: true, completion: nil)
    }
}
