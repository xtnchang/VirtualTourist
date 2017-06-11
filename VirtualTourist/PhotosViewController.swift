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
    var photoArray = [[String : AnyObject]]()
    
    // Store an array of cells that the user tapped to be deleted.
    var tappedIndexPaths = [IndexPath]()
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    
    var deletedPhotoIds = [NSManagedObject]()
    
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            
            // The protocol is NSFetchedResultsControllerDelegate, which PhotosViewController conforms to (see extension).
            fetchedResultsController?.delegate = self
            
            // Whenever the frc changes (i.e. new fetch request passed in), we fetch the photos from the context.
            fetchPhotos()
            
            // Whenever performFetch is called on the fetchedResultsController (as it is in fetchPhotos()), we reload the collection view.
            collectionView.reloadData()
        }
    }
    
    // Get the stack
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    
    override func viewDidLoad() {
        super.viewDidLoad()
        retrieveDeletedPhotoIds()
        showPin()
        loadPhotos()
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Create a fetch request
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fr.sortDescriptors = [NSSortDescriptor(key: "imageData", ascending: true)]
        
        // Specify that we only want the photos associated with the tapped pin. (pin is the relationships)
        fr.predicate = NSPredicate(format: "pin = %@", tappedPin!)
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
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
                    
                    // https://stackoverflow.com/questions/41763790/array-filter-in-swift3
                    self.photoArray = unwrappedPhotoDataArray.filter({ (photoDictionary) -> Bool in
                        if let id = photoDictionary["id"] as? String {
                            
                            // https://developer.apple.com/documentation/swift/array/2297359-contains
                            return !self.deletedPhotoIds.contains(where: { (object) -> Bool in
                                return object.value(forKey: "photoId") as? String == id
                            })
                        }
                        return false
                    })
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
    func fetchPhotos() {
        
        if let frc = fetchedResultsController {
            do {
                try frc.performFetch()
            } catch let error as NSError {
                print("Error while trying to perform a search: \n\(error)\n\(fetchedResultsController)")
            }
        }
    }
    
    // Delete the photos selected by the user. 
    func deleteSelectedPhotos() {
        
        // Delete the photos corresponding to the indexes stored in self.tappedIndexPaths (populated in didSelectItemAt)
        for indexPath in tappedIndexPaths {
            
            let photo = photoArray[indexPath.row]
            if let photoId = photo["id"] as? String {
                saveDeletedPhotoId(id: photoId)
            }
            
            photoArray.remove(at: indexPath.row)

            // stack.context.delete(fetchedResultsController?.object(at: indexPath as IndexPath) as! Photo)
        }

        collectionView.reloadData()
    }
    
    func saveDeletedPhotoId(id: String) {

        if let entity = NSEntityDescription.entity(forEntityName: "DeletedPhotos", in: stack.context) {
            let photoId = NSManagedObject(entity: entity, insertInto: stack.context)
            deletedPhotoIds.append(photoId)
            photoId.setValue(id, forKey: "photoId")
            do {
                try stack.context.save()
            }
            catch {
                print(error.localizedDescription)
            }
        }
        
    }
    
    func retrieveDeletedPhotoIds() {
        let managedContext = stack.context
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DeletedPhotos")
        do {
            deletedPhotoIds = try managedContext.fetch(fetchRequest)
        }
        catch {
            print("fetch error")
        }
    }
    
    
    @IBAction func barButtonPressed(_ sender: Any) {
        
        if barButton.title == "Remove selected pictures" {

            deleteSelectedPhotos()
            
            self.barButton.title = "Refresh collection"
            
            collectionView.reloadData()
            
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
        // let photoToLoad = fetchedResultsController!.object(at: indexPath) as! Photo
    
        // Download the image at the url
        if let url = photoToLoad["url_m"] as? String {
            self.downloadPhotoWith(url: url) { (image, error) in
                cell.imageView.image = image
            }
        }

        // Save to Core Data
        do {
            try self.stack.context.save()
        } catch {
            print("error")
        }

        return cell
    }
    
    // Helper method: given a URL, get the UIImage to load in the collection view cell
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
            
//            DispatchQueue.main.async {
//                
//                // Instantiate a Photo object
//                let photo = Photo(imageData: data as NSData, context: self.stack.context)
//                photo.pin = self.tappedPin
//            }
        
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
