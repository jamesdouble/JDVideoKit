//
//  PhotoAlbum.swift
//  ReversedMovie
//
//  Created by Haik Ampardjian on 4/17/17.
//  Copyright © 2017 Unicorn. All rights reserved.
//

import Photos

class PhotoAlbum: NSObject
{
    static let albumName = "ReversedVideos"
    static let shared = PhotoAlbum()
    
    var assetCollection: PHAssetCollection!
    
    override init() {
        super.init()
        
        if let assetCollection = fetchAssetCollectionForAlbum() {
            self.assetCollection = assetCollection
            return
        }
        
        if PHPhotoLibrary.authorizationStatus() != PHAuthorizationStatus.authorized {
            PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) -> Void in
                print(status)
            })
        }
        
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.authorized {
            createAlbum()
        } else {
            PHPhotoLibrary.requestAuthorization(requestAuthorizationHandler)
        }
    }
    
    func requestAuthorizationHandler(_ status: PHAuthorizationStatus) {
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.authorized {
            // ideally this ensures the creation of the photo album even if authorization wasn't prompted till after init was done
            print("trying again to create the album")
            createAlbum()
        } else {
            print("should really prompt the user to let them know it's failed")
        }
    }
    
    func createAlbum() {
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: PhotoAlbum.albumName)   // create an asset collection with the album name
        }) { [weak self] success, error in
            if success {
                self?.assetCollection = self?.fetchAssetCollectionForAlbum()
            } else {
                print("error \(String(describing: error))")
            }
        }
    }
    
    func fetchAssetCollectionForAlbum() -> PHAssetCollection!
    {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", PhotoAlbum.albumName)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let _: AnyObject = collection.firstObject {
            return collection.firstObject!
        }
        return nil
    }
    
    func getLibraryVideoThumbnail(choose:@escaping (CGImage?)->())
    {
        let options = PHFetchOptions()
        var cgimage:CGImage?
        options.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: false) ]
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        if let video = PHAsset.fetchAssets(with: options).firstObject
        {
            PHCachingImageManager().requestAVAsset(forVideo: video, options: nil, resultHandler: { (asset, audiomax, info) in
                let imggenerator = AVAssetImageGenerator(asset: asset!)
                let attime:CMTime = CMTime(seconds: 0.0, preferredTimescale: 600)
                cgimage = try? imggenerator.copyCGImage(at: attime, actualTime: nil)
                choose(cgimage)
            })
        }
    }
    
    func save(_ fileURL: URL, completion: @escaping (Bool, Error?) -> ()) {
        if assetCollection == nil {
            return                          // if there was an error upstream, skip the save
        }
        
        PHPhotoLibrary.shared().performChanges({
            let assetChangeRequest: PHAssetChangeRequest?
            
            assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
            
            let assetPlaceHolder = assetChangeRequest?.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection)
            albumChangeRequest!.addAssets([assetPlaceHolder!] as NSArray)
            
        }, completionHandler: completion)
    }
}
