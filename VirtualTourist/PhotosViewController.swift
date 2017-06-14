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
import CoreData

class PhotosViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var barButton: UIBarButtonItem!
   
    var tappedPin: Pin?
    var coordinate: CLLocationCoordinate2D?
    var latitude: Double?
    var longitude: Double?
    
    // Store the data in the "photo" array (from JSON). Populated in loadPhotos()
    var urlArray = [String]()
    
    // Store the photo entities in an array. This array is associated with the context, so when there are objects in this array, you can save them by saving the context.
    var photoEntityArray = [Photo]()
    
    // Store an array of cells that the user tapped to be deleted.
    var tappedIndexPaths = [IndexPath]()
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    
    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
       
        // Create a fetch request
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fr.sortDescriptors = [NSSortDescriptor(key: "imageData", ascending: true)]
        
        // Specify that we only want the photos associated with the tapped pin. (pin is the relationships)
        fr.predicate = NSPredicate(format: "pin = %@", self.tappedPin!)
        
        // Create the FetchedResultsController
        return NSFetchedResultsController(fetchRequest: fr, managedObjectContext: self.stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
    }()
    
    // Get the stack
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    
    override func viewDidLoad() {
        showPin()
        
        // Check if this pin has photos stored in Core Data. If not, then load photos from Flickr. Otherwise, fetch the photos from Core Data.
//        let fetchedObjects = fetchedResultsController.fetchedObjects
//        if fetchedObjects?.count == 0 {
//            loadPhotosFromFlickr()
//        } else {
//            fetchPhotosFromCoreData()
//        }
        
        loadPhotosFromFlickr()
        
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
    
    func loadPhotosFromFlickr() {
        
        FlickrClient.sharedInstance().getLocationPhotos(latitude: latitude!, longitude: longitude!) { (success, urlArray, error) in
                
            if success {
                
                if let unwrappedUrlArray = urlArray {
                    self.urlArray = unwrappedUrlArray
                }
                
                for url in urlArray! {
                    var photo = Photo(pin: self.tappedPin!, imageURL: url, context: self.stack.context)
                    self.photoEntityArray.append(photo)
                }
                
                do {
                    try self.stack.context.save()
                } catch {
                    print("Error saving the url")
                }
                
                DispatchQueue.main.async {
                   self.collectionView.reloadData()
                }

            } else {
                print("Error loading photos")
            }
        }
    }
    
    // Display the images specified by the fetch request and fetchedResultsController in viewDidLoad.
    func fetchPhotosFromCoreData() {
        
        self.fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Error while trying to perform a search: \n\(error)\n\(fetchedResultsController)")
        }

        let fetchedObjects = fetchedResultsController.fetchedObjects
        
        for fetchedObject in fetchedObjects! {
            let object = fetchedObject as! Photo
            self.photoEntityArray.append(object)
        }
    }
    
    // Delete the photos selected by the user. 
    func deleteSelectedPhotos() {
        
        // Delete the photos corresponding to the indexes stored in self.tappedIndexPaths (populated in didSelectItemAt)
        for indexPath in tappedIndexPaths {
            
            urlArray.remove(at: indexPath.row)

            // stack.context.delete(fetchedResultsController?.object(at: indexPath as IndexPath) as! Photo)
        }

        collectionView.reloadData()
    }
    
    
    @IBAction func barButtonPressed(_ sender: Any) {
        
        if barButton.title == "Remove selected pictures" {

            deleteSelectedPhotos()
            
            self.barButton.title = "Refresh collection"
            
        } else {
            print("refresh collection")
        }
    }

}

// MARK: UICollectionViewDataSource
extension PhotosViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return self.photoEntityArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoViewCell
        
        // For each cell, retrieve the image corresponding to the cell's indexPath.
        let photoToLoad = photoEntityArray[indexPath.row]
        // let photoToLoad = fetchedResultsController!.object(at: indexPath) as! Photo
    
        let url = photoToLoad.imageURL
        
        // Download the image at the url
        FlickrClient.sharedInstance().downloadPhotoWith(url: url!) { (success, image, error) in
            cell.imageView.image = image
        }

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
        
        // Whenever user selects one or more cells, the bar button changes to Remove seleceted pictures
        self.barButton.title = "Remove selected pictures"
        
        self.tappedIndexPaths.append(indexPath)
    }
    
}

// MARK: NSFetchedResultsControllerDelegate
extension PhotosViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        print("didChange anObject")
        
        switch type {
            
        case NSFetchedResultsChangeType.insert:
            insertedIndexPaths.append(newIndexPath! as NSIndexPath)
            
        case NSFetchedResultsChangeType.delete:
            deletedIndexPaths.append(newIndexPath! as NSIndexPath)
            
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        collectionView.performBatchUpdates({
            for indexPath in self.insertedIndexPaths{
                self.collectionView.insertItems(at: [indexPath as IndexPath])
            }
            
            for indexPath in self.deletedIndexPaths{
                self.collectionView.deleteItems(at: [indexPath as IndexPath])
            }

        }, completion: nil)
        
    }

}
