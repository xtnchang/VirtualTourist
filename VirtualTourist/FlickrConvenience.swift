//
//  FlickrConvenience.swift
//  VirtualTourist
//
//  Created by Christine Chang on 4/24/17.
//  Copyright © 2017 Christine Chang. All rights reserved.
//

import Foundation
import UIKit

extension FlickrClient {
    
    // The HTTP response for the photos is a dictionary.
    func getLocationPhotos(latitude: Double, longitude: Double, completionHandlerForPhotos: @escaping (_ success: Bool, _ urlArray: [String]?, _ error: NSError?) -> Void) {
        
        let latString = String(describing: latitude)
        let lonString = String(describing: longitude)
        
        // Build the query string parameters to pass into taskForGET.
        let parameters = FlickrParameterKeys.Method + FlickrParameterValues.SearchMethod + "&" + FlickrParameterKeys.APIKey + FlickrParameterValues.APIKey + "&" + FlickrParameterKeys.Latitude + latString + "&" + FlickrParameterKeys.Longitude + lonString + "&" + FlickrParameterKeys.Extras + FlickrParameterValues.MediumURL + "&" + FlickrParameterKeys.Format + FlickrParameterValues.ResponseFormat + "&" + FlickrParameterKeys.NoJSONCallback + FlickrParameterValues.DisableJSONCallback + "&" + FlickrParameterKeys.PerPage + FlickrParameterValues.PerPage
        
        taskForGETMethod(parameters: parameters) { (deserializedData, error) in
            
            func sendError(error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandlerForPhotos(false, nil, NSError(domain: "completionHandlerForGET", code: 1, userInfo: userInfo))
            }
            
            guard (error == nil) else {
                sendError(error: "There was an error with your request: \(error?.localizedDescription)")
                return
            }
            
            guard (deserializedData != nil) else {
                sendError(error: "No results were found.")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = deserializedData?[FlickrResponseKeys.Status] as? String, stat == FlickrResponseValues.OKStatus else {
                sendError(error: "Flickr API returned an error. See error code and message in \(deserializedData)")
                return
            }
            
            /* GUARD: Are the "photos" and "photo" keys in our result? */
            guard let photosContainer = deserializedData?[FlickrResponseKeys.Photos] as? [String:AnyObject], let photosArray = photosContainer[FlickrResponseKeys.Photo] as? [[String:AnyObject]] else {
                sendError(error: "Cannot find keys '\(FlickrResponseKeys.Photos)' and '\(FlickrResponseKeys.Photo)' in \(deserializedData)")
                return
            }
            
            var urlArray = [String]()
            
            for photo in photosArray {
                guard let url = photo[FlickrResponseKeys.MediumURL] as? String else {
                    sendError(error: "Cannot find url")
                    return
                }
                
                urlArray.append(url)
            }
            
            // In this completion handler, we just retrieve the photosArray (urls) rather than downloading the actual images themselves (type Data), because that is very resource intensive and causes the images to load very slowly.
            
            completionHandlerForPhotos(true, urlArray, nil)
            
        }
    }
    
    // Helper method: given a URL, get the UIImage to load in the collection view cell
    func downloadPhotoWith(url: String, completionHandlerForDownload: @escaping (_ success: Bool, _ image: UIImage?, _ error: Error?) -> Void) {
        
        let session = URLSession.shared
        
        // Convert the url string to URL so that it can be passed into dataTask(with url:)
        let photoURL = URL(string: url)
        
        let task = session.dataTask(with: photoURL!) { (data, response, error) in
            
            guard let data = data else {
                completionHandlerForDownload(false, nil, error)
                return
            }
            
            guard let image = UIImage(data: data) else {
                completionHandlerForDownload(false, nil, error)
                return
            }
            
            //            DispatchQueue.main.async {
            //                let photo = Photo(imageData: data as NSData, context: self.stack.context)
            //                photo.pin = self.tappedPin
            //            }
            
            completionHandlerForDownload(true, image, nil)
        }
        
        task.resume()
    }
    
}
