//
//  JDBufferToVideo.swift
//  JDAVKit
//
//  Created by 郭介騵 on 2017/7/27.
//  Copyright © 2017年 james12345. All rights reserved.
//

import Foundation
import AVFoundation
import CoreVideo
protocol VideoFactoryPipeline {
    func havechooseVideo(video:VideoOrigin)
    func haveCameraBuffer(buffer:[CVImageBuffer])
    func bufferHabeBeenTovideo(url:URL)
    func setDoneClosure(clo: @escaping (_ url:URL)->())
}


class JDVideoFactory:NSObject,VideoFactoryPipeline
{
    var videoorigin:VideoOrigin!
    var buffertoVideo:JDBufferToVideo?
    var cvimgbuffer:[CVImageBuffer] = [CVImageBuffer]()
    var doneClosure:(_ url:URL)->() = { url in
        
    }
    var fps:Int = 30
    override init()
    {
        super.init()
    }
    
    init(withBuffer buffer:[CVImageBuffer]) {
        self.cvimgbuffer = buffer
    }
    
    func setDoneClosure(clo: @escaping (_ url:URL) -> ()) {
        self.doneClosure = clo
    }
    
    ///1.0
    func havechooseVideo(video: VideoOrigin) {
        self.videoorigin = video
        assetTOcvimgbuffer()
    }
    func haveCameraBuffer(buffer: [CVImageBuffer]) {
        self.cvimgbuffer = buffer
        bufferToVideo()
    }
    ///2.0
    func assetTOcvimgbuffer()
    {
        let videoAsset = AVAsset(url: videoorigin?.mediaUrl! as! URL)
        let trackreader = try! AVAssetReader(asset: videoAsset)
        let videoTracks = videoAsset.tracks(withMediaType: AVMediaTypeVideo)
        //
        for track in videoTracks
        {
            let trackoutput:AVAssetReaderTrackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: [
                String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
                ])
            //
            fps = Int(track.nominalFrameRate)
            if trackreader.canAdd(trackoutput)
            {
                trackreader.add(trackoutput)
                var buffer:CMSampleBuffer?
                if trackreader.startReading()
                {
                    buffer = trackoutput.copyNextSampleBuffer()
                    while(buffer != nil)
                    {
                        guard let cvimgabuffer = CMSampleBufferGetImageBuffer(buffer!) else {
                            fatalError("cvimgabuffer is nil")
                        }
                        cvimgbuffer.append(cvimgabuffer.deepcopy())
                        buffer = trackoutput.copyNextSampleBuffer()
                    }
                }
            }
        }
        bufferToVideo()
    }
    ///3.0
    func bufferToVideo()
    {
        cvimgbuffer.reverse()
        let jdbuffer = JDBufferToVideo(buffer: cvimgbuffer, fps: Int32(fps))
        jdbuffer.factoryPipeline = self
        jdbuffer.build({ (progress) in
            
        }) { (error) in
            print(error)
        }
    }
    ///4.0
    func bufferHabeBeenTovideo(url: URL)
    {
        self.doneClosure(url)
    }
}



class JDBufferToVideo:NSObject
{
    let buffer: [CVPixelBuffer]
    var factoryPipeline:VideoFactoryPipeline?
    var fps: Int32 = 30
    let kErrorDomain = "TimeLapseBuilder"
    let kFailedToStartAssetWriterError = 0
    let kFailedToAppendPixelBufferError = 1
    
    //Capture Real time
    init(buffer: [CVPixelBuffer], fps: Int32) {
        self.buffer = buffer
        self.fps = fps
    }
    
