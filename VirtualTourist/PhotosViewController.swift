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
    
    // Store an array of the Flickr images to load.
    var photosToLoad = [Data]()
    
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
                    
                print("Load photos in collection view")
                print(photoDataArray ?? 0)
                self.photosToLoad = photoDataArray!

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
        
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoViewCell
        
        // For each cell, load the image corresponding to the cell's indexPath.
        let cellPhoto = photosToLoad[indexPath.item]
        
        cell.imageView.image = UIImage(data: cellPhoto)

        return cell
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
