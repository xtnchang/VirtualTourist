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
    
    // Store the photo entities in an array.
    var photoEntityArray = [Photo]()
    
    // Store an array of cells that the user tapped to be deleted.
    var tappedIndexPaths = [IndexPath]()
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    
    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
       
        // Create a fetch request to specify what objects this fetchedResultsController tracks.
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fr.sortDescriptors = [NSSortDescriptor(key: "imageData", ascending: true)]
        
        // Specify that we only want the photos associated with the tapped pin. (pin is the relationships)
        fr.predicate = NSPredicate(format: "pin = %@", self.tappedPin!)
        
        // Create and return the FetchedResultsController
        return NSFetchedResultsController(fetchRequest: fr, managedObjectContext: self.stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
    }()
    
    // Get the stack
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    
    override func viewDidLoad() {
        showPin()
        
        fetchedResultsController.delegate = self
        
        // Check if this pin has photos stored in Core Data.
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Error while trying to perform a search: \n\(error)\n\(fetchedResultsController)")
        }
        
        let fetchedObjects = fetchedResultsController.fetchedObjects
        
        // If this pin has no photos stored in Core Data, then load photos from Flickr. Otherwise, fetch the photos from Core Data.
        if fetchedObjects?.count == 0 {
            loadPhotosFromFlickr()
        } else {
            fetchPhotosFromCoreData()
        }
        
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
                
                for url in urlArray! {
                    
                    // Since we insert the photo to the context, the frc now knows about it and tracks it as one of its objects. The context is like the database, and the frc updates the UI in real time.
                    let photo = Photo(pin: self.tappedPin!, imageURL: url, context: self.stack.context)
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

        let fetchedObjects = fetchedResultsController.fetchedObjects
        
        for fetchedObject in fetchedObjects! {
            let object = fetchedObject as! Photo
            self.photoEntityArray.append(object)
        }
    }
    
    // Delete the photos selected by the user from Core Data.
    func deleteSelectedPhotos() {
        
        // Delete the photos corresponding to the indexes stored in self.tappedIndexPaths (populated in didSelectItemAt)
        for indexPath in tappedIndexPaths {
            
            // photoEntityArray.remove(at: indexPath.row)
            stack.context.delete(fetchedResultsController.object(at: indexPath as IndexPath) as! Photo)
        }
        
        do {
            try stack.context.save()
        } catch {
            print("Error saving the context after deleting photos")
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
        
        // return self.photoEntityArray.count
        // Return the number of objects in Core Data
        // https://www.youtube.com/watch?v=0JJJ2WGpw_I (8:30)
        return fetchedResultsController.sections![0].numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoViewCell
        
        // For each cell, retrieve the image corresponding to the cell's indexPath.
        // let photoToLoad = photoEntityArray[indexPath.row]
   
        // The frc should have access to to the photo URLs downloaded in loadPhotosFromFlickr().
        let photoToLoad = fetchedResultsController.object(at: indexPath) as! Photo
    
        // If no photo exists in Core Data, then download a photo from Flickr. If a photo exists for this indexPath in Core Data, then display the object in the fetchedResultsController.
        if photoToLoad.imageData == nil {
            FlickrClient.sharedInstance().downloadPhotoWith(url: photoToLoad.imageURL!) { (success, imageData, error) in
                
                // Core Data is not thread friendly; put in main thread.
                DispatchQueue.main.async {
                    cell.imageView.image = UIImage(data: imageData as! Data)
                    // Save the photo's corresponding imageData to Core Data.
                    photoToLoad.imageData = imageData
                    
                    do {
                        try self.stack.context.save()
                    } catch {
                        print("Error saving the imageData")
                    }
                }
            }
            
        // Else, photoToLoad.imageData already exists.
        } else {
            
            DispatchQueue.main.async {
                cell.imageView.image = UIImage(data: photoToLoad.imageData as! Data)
            }
        }
        
//        let url = photoToLoad.imageURL
//        
//        FlickrClient.sharedInstance().downloadPhotoWith(url: url!) { (success, imageData, error) in
//            cell.imageView.image = UIImage(data: imageData as! Data)
//        }

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
    
    // https://www.youtube.com/watch?v=0JJJ2WGpw_I (13:50-15:00)
    // This method is only called when anything in the context has been added or deleted. It collects the indexPaths that have changed. Then, in controllerDidChangeContent, the changes are applied to the UI. 
    // The indexPath value is nil for insertions, and the newIndexPath value is nil for deletions.
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
            
        case .insert:
            insertedIndexPaths.append(newIndexPath! as NSIndexPath)
            print("Inserted a new index path")
            
        case .delete:
            deletedIndexPaths.append(indexPath! as NSIndexPath)
            print("Deleted an index path")
            
        default:
            break
        }
    }
    
    // https://www.youtube.com/watch?v=0JJJ2WGpw_I (18:15)
    // Updates the UI so that it syncs up with Core Data. This method doesn't change anything in Core Data.
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
