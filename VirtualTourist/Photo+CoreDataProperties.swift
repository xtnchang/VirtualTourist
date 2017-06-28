//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Christine Chang on 5/6/17.
//  Copyright © 2017 Christine Chang. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var imageData: NSData?
    @NSManaged public var imageURL: String?
    @NSManaged public var pin: Pin?

}
