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
    
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the fetchedResultsController is initialized with a new fetchRequest, we reload the map view?
            // The protocol is NSFetchedResultsControllerDelegate, which PhotosViewController conforms to (see extension).
            fetchedResultsController?.delegate = self
        }
    }
    
    // Get the stack
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        activateGestureRecognizer()
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fr.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
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
//            self.annotation = MKPointAnnotation()
//            self.annotation?.coordinate = self.coordinate!
//            self.mapView.addAnnotation(annotation!)
            print("adding pin")
            
            // Store the latitude and longitude values for Flickr query string parameters later
            self.latitude = self.coordinate?.latitude
            self.longitude = self.coordinate?.longitude
            
            // Instantiate a Pin object
            let newPin = Pin(latitude: self.latitude!, longitude: self.longitude!, context: stack.context)
            
            // Save the pin
            do {
                
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

}

// MARK: MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
    
    // When user taps a pin, move to the next view controller
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "PhotosViewController") as! PhotosViewController
        
        // To stay in the navigation stack, use push instead of present.
        // http://stackoverflow.com/questions/24038215/how-to-navigate-from-one-view-controller-to-another-using-swift
        self.navigationController?.pushViewController(controller, animated: true)
        
        // Pass the coordinate information to the PhotosViewController
        controller.coordinate = self.coordinate
        controller.latitude = self.latitude
        controller.longitude = self.longitude
        
        // Deselect the pin so that it's selectable again when we return from PhotosViewController
        self.mapView.deselectAnnotation(self.annotation, animated: true)
    }

}

// MARK: NSFetchedResultsControllerDelegate
extension MapViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        print("didChange anObject")
        switch type {
            
        case .delete:
            // do something on main thread
            print("delete")
        case .insert:
            DispatchQueue.main.async {
                // Add the CLLocationCoordinate2D to the map.
                self.annotation = MKPointAnnotation()
                self.annotation?.coordinate = self.coordinate!
                self.mapView.addAnnotation(self.annotation!)
            }
            
        default:
            print("Default")
        }
        
        
        
    }
}




