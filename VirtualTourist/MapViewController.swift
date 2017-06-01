//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Christine Chang on 4/24/17.
//  Copyright © 2017 Christine Chang. All rights reserved.
//

import Foundation 
import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var coordinate: CLLocationCoordinate2D?
    var annotation: MKPointAnnotation?
    var latitude: Double?
    var longitude: Double?
    var pin: Pin?
    
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? 
    
    // Get the stack
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        activateGestureRecognizer()
        
        // Create a fetch request
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fr.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        do {
            var pinsArray = try fr.execute()
            print(pinsArray.count)
        } catch {
            print(error.localizedDescription)
        }
        
        // Create the FetchedResultsController
//        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    // http://stackoverflow.com/questions/30858360/adding-a-pin-annotation-to-a-map-view-on-a-long-press-in-swift
    func addPin(gestureRecognizer: UILongPressGestureRecognizer) {
        
        // state is a property of UIGestureRecognizer (superclass of UILongPressGestureRecognizer)
        // The state property is of type UIGestureRecognizerState
        if gestureRecognizer.state == UIGestureRecognizerState.began {
            
            // The location method returns a CGPoint
            let pressedLocation = gestureRecognizer.location(in: mapView)
           
            // Convert the CGPoint to a CLLocationCoordinate2D
            // https://developer.apple.com/reference/mapkit/mkmapview/1452503-convert
            self.coordinate = mapView.convert(pressedLocation, toCoordinateFrom: mapView)
            
            // Add the CLLocationCoordinate2D to the map.
            self.annotation = MKPointAnnotation()
            self.annotation?.coordinate = self.coordinate!
            self.mapView.addAnnotation(annotation!)
            
            print("adding pin")
            
            // Store the latitude and longitude values for Flickr query string parameters later
            self.latitude = self.coordinate?.latitude
            self.longitude = self.coordinate?.longitude
            
            // Instantiate a Pin object
            let newPin = Pin(latitude: self.latitude!, longitude: self.longitude!, context: stack.context)
            
            // Save the pin
            do {
                
                // Does this save it to the database, or do I need to do something with the persistent store?
                try stack.context.save()
            } catch {
                print("error")
            }
        }
    }
    
    // You must activate UIGestureRecognizer in order for addPin to work.
    func activateGestureRecognizer() {
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(addPin(gestureRecognizer:)))
        longPress.minimumPressDuration = 1.0
        
        // https://developer.apple.com/reference/uikit/uiview/1622496-addgesturerecognizer
        mapView.addGestureRecognizer(longPress)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier! == "displayPhotos" {
            
            if let photosVC = segue.destination as? PhotosViewController {
                
                // Create a fetch request to fetch the photos for this pin.
                let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
                
                fr.sortDescriptors = [NSSortDescriptor(key: "imageData", ascending: true)]
                
                // Use the predicate to indicate that you only want to display the photos for this pin. Is the predicate format the relationship name?
                let pred = NSPredicate(format: "pin = %@", argumentArray: [])
                
                fr.predicate = pred
                
                // How do I specify which photos I want to inject/display?
                let photoArray = [["??":"??"]]
                
                // Create a fetchedResultsController for PhotosVC. Do I need to do this if I already create a fetchedResultsController in PhotosVC's viewDidLoad?
                let fc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: "humanReadableAge", cacheName: nil)
                
                // Inject it into the photosVC
                photosVC.fetchedResultsController = fc
                
                // Inject the photos too!
                photosVC.photoArray = photoArray as [[String : AnyObject]]
            }
        }
    }
}

// MARK: MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
    
    // When user taps a pin, move to the next view controller
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "PhotosViewController") as! PhotosViewController
        
        self.navigationController?.show(controller, sender: navigationController)
        
        // Pass the coordinate information to the PhotosViewController
        controller.coordinate = self.coordinate
        controller.latitude = self.latitude
        controller.longitude = self.longitude
        
        // Deselect the pin so that it's selectable again when we return from PhotosViewController
        self.mapView.deselectAnnotation(self.annotation, animated: true)
    }

}
