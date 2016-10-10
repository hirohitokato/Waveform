//
//  ViewController.swift
//  Video Editing Template
//
//  Created by developer on 03/02/16.
//  Copyright © 2016 developer. All rights reserved.
//

import UIKit
import Photos

@objc
class VideoCollectionViewController: UICollectionViewController {

    var assetsFetchResults: [PHFetchResult] = [PHFetchResult<AnyObject>]()
    var moments: [PHAssetCollection]        = []

    var userAlbumsFetchPredicate       = NSPredicate(format: "estimatedAssetCount > 0")
    var userAlbumsFetchSortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
    var inAlbumItemsFetchPredicate     = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
    
    var selectedSnapshotView: UIView?
    
    fileprivate struct Constants {
        static let collectionViewCellReuseId = "video_collection_view_cell"
        static let collectionHeaderReuseId   = "video_collection_view_header"
        static let collectionFooterReuseId   = "FooterView"

        static func collectionSupplementaryElementReuseIdForKind(kind: String) -> String {
            switch kind {
            case UICollectionElementKindSectionHeader:
                return self.collectionHeaderReuseId
            case UICollectionElementKindSectionFooter:
                return self.collectionFooterReuseId
            default:
                fatalError()
            }
        }

        static let preview_width: CGFloat    = 150.0
        static let preview_height: CGFloat   = preview_width * 3/4
    }
    
    // MARK: - Constuctor/Destructor
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit{
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    // MARK: - View Controller Lifetime
    override func viewDidLoad() {
        super.viewDidLoad()

        // Hide nav bar bottom line
        let navBarHairlineImageView: UIImageView? = navigationController?.barHairlineImageView()
        navBarHairlineImageView?.isHidden           = true;
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        clearApplicationTmpDirectory()

        if self.assetsFetchResults.count == 0 {
            updateAssetsFetchResultsAndMoments()
            collectionView?.reloadData()
        }
    }
}


// MARK: - UICollectionViewDataSource
extension VideoCollectionViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return assetsFetchResults.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assetsFetchResults[section].count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.collectionViewCellReuseId, for:indexPath)
        
        if let cell = cell as? VideoCollectionViewCell,
            let asset = self.assetsFetchResults[indexPath.section][indexPath.row] as? PHAsset {
                cell.videoSource = asset
        } else {
            fatalError()
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        let reuseId = Constants.collectionSupplementaryElementReuseIdForKind(kind: kind)
        let reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: reuseId, for: indexPath)

        switch (kind, reusableView) {
        case (UICollectionElementKindSectionHeader, let headerView as VideoCollectionReusableView):
            headerView.configureWithCollection(collection: self.moments[indexPath.section])
        case (UICollectionElementKindSectionFooter, _): ()
        default:
            fatalError()
        }
        
        return reusableView
    }
}


// MARK: - UICollectionViewDelegateFlowLayout
extension VideoCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let count = floor(self.view.bounds.width/Constants.preview_width);
        let width = self.view.bounds.width/count;
        return CGSize(width: width,height: Constants.preview_height);
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return .zero
    }
}

// MARK: - Navigation/Transition
extension VideoCollectionViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller     = segue.destination as! ViewController
        let cell           = sender as! VideoCollectionViewCell
        controller.phAsset = cell.videoSource
    }
}


// MARK: - Content Update
extension VideoCollectionViewController {

    func updateAssetsFetchResultsAndMoments() {
        var assets  = [PHFetchResult<AnyObject>]()
        var moments = [PHAssetCollection]()
        
        let userAlbumsFetchOptions             = PHFetchOptions()
        userAlbumsFetchOptions.predicate       = userAlbumsFetchPredicate
        userAlbumsFetchOptions.sortDescriptors = userAlbumsFetchSortDescriptors
        
        let userAlbumsFetchResult = PHAssetCollection.fetchMoments(with: userAlbumsFetchOptions)
        
        let inAlbumItemsFetchOptions       = PHFetchOptions()
        inAlbumItemsFetchOptions.predicate = inAlbumItemsFetchPredicate
        
        
        userAlbumsFetchResult.enumerateObjects ({ (collection, _, _) -> Void in
            
            let assetsFetchResult = PHAsset.fetchAssets(in: collection, options: inAlbumItemsFetchOptions)
            
            if assetsFetchResult.count > 0 {
                assets.append(assetsFetchResult as! PHFetchResult<AnyObject>)
                moments.append(collection)
            }
        })
        
        self.moments            = moments
        self.assetsFetchResults = assets
    }
}


// MARK: - View Controller Auto Rotation
extension VideoCollectionViewController {
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}


// MARK: - PHPhotoLibraryChangeObserver
extension VideoCollectionViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async { () -> Void in
            self.updateAssetsFetchResultsAndMoments()
            self.collectionView?.reloadData()
        }
    }
}


// MARK:  -
// MARK:  - UINavigationController ex
extension UINavigationController {
    func barHairlineImageView() -> UIImageView? {
        return view.findSubview { $0.bounds.height <= 1.0 }
    }
}


// MARK: - UIView ex
extension UIView {
    func findSubview<T: UIView>(_ predicate: (T) -> (Bool)) -> T? {
        
        if let self_ = self as? T , predicate(self_) {
            return self_
        }
        
        for subview in subviews {
            if let targetView = subview.findSubview(predicate) {
                return targetView
            }
        }
        return nil
    }
}

// MARK: - Utility
func clearApplicationTmpDirectory() {
    do {
        let tmpDirectoryContent = try FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory())
        for file in tmpDirectoryContent {
            let filePath = NSTemporaryDirectory() + file
            try FileManager.default.removeItem(atPath: filePath)
        }
    } catch (let error) {
        print("\(#function), catched error:\(error)")
    }
}


