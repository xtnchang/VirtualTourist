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

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        activateGestureRecognizer()
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
            let coordinate = mapView.convert(pressedLocation, toCoordinateFrom: mapView)
            
            // Add the CLLocationCoordinate2D to the map.
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            self.mapView.addAnnotation(annotation)
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
        
        self.present(controller, animated: true, completion: nil)
    }

}






