//
//  FlickrConstants.swift
//  VirtualTourist
//
//  Created by Christine Chang on 4/24/17.
//  Copyright © 2017 Christine Chang. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    // Sample URL: https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=d592362beec3f98703d88ff5d1d35647&lat=37.3230&lon=122.0322&extras=url_m&format=json&nojsoncallback=1&auth_token=72157680012118213-ba4752877870d261&api_sig=6ee37e6fd4510f67a1a1472c875a0330
    
    // MARK: URL Constants
    struct Constants {
        // Hardcode as "https" instead of "https://" because flickrURLFromParameters() takes care of it.
        static let APIScheme = "https"
        static let APIHost = "api.flickr.com"
        static let APIPath = "/services/rest/"
    }
    
    // MARK: Flickr Query String Parameter Keys
    struct FlickrParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let GalleryID = "gallery_id"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let SafeSearch = "safe_search"
        static let Text = "text"
        static let BoundingBox = "bbox"
        static let PerPage = "per_page"
        static let Page = "page"
        static let Latitude = "lat"
        static let Longitude = "lon"
    }
    
    // MARK: Flickr Query String Parameter Values
    struct FlickrParameterValues {
        static let SearchMethod = "flickr.photos.search"
        static let APIKey = "b42cff4bc2e5dc3dbae03f49bda70791"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1" /* 1 means "yes" */
        static let GalleryPhotosMethod = "flickr.galleries.getPhotos"
        static let GalleryID = "5704-72157622566655097"
        static let MediumURL = "url_m" // includes the photo URL in the response body
        static let UseSafeSearch = "1"
        static let PerPage = "20"
        /* static let Page = "\(arc4random_uniform(10))" */
    }
    
    // MARK: Flickr HTTP Response Keys
    struct FlickrResponseKeys {
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let Title = "title"
        static let MediumURL = "url_m"
        static let Pages = "pages"
        static let Total = "total"
    }
    
    // MARK: Flickr HTTP Response Values
    struct FlickrResponseValues {
        static let OKStatus = "ok"
    }
}
