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

class PhotosCollectionViewController: UICollectionViewController {
    
    typealias Record = AlbumQuery.Data.Album.Photo.Record
    var photoDataSource = [String?]()
    var offSetVal: Int = 50

    override func viewDidLoad() {
        super.viewDidLoad()
//        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["Authorization": bearerToken]
        
        let urlString = URL(string: "https://core-graphql.staging.waldo.photos/gql")
        let apollo = ApolloClient(networkTransport: HTTPNetworkTransport(url: urlString!, configuration: configuration))
        apollo.fetch(query: AlbumQuery(offset: offSetVal)) { (data, error) in
            if let error = error { NSLog("Error while fetching query: \(error.localizedDescription)");  return }
            if let data = data?.data {
                if let photos = data.album?.photos?.records {
                    let urls = photos.map { $0?.urls?[1]?.url }
                    self.photoDataSource.append(contentsOf: urls)
//                    print(self.photoDataSource)
                }
            }
            self.collectionView?.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return photoDataSource.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? PhotosCollectionViewCell
        
        let url = photoDataSource[indexPath.item]
        if let tempImage: NSData = NSData(contentsOf: URL(string: url!)!) {
            let image: UIImage = UIImage(data: tempImage as Data)!
            DispatchQueue.main.async (execute: {
                cell?.imageView.image = image
            })
        }
        // Configure the cell
    
        return cell!
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}

class PhotosCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    
    override func prepareForReuse() {
        let nothing: UIImage? = nil
        imageView.image = nothing
    }
    
}


