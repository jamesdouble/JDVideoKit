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

struct VideoOrigin {
    var mediaType: Any?
    var mediaUrl: Any?
    var referenceURL: Any?
}

protocol VideoFactoryPipeline {
    func bufferHabeBeenTovideo(url:URL,_ factory:JDVideoFactory)
    func reportProgress(_ progress:Progress,_ factory:JDVideoFactory)
}

class JDVideoFactory:NSObject
{
    var pipeline:VideoFactoryPipeline?
    var videoorigin:VideoOrigin?
    var cvimgbuffer:[CVImageBuffer] = [CVImageBuffer]()
    var fps:Int = 30
    var type:videoProcessType!
    var videoAsset:AVAsset?
    
    override init()
    {
        super.init()
    }
    
    init(type:videoProcessType,video:VideoOrigin)
    {
        super.init()
        self.type = type
        self.videoorigin = video
    }
    
    init(type:videoProcessType,video:AVAsset)
    {
        super.init()
        self.type = type
        self.videoAsset = video
    }
    
    ///2.0
    func assetTOcvimgbuffer()
    {
        if videoAsset == nil, let url = videoorigin?.mediaUrl as? URL {
            videoAsset = AVAsset(url: url)
        }
        guard let videoAsset = videoAsset else { fatalError("Asset not found") }
        let trackreader: AVAssetReader
        do {
            trackreader = try AVAssetReader(asset: videoAsset)
        } catch {
            fatalError(error.localizedDescription)
        }
        let videoTracks = videoAsset.tracks(withMediaType: AVMediaType.video)
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
        if(self.type == .Reverse)
        {
            cvimgbuffer.reverse()
        }
        if(self.type == .Boom)
        {
           if(cvimgbuffer.count > self.fps * 3)
           {
               let slice = cvimgbuffer.dropLast(cvimgbuffer.count - self.fps * 3)
               cvimgbuffer = Array(slice)
           }
           let reverse = cvimgbuffer.reversed()
           let origin = cvimgbuffer.map({ (buffer) -> CVImageBuffer in
            return buffer.deepcopy()
           })
           cvimgbuffer.append(contentsOf: reverse)
           cvimgbuffer.append(contentsOf: origin)
           cvimgbuffer.append(contentsOf: reverse)
        }
        
        let jdbuffer = JDBufferToVideo(buffer: cvimgbuffer, fps: Int32(fps))
        if(self.type == .Boom)
        {
            jdbuffer.filename = "BoomVideo.mov"
        }
        if(self.type == .Speed)
        {
            jdbuffer.fps = jdbuffer.fps * 2
        }
        
        jdbuffer.build({ (url) in
            self.pipeline?.bufferHabeBeenTovideo(url: url, self)
        }, { (progress) in
            self.pipeline?.reportProgress(progress, self)
        }) { (error) in
            
        }
    }
}



class JDBufferToVideo:NSObject
{
    let buffer: [CVPixelBuffer]
    var fps: Int32 = 30
    let kErrorDomain = "TimeLapseBuilder"
    let kFailedToStartAssetWriterError = 0
    let kFailedToAppendPixelBufferError = 1
    var filename:String = "MergedVideo.mov"
    
    //Capture Real time
    init(buffer: [CVPixelBuffer], fps: Int32) {
        self.buffer = buffer
        self.fps = fps
    }
    
    func build(_ sucess: @escaping ((URL) -> Void),_ progress: @escaping ((Progress) -> Void), failure: ((NSError) -> Void)) {
        
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
        
        let videoOutputURL = URL(fileURLWithPath: documentsPath.appendingPathComponent(filename))
        do {
            try FileManager.default.removeItem(at: videoOutputURL)
        } catch {}
        do {
            try videoWriter = AVAssetWriter(outputURL: videoOutputURL, fileType: .mp4)
        } catch let writerError as NSError {
            error = writerError
            videoWriter = nil
        }
        
        ///
        if let videoWriter = videoWriter
        {
            ///Add Input to Writer , AVAssetWriterInput use CVSampleBuffer , AVAssetWriterInputPixelBufferAdaptor use CVPixelBuffer
            let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
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
                            sucess(videoOutputURL)
                            return
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

