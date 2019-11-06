//
//  DataController.swift
//  VirtualTourist
//
//  Created by Anna Koulaeva on 01.11.2019.
//  Copyright © 2019 Anna Koulaeva. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class DataController {
    
    let persistentContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func configureContexts() {
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.configureContexts()
            completion?()
        }
    }
    
    func fetchRecordsForEntity(_ entity: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext, predicate: NSPredicate?) -> [NSManagedObject] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        if let predicate = predicate {
            fetchRequest.predicate = predicate
        }
        var result = [NSManagedObject]()
        do {
            let records = try managedObjectContext.fetch(fetchRequest)
            if let records = records as? [NSManagedObject] {
                result = records
            }
        }
        catch {
            print("Unable to fetch managed objects for entity \(entity).")
        }
        return result
    }
    
    func saveContext() {
        do {
            try self.viewContext.save()
        }
        catch {
            print(error.localizedDescription)
        }
    }
}
