//
//  PhotosCollectionViewController.swift
//  WaldoPhotosTest
//
//  Created by Nanci Frank on 1/25/17.
//  Copyright © 2017 Wildcat Productions. All rights reserved.
//

import UIKit
import Apollo
import ReachabilitySwift

private let reuseIdentifier = "imageViewCell"
private let bearerToken = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhY2NvdW50X2lkIjoiMmEyODQ4M2YtNWM2Yi00ZWU5LWE4YjUtYzFlMGU5NWUwYTY5Iiwicm9sZXMiOlsiYWRtaW5pc3RyYXRvciJdLCJpc3MiOiJ3YWxkbzpjb3JlIiwiZ3JhbnRzIjpbImFsYnVtczpkZWxldGU6KiIsImFsYnVtczpjcmVhdGU6KiIsImFsYnVtczplZGl0OioiLCJhbGJ1bXM6dmlldzoqIl0sImV4cCI6MTQ4Nzk3OTExMywiaWF0IjoxNDg1Mzg3MTEzfQ.3i4KWxNyCyGiKr2a1cWPbHAWSISDOg3ch8zOruY5Abg"

enum PhotoRecordState {
    case new, downloaded, failed
}

class PhotoRecord {
    let url: String
    var state: PhotoRecordState = .new
    var image: UIImage?
    
    init(url: String) {
        self.url = url
    }
}

class PendingOperations {
    lazy var downloadsInProgress = [IndexPath:Operation]()
    lazy var downloadQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Download"
        return queue
    }()
}

class ImageDownloader: Operation {
    let photoRecord: PhotoRecord
    
    init(photoRecord: PhotoRecord) {
        self.photoRecord = photoRecord
    }
    
    override func main() {
        if self.isCancelled { return }
        if let photoURL = URL(string: photoRecord.url), let tempImage: NSData = NSData(contentsOf: photoURL) {
            guard !self.isCancelled else { return }
            let image: UIImage = UIImage(data: tempImage as Data)!
            self.photoRecord.image = image
            self.photoRecord.state = .downloaded
        } else {
            self.photoRecord.image = UIImage(named: "BrokenImage")
            self.photoRecord.state = .failed
        }
    }
}


class PhotosCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var photoDataSource = [PhotoRecord]()
    var offSetVal: Int = 0
    var loadingPhotos: Bool = false
    var allPhotosLoaded: Bool = false
    
    let pendingOperations = PendingOperations()
    
    lazy var flowLayout: UICollectionViewFlowLayout = {
        return self.collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
    }()
    
    var networkIsReachable: Bool = true
    let reachability = Reachability()!
    
    var numberOfPhotos: Int {
        if self.currentDevice == .pad {
            return 6
        } else if self.traitCollection.verticalSizeClass == .compact {
            return 5
        }
        return 3
    }
    
    var minWidth: Int = 375
    var imageCache = [String : UIImage]() // Used a dictionary for image cache. NSCache would clear when lost network connection
    
    let refreshControl = UIRefreshControl()
    
    lazy var currentDevice: UIUserInterfaceIdiom = {
        return self.traitCollection.userInterfaceIdiom
    }()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupReachability()
    }
    
    // Check if network is accessible; Alert user if it is not and set flag to stop downloading any more images
    func setupReachability() {
        reachability.whenReachable = { [unowned self] reachability in
            self.networkIsReachable = true
        }
        reachability.whenUnreachable = { [unowned self] reachability in
            self.networkIsReachable = false
            let alert = UIAlertController(title: "Alert", message: "Network not available. Not able to load more photos.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    
    // Setup Pull to Refresh
    func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refreshData(refreshControl:)), for: .valueChanged)
        collectionView?.addSubview(refreshControl)
    }
    
    // Pull to Refresh: Clear all data and cache. Make new call to download images.
    // Can refresh data after lose/regain network connection
    func refreshData(refreshControl: UIRefreshControl) {
        guard networkIsReachable else { return }
        photoDataSource.removeAll()
        offSetVal = 0
        loadingPhotos = false
        allPhotosLoaded = false
        collectionView?.reloadData()
        fetchPhotoData()
        refreshControl.endRefreshing()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupRefreshControl()
        fetchPhotoData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    deinit {
        self.reachability.stopNotifier()
    }
    
    // Check the width of the device to use for calculating photo size in collection view layout
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        minWidth = Int(view.frame.width)
        collectionView?.reloadData()
    }
    
    /*
     Set up configuration for Apollo to fetch data
     Set loadingPhotos to true to stop retrieving more until completed
     If no errors, retrieve URL for small2X photo for each record
     Store URLs as strings in photoDataSource
    */
    func fetchPhotoData() {
        guard networkIsReachable else {
            return
        }
        
        loadingPhotos = true
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["Authorization": bearerToken]
        
        let urlString = URL(string: "https://core-graphql.staging.waldo.photos/gql")
        let apollo = ApolloClient(networkTransport: HTTPNetworkTransport(url: urlString!, configuration: configuration))
        apollo.fetch(query: AlbumQuery(offset: offSetVal)) { [unowned self] (data, error) in
            if let error = error {
                NSLog("Error while fetching query: \(error.localizedDescription)")
                self.loadingPhotos = false
                self.allPhotosLoaded = true
                return
            }
            
            // Access records and URLs, store in photoDataSource
            if let data = data?.data {
                if let photos = data.album?.photos?.records, photos.count > 0 {
                    if let title = data.album?.name {
                        self.navigationItem.title = title + " Photos"
                    } else {
                        self.navigationItem.title = "Photo Album Viewer"
                    }
                    for photo in photos {
                        let photoRecord = PhotoRecord(url: (photo?.urls?[1]?.url)!)
                        self.photoDataSource.append(photoRecord)
                    }
                } else {
                    self.allPhotosLoaded = true
                }
            } else {
                self.allPhotosLoaded = true
            }
            
            self.collectionView?.reloadData()
            self.loadingPhotos = false
        }
    }
    
    func startDownloadForPhotoRecord(_ photoRecord: PhotoRecord, indexPath: IndexPath) {
        if let _ = pendingOperations.downloadsInProgress[indexPath] {
            return
        }
        
        let downloader = ImageDownloader(photoRecord: photoRecord)
        
        downloader.completionBlock = {
            if downloader.isCancelled {
                return
            }
            OperationQueue.main.addOperation {
                self.pendingOperations.downloadsInProgress.removeValue(forKey: indexPath)
                self.collectionView?.reloadItems(at: [indexPath])
            }
        }
        pendingOperations.downloadsInProgress[indexPath] = downloader
        pendingOperations.downloadQueue.addOperation(downloader)
    }

    
    // Infintite scrolling: Check if scrolled to bottom of images. Retrieve more data if needed
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !loadingPhotos && !allPhotosLoaded && networkIsReachable else { return }
        
        let offsetY = scrollView.contentOffset.y
        let contentTrigger = scrollView.contentSize.height - scrollView.frame.size.height
        if offsetY > contentTrigger && offsetY > 0 {
            offSetVal += 50
            fetchPhotoData()
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoDataSource.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? PhotosCollectionViewCell
        
        // Start indicator to show loading photos
        cell?.activityIndicator.startAnimating()
        
        let photoRecord = photoDataSource[indexPath.row]
        cell?.imageView.image = photoRecord.image
        
        switch photoRecord.state {
        case .failed:
            cell?.activityIndicator.stopAnimating()
            break
        case .new:
            self.startDownloadForPhotoRecord(photoRecord, indexPath: indexPath)
        case .downloaded:
            cell?.activityIndicator.stopAnimating()
        }

        return cell!
    }
 
    // MARK: UICollectionViewDelegateFlowLayout

    // Set cell and image size for collection view. Calculate based on device size.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemSpacing = Int(flowLayout.minimumInteritemSpacing)
        let leftRightInset = Int(flowLayout.sectionInset.left + flowLayout.sectionInset.right)
        let kWhateverHeightYouWant = CGFloat((minWidth - ((numberOfPhotos - 1) * itemSpacing) - leftRightInset) / numberOfPhotos)
        return CGSize(width: kWhateverHeightYouWant, height: kWhateverHeightYouWant)
    }
}

class PhotosCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func prepareForReuse() {
        imageView.image = nil
        self.activityIndicator.stopAnimating()
    }
    
}


