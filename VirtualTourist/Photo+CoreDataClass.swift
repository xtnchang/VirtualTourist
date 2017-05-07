//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Christine Chang on 5/6/17.
//  Copyright © 2017 Christine Chang. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)
public class Photo: NSManagedObject {

    convenience init(imageData: NSData, context: NSManagedObjectContext) {
        
        // An EntityDescription is an object that has access to all the information you provided in the Entity part of the model.
        // You need it to create an instance of this class.
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: ent, insertInto: context)
            self.imageData = imageData
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
}
