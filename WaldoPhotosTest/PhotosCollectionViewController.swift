//
//  PhotosCollectionViewController.swift
//  WaldoPhotosTest
//
//  Created by Nanci Frank on 1/25/17.
//  Copyright © 2017 Wildcat Productions. All rights reserved.
//

import UIKit
import Apollo

private let reuseIdentifier = "imageViewCell"
private let bearerToken = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhY2NvdW50X2lkIjoiMmEyODQ4M2YtNWM2Yi00ZWU5LWE4YjUtYzFlMGU5NWUwYTY5Iiwicm9sZXMiOlsiYWRtaW5pc3RyYXRvciJdLCJpc3MiOiJ3YWxkbzpjb3JlIiwiZ3JhbnRzIjpbImFsYnVtczpkZWxldGU6KiIsImFsYnVtczpjcmVhdGU6KiIsImFsYnVtczplZGl0OioiLCJhbGJ1bXM6dmlldzoqIl0sImV4cCI6MTQ4Nzk3OTExMywiaWF0IjoxNDg1Mzg3MTEzfQ.3i4KWxNyCyGiKr2a1cWPbHAWSISDOg3ch8zOruY5Abg"

class PhotosCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var photoDataSource = [String?]()
    var offSetVal: Int = 50
    var loadingPhotos: Bool = false
    var allPhotosLoaded: Bool = false
    var isLoading: Bool = false
    
    var imageCache = NSCache<NSString, AnyObject>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Photo Album Viewer"
        fetchPhotoData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }
    
    func fetchPhotoData() {
        loadingPhotos = true
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["Authorization": bearerToken]
        
        let urlString = URL(string: "https://core-graphql.staging.waldo.photos/gql")
        let apollo = ApolloClient(networkTransport: HTTPNetworkTransport(url: urlString!, configuration: configuration))
        apollo.fetch(query: AlbumQuery(offset: offSetVal)) { [unowned self] (data, error) in
            if let error = error {
                NSLog("Error while fetching query: \(error.localizedDescription)")
                self.loadingPhotos = false
                return
            }
            if let data = data?.data {
                if let photos = data.album?.photos?.records {
                    let urls = photos.map { $0?.urls?[1]?.url }
                    self.photoDataSource.append(contentsOf: urls)
//                    print("photoDataSource: \(self.photoDataSource.count)")
                }
            } else {
               // To do: set all photos loaded to true
                self.allPhotosLoaded = true
            }
            self.collectionView?.reloadData()
            self.loadingPhotos = false
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !loadingPhotos else { return }
        
        let offsetY = scrollView.contentOffset.y
        let contentTrigger = scrollView.contentSize.height - scrollView.frame.size.height
        if offsetY > contentTrigger && offsetY > 0 {
//            print("offSetY: \(offsetY), contentTrigger: \(contentTrigger)")
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
        
        let url = photoDataSource[indexPath.item]
        cell?.activityIndicator.startAnimating()

        DispatchQueue.global().async {
            if let tempImage: NSData = NSData(contentsOf: URL(string: url!)!) {
                let image: UIImage = UIImage(data: tempImage as Data)!
                self.imageCache.setObject(image, forKey: NSString(string: url!))
                DispatchQueue.main.async (execute: {
                    cell?.activityIndicator.stopAnimating()
                    cell?.imageView.image = image
                    cell?.photoLabel.text = ""
//                    cell?.photoLabel.text = String(indexPath.item)
                })
            }
        }
    
        return cell!
    }
 
    // MARK: UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let kWhateverHeightYouWant = ((UIApplication.shared.keyWindow?.frame.width)! / 3) - 4
        return CGSize(width: kWhateverHeightYouWant, height: kWhateverHeightYouWant)
    }
}

class PhotosCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var photoLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func prepareForReuse() {
        imageView.image = nil
        self.activityIndicator.stopAnimating()
        photoLabel.text = ""
    }
    
}