    func build(_ progress: @escaping ((Progress) -> Void), failure: ((NSError) -> Void)) {
        
        ///Get Basic Setting
        var error: NSError?
        let firstPixelBuffer = buffer.first!
        let width = CVPixelBufferGetWidth(firstPixelBuffer)
        let height = CVPixelBufferGetHeight(firstPixelBuffer)
        let attr = CVBufferGetAttachments(firstPixelBuffer, .shouldPropagate) as! [String : Any]
        let videoSettings: [String : Any] = [
            AVVideoCodecKey  : AVVideoCodecH264,
            AVVideoWidthKey  : width,
            AVVideoHeightKey : height
        ]
        
        ///Now in order to glue all the data we grabbed so far, we need to use magic AVAssetWriter. It’s a powerful class in AVFoundation which allow to write a video into output directory, encode the video file format into .mov or .mp4 and manage the metadata of the frames while recording it.
        var videoWriter: AVAssetWriter?
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let videoOutputURL = URL(fileURLWithPath: documentsPath.appendingPathComponent("MergedVideo.mov"))
        do {
            try FileManager.default.removeItem(at: videoOutputURL)
        } catch {}
        do {
            try videoWriter = AVAssetWriter(outputURL: videoOutputURL, fileType: AVFileTypeQuickTimeMovie)
        } catch let writerError as NSError {
            error = writerError
            videoWriter = nil
        }
        
        ///
        if let videoWriter = videoWriter
        {
            ///Add Input to Writer , AVAssetWriterInput use CVSampleBuffer , AVAssetWriterInputPixelBufferAdaptor use CVPixelBuffer
            let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
            let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput,sourcePixelBufferAttributes: attr)
            guard videoWriter.canAdd(videoWriterInput) else {
                fatalError("VideoWriter Can't Add")
            }
            videoWriterInput.expectsMediaDataInRealTime = false
            videoWriter.add(videoWriterInput)
            ///
            if videoWriter.startWriting()
            {
                //start session 讓 pixel buffer != nil
                videoWriter.startSession(atSourceTime: kCMTimeZero)
                if (pixelBufferAdaptor.pixelBufferPool == nil)
                {
                    fatalError("pixelBufferPool is nil")
                }
                
                let media_queue = DispatchQueue(label: "mediaInputQueue")
                //
                videoWriterInput.requestMediaDataWhenReady(on: media_queue)
                {
                    let welf = self
                    let currentProgress = Progress(totalUnitCount: Int64(welf.buffer.count))
                    var frameCount: Int64 = 0
                    let frameDuration = CMTimeMake(1, welf.fps)
                    var remainingPhotoURLs = welf.buffer
                    
                    while !remainingPhotoURLs.isEmpty
                    {
                        let nextPhotoURL:CVPixelBuffer? = remainingPhotoURLs.remove(at: 0)
                        let newPixelBufferoutputs:CVPixelBuffer = nextPhotoURL!
                        let lastFrameTime = CMTimeMake(frameCount, welf.fps)
                        let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
                        while !videoWriterInput.isReadyForMoreMediaData
                        {
                            Thread.sleep(forTimeInterval: 0.1)
                        }
                        
                        if pixelBufferAdaptor.append(newPixelBufferoutputs, withPresentationTime: presentationTime)
                        {
                            frameCount += 1
                            currentProgress.completedUnitCount = frameCount
                            progress(currentProgress)
                        }
                        else
                        {
                            fatalError("pixelBufferAdaptor can't append")
                        }
                    }
                    
                    videoWriterInput.markAsFinished()
                    videoWriter.finishWriting {
                        if error == nil {
                            if(self.factoryPipeline != nil)
                            {
                                self.factoryPipeline?.bufferHabeBeenTovideo(url: videoOutputURL)
                            }
                        }
                    }
                }
            } else {
                error = NSError(
                    domain: kErrorDomain,
                    code: kFailedToStartAssetWriterError,
                    userInfo: ["description": "AVAssetWriter failed to start writing"]
                )
            }
        }
        
        if let error = error {
            failure(error)
        }
    }
}

extension CVPixelBuffer
{
    func deepcopy() -> CVPixelBuffer {
        /// 1
        precondition(CFGetTypeID(self) == CVPixelBufferGetTypeID(), "copy() cannot be called on a non-CVPixelBuffer")
        
        /// 2
        let attr = CVBufferGetAttachments(self, .shouldPropagate)
        var _copy : CVPixelBuffer? = nil
        
        /// 3
        CVPixelBufferCreate(
            CFAllocatorGetDefault().takeRetainedValue(),
            CVPixelBufferGetWidth(self),
            CVPixelBufferGetHeight(self),
            CVPixelBufferGetPixelFormatType(self),
            attr,
            &_copy)
        
        guard let copy = _copy else { fatalError() }
        
        /// 4
        CVPixelBufferLockBaseAddress(self, .readOnly)
        CVPixelBufferLockBaseAddress(copy, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        
        /// 5
        let planeCount = CVPixelBufferGetPlaneCount(self)
        
        for plane in 0..<planeCount {
            let dest = CVPixelBufferGetBaseAddressOfPlane(copy, plane)
            let source = CVPixelBufferGetBaseAddressOfPlane(self, plane)
            let height = CVPixelBufferGetHeightOfPlane(self, plane)
            let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(self, plane)
            
            memcpy(dest, source, height * bytesPerRow)
        }
        
        /// 6
        CVPixelBufferUnlockBaseAddress(copy, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        CVPixelBufferUnlockBaseAddress(self, .readOnly)
        
        return copy
    }
}

