//
//  PhotosViewController.swift
//  VirtualTourist
//
//  Created by Christine Chang on 4/24/17.
//  Copyright © 2017 Christine Chang. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class PhotosViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var barButton: UIBarButtonItem!
   
    var coordinate: CLLocationCoordinate2D?
    var latitude: Double?
    var longitude: Double?
    
    // Store the data in the "photo" array (from JSON)
    var photoArray = [[String : AnyObject]]()
    
    // Store an array of cells that the user tapped to be deleted.
    var indexPathArray = [IndexPath]()
    
    override func viewDidLoad() {
        showPin()
        loadPhotos()
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    func showPin() {
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate!
        mapView.addAnnotation(annotation)
        
        // Zoom map to the correct region for showing the pin
        self.mapView.centerCoordinate = self.coordinate!
        // Instantiate an MKCoordinateSpanMake to pass into MKCoordinateRegion
        let coordinateSpan = MKCoordinateSpanMake(80,80)
        // Instantiate an MKCoordinateRegion to pass into setRegion.
        let coordinateRegion = MKCoordinateRegion(center: coordinate!, span: coordinateSpan)
        self.mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func loadPhotos() {
        
        FlickrClient.sharedInstance().getLocationPhotos(latitude: latitude!, longitude: longitude!) { (success, photoDataArray, error) in
                
            if success {
                
                if let unwrappedPhotoDataArray = photoDataArray {
                    self.photoArray = unwrappedPhotoDataArray
                }
                
                DispatchQueue.main.async {
                   self.collectionView.reloadData()
                }

            } else {
                print("Error loading photos")
            }
        }
    }
    
    
    @IBAction func barButtonPressed(_ sender: Any) {
        
        if barButton.title == "Remove selected pictures" {
            print("remove selected cells")
            print(self.indexPathArray)
            // self.collectionView.deleteItems(at: self.indexPathArray)
            self.barButton.title = "Refresh collection"
        } else {
            print("refresh collection")
        }
    }

}

// MARK: UICollectionViewDataSource
extension PhotosViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return self.photoArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoViewCell
        
        // For each cell, retrieve the image corresponding to the cell's indexPath.
        let photoToLoad = photoArray[indexPath.row]
    
        // Download the image at the url
        if let url = photoToLoad["url_m"] as? String {
            downloadPhotoWith(url: url) { (image, error) in
                cell.imageView.image = image
            }
        }

        return cell
    }
    
    // Given a URL, get the UIImage to load in the collection view cell
    func downloadPhotoWith(url: String, completionHandlerForDownload: @escaping (_ image: UIImage?, _ error: Error?) -> Void) {
        
        let session = URLSession.shared
        
        // Convert the url string to URL so that it can be passed into dataTask(with url:)
        guard let photoURL = URL(string: url) else {
            completionHandlerForDownload(nil, nil)
            return
        }
        
        let task = session.dataTask(with: photoURL) { (data, response, error) in
            
            guard let data = data else {
                completionHandlerForDownload(nil, error)
                return
            }
            
            guard let image = UIImage(data: data) else {
                completionHandlerForDownload(nil, error)
                return
            }
            
            completionHandlerForDownload(image, nil)
        }
        
        task.resume()
    }
    
}

// MARK: UICollectionViewDelegate
extension PhotosViewController: UICollectionViewDelegate {
    
    // Things to do when a user taps photo cells
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // Fade out selected cells
        let cell = collectionView.cellForItem(at: indexPath as IndexPath)
        cell?.alpha = 0.5
        
        // Whenever user selects one or more cells, the bar button changes to Remove selecetd pictures
        self.barButton.title = "Remove selected pictures"
        
        self.indexPathArray.append(indexPath)
    }
    
}
