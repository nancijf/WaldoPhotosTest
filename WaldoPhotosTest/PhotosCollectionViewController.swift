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

class PhotosCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var photoDataSource = [String?]()
    var offSetVal: Int = 0
    var loadingPhotos: Bool = false
    var allPhotosLoaded: Bool = false
    
    lazy var flowLayout: UICollectionViewFlowLayout = {
        return self.collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
    }()
    
    var networkIsReachable: Bool = false
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
        imageCache.removeAll()
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
        
        self.imageCache.removeAll() // Clear image cache if memory low
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
     If no errors, retrieve URL for small2X for each record
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
            
            if let data = data?.data {
                if let photos = data.album?.photos?.records, photos.count > 0 {
                    if let title = data.album?.name {
                        self.navigationItem.title = title + " Photos"
                    } else {
                        self.navigationItem.title = "Photo Album Viewer"
                    }
                    let urls = photos.map { $0?.urls?[1]?.url }
                    self.photoDataSource.append(contentsOf: urls)
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
        
        // Check for data then if data is already stored in cache
        guard let url = photoDataSource[indexPath.item] else { return cell! }
        if let image = imageCache[url] {
            cell?.imageView.image = image
            cell?.activityIndicator.stopAnimating()
        } else {
            
            // Download image data and store in cache
            DispatchQueue.global().async {
                if let tempImage: NSData = NSData(contentsOf: URL(string: url)!) {
                    let image: UIImage = UIImage(data: tempImage as Data)!
                    self.imageCache[url] = image
                    DispatchQueue.main.async (execute: {
                        cell?.activityIndicator.stopAnimating()
                        cell?.imageView.image = image
                    })
                } else {
                    
                // if image can't be downloaded, ude default image
                    self.imageCache[url] = UIImage(named: "BrokenImage")
                    DispatchQueue.main.async (execute: {
                        cell?.activityIndicator.stopAnimating()
                        cell?.imageView.image = UIImage(named: "BrokenImage")
                    })
                }
            }
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


