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
    var tappedPin: Pin?
    
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? 
    
    // Get the stack
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        // Enable user to add a pin
        activateGestureRecognizer()
        
        // Create a fetch request
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fr.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        // Fetch the Pin objects in the context.
        do {
            let pinsArray = try stack.context.fetch(fr)
            print(pinsArray)
        } catch {
            print(error.localizedDescription)
        }
        
        // Don't need a fetchedResultsController for map view
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
            let pin = Pin(latitude: self.latitude!, longitude: self.longitude!, context: stack.context)
            
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier! == "displayPhotos" {
            
            if let photosVC = segue.destination as? PhotosViewController {
                
                // Pass the pin information to the next view controller
                photosVC.tappedPin = self.tappedPin
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
        
        // Pass the tapped pin coordinates to the PhotosViewController
        controller.coordinate = view.annotation?.coordinate
        controller.latitude = view.annotation?.coordinate.latitude
        controller.longitude = view.annotation?.coordinate.longitude

        
        // Pass the tapped pin object to the PhotosViewController
        self.tappedPin = Pin(latitude: (view.annotation?.coordinate.latitude)!, longitude: (view.annotation?.coordinate.longitude)!, context: stack.context)
        controller.tappedPin = self.tappedPin
        
        // Deselect the pin so that it's selectable again when we return from PhotosViewController
        self.mapView.deselectAnnotation(self.annotation, animated: true)
    }

}
