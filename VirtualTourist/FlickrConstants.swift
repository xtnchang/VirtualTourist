//
//  FlickrConstants.swift
//  VirtualTourist
//
//  Created by Christine Chang on 4/24/17.
//  Copyright © 2017 Christine Chang. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    // Sample URL: https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=d592362beec3f98703d88ff5d1d35647&format=json&nojsoncallback=1&auth_token=72157680012118213-ba4752877870d261&api_sig=dcce79813ac936e6ffa88f687efece01
    
    // MARK: URL Constants
    struct Constants {
        static let APIScheme = "https"
        static let APIHost = "api.flickr.com"
        static let APIPath = "/services/rest/?"
    }
    
    // MARK: Flickr Query String Parameter Keys
    struct FlickrParameterKeys {
        static let Method = "method="
        static let APIKey = "api_key="
        static let GalleryID = "gallery_id="
        static let Extras = "extras="
        static let Format = "format="
        static let NoJSONCallback = "nojsoncallback="
        static let SafeSearch = "safe_search="
        static let Text = "text="
        static let BoundingBox = "bbox="
        static let Page = "page="
    }
    
    // MARK: Flickr Query String Parameter Values
    struct FlickrParameterValues {
        static let SearchMethod = "flickr.photos.search"
        static let APIKey = "f586ce4eaedba683f3919ab7a27f2aa9"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1" /* 1 means "yes" */
        static let GalleryPhotosMethod = "flickr.galleries.getPhotos"
        static let GalleryID = "5704-72157622566655097"
        static let MediumURL = "url_m"
        static let UseSafeSearch = "1"
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
