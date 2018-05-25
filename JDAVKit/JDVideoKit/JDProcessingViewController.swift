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
    func VideoHasBeenSelect(video:VideoOrigin,processingVC:UIViewController)->JDPresentingViewController?
}

public class JDProcessingViewController:UIViewController
{
    let queue: DispatchQueue = DispatchQueue(label: "VideoOutputQueue")
    var delegate:JDProcessingViewControllerDlegate?
    //
    fileprivate var imgPickerVC:UIImagePickerController?
    fileprivate var preview: AVCaptureVideoPreviewLayer?
    fileprivate var captureSession:AVCaptureSession!
    fileprivate var device:AVCaptureDevice!
    fileprivate var dataOutput:AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
    //
    fileprivate var filename:String = "RecordVideo.mov"
    fileprivate var camerapostiion:Bool = false
    fileprivate var flashOn:Bool = false
    fileprivate var sessionSucess:Bool = false
    fileprivate var pinchZoomGesture:UIPinchGestureRecognizer!
    //
    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var sessionLayer: UIView!
    @IBOutlet weak var UpperViewContainer: UIView!
    @IBOutlet weak var DownViewContainer: UIView!
    @IBOutlet weak var SwitchCamVIew: SwitchIconDraw!
    @IBOutlet weak var FlashView: FlashIconDraw!
    @IBOutlet weak var RecordView: RecordIconDraw!
    //
    public var enableFlashLight:Bool = true
    public var FlashLightIconColor:UIColor = UIColor.black
    public var SwitchIconColor:UIColor = UIColor.white
    public var CaptureIconColor:UIColor = UIColor.white
    public var allowChooseFromLibrary:Bool = true
    public var BackgroundViewBarColor:UIColor?
    //
    func videoHasBeenSelect(video:VideoOrigin)
    {
        if let presenting = delegate?.VideoHasBeenSelect(video: video, processingVC: self)
        {
            self.present(presenting, animated: true, completion: nil)
        }
    }
    
    
    /////////////////////////////////////////////////////////////////////
    
    override public func viewWillAppear(_ animated: Bool) {
        if(sessionSucess)
        {
            captureSession.startRunning()
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        captureSession.stopRunning()
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview?.frame = sessionLayer.bounds
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        pinchZoomGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchToZoom(_:)))
        sessionLayer.addGestureRecognizer(pinchZoomGesture)
        prepareSession()
        //
        initLibraryButton()
        initFlashButton()
        initSwitchButton()
        initCaptureButton()
        if let bgcolor = BackgroundViewBarColor
        {
            UpperViewContainer.backgroundColor = bgcolor
            DownViewContainer.backgroundColor = bgcolor
        }
    }
    
    @IBAction func openLibrary(_ sender: Any) {
        imgPickerVC = UIImagePickerController()
        imgPickerVC?.delegate = self
        imgPickerVC?.sourceType = .photoLibrary
        imgPickerVC?.mediaTypes = [(kUTTypeMovie as String),(kUTTypeVideo as String)]
        self.present(imgPickerVC!, animated: true, completion: nil)
    }
    
    @objc func ChangeCamera(_ sender: Any) {
        camerapostiion = !camerapostiion
        switchCamera()
    }
    
    @objc func openFlash(_ sender: Any)
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
    
    @objc func pinchToZoom(_ sender: UIPinchGestureRecognizer) {
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

    
    @objc func startRecord(_ sender: Any)
    {
        progressView.alpha = 1.0
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let videoOutputURL = URL(fileURLWithPath: documentsPath.appendingPathComponent(filename))
        do {
            try FileManager.default.removeItem(at: videoOutputURL)
        } catch {}
        dataOutput.maxRecordedDuration = CMTime(seconds: 6.0, preferredTimescale: 30)
        dataOutput.startRecording(to: videoOutputURL, recordingDelegate: self)
    }
}

extension JDProcessingViewController
{
    func initFlashButton()
    {
        if(!enableFlashLight)
        {
            FlashView.isHidden = true
            return
        }
        FlashView.iconcolor = FlashLightIconColor.cgColor
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(self.openFlash(_:)))
        FlashView.addGestureRecognizer(tap2)
    }
    
    func initSwitchButton()
    {
        SwitchCamVIew.iconcolor = SwitchIconColor.cgColor
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.ChangeCamera(_:)))
        SwitchCamVIew.addGestureRecognizer(tap)
    }
    
    func initCaptureButton()
    {
        RecordView.iconcolor = CaptureIconColor.cgColor
        let tap3 = UITapGestureRecognizer(target: self, action: #selector(self.startRecord(_:)))
        RecordView.addGestureRecognizer(tap3)
    }
    
    func initLibraryButton()
    {
        if(!allowChooseFromLibrary)
        {
            self.libraryButton.isHidden = true
            return
        }
        PhotoAlbum.shared.getLibraryVideoThumbnail(choose: { (img) in
            if let image = img {
                DispatchQueue.main.async {
                    self.libraryButton.setImage(UIImage(cgImage: image), for: .normal)
                    self.libraryButton.imageEdgeInsets = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
                }
            }
        })
        
    }
}

extension JDProcessingViewController: AVCaptureFileOutputRecordingDelegate
{
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        let videoorigin = VideoOrigin(mediaType: nil, mediaUrl: outputFileURL, referenceURL: nil)
        self.videoHasBeenSelect(video: videoorigin)
        self.progressView.progress = 0
    }
    
    public func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        queue.async {
            while(output.isRecording)
            {
                let duration = output.recordedDuration
                let second = CMTimeGetSeconds(duration)
                let ratio = second / 6.0
                DispatchQueue.main.sync {
                    self.progressView.progress = Float(ratio)
                }
            }
        }
    }
        
    func switchCamera()
    {
        for input in captureSession.inputs
        {
            captureSession.removeInput(input)
        }
        guard let input = try? AVCaptureDeviceInput(device: connectedDevice(front: camerapostiion)) else { return }
        if captureSession.canAddInput(input)
        {
            captureSession.addInput(input)
        }
         captureSession.startRunning()
    }
    
    fileprivate func prepareSession()
    {
        captureSession = AVCaptureSession()
        device = connectedDevice(front: camerapostiion)
        guard let input = try? AVCaptureDeviceInput(device: device) else { return }
        if captureSession.canAddInput(input)
        {
            captureSession.addInput(input)
        }
        else { print("captureSession can't add input")
            return}
        sessionSucess = true
       
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            print("Unable to add audio device to the recording.")
            return
        }
        do {
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            self.captureSession.addInput(audioInput)
        } catch {
            print("Unable to add audio device to the recording.")
            return
        }
        //Quality
        captureSession.sessionPreset = AVCaptureSession.Preset.high
        /// 4
        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
        } else { fatalError("captureSession can't add output") }
        
        captureSession.commitConfiguration()
        captureSession.startRunning()
        dataOutput.connection(with: .video)?.videoOrientation = .portrait
        ///
        preview = AVCaptureVideoPreviewLayer(session: captureSession)
        preview?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        preview?.connection?.videoOrientation = .portrait
        sessionLayer.layer.addSublayer(preview!)
    }
    
    fileprivate func connectedDevice(front:Bool) -> AVCaptureDevice! {
        /// 7
        let postition:AVCaptureDevice.Position = (front) ? .front : .back
        if #available(iOS 10.0, *) {
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: postition)
        }
        else {
            return AVCaptureDevice.devices().filter { $0.hasMediaType(.video) && $0.position == postition }.first! as AVCaptureDevice
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
