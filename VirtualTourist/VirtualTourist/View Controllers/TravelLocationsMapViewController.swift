//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Anna Koulaeva on 01.11.2019.
//  Copyright © 2019 Anna Koulaeva. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var dataController: DataController!
    var pins: [Pin] = []
    var fetchedImagesController: NSFetchedResultsController<Photo>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longTap))
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        pins = fetchRecordsForEntity("Pin", inManagedObjectContext: dataController.viewContext) as! [Pin]
        placeSavedPins()
        let currentCenterArr = fetchRecordsForEntity("Map", inManagedObjectContext: dataController.viewContext)
        if (currentCenterArr.count > 0) {
            let currentCenter = currentCenterArr[0] as! Map
            mapView.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: currentCenter.centerLatitude, longitude: currentCenter.centerLongitude), span: MKCoordinateSpan(latitudeDelta: currentCenter.latitudeDelta, longitudeDelta: currentCenter.longitudeDelta))
        }
    }
    
    func setupFetchedResultsController(pin: Pin) {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedImagesController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "lat: \(pin.latitude) lon: \(pin.longitude)")
        fetchedImagesController.delegate = self
        dataController!.backgroundContext.perform {
            do {
                try self.fetchedImagesController.performFetch()
            }
            catch {
                fatalError("The fetch could not be performed: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchRecordsForEntity(_ entity: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> [NSManagedObject] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
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
    
    func placeSavedPins() {
        for pin in pins {
            MyPointAnnotation.putPin(mapView: mapView, pin: pin)
        }
    }
    
    @objc func longTap(sender: UITapGestureRecognizer){
        if sender.state == .began {
            let locationInView = sender.location(in: mapView)
            let locationOnMap = mapView.convert(locationInView, toCoordinateFrom: mapView)
            addAnnotation(location: locationOnMap)
        }
    }
    
    func addAnnotation(location: CLLocationCoordinate2D) {
        let newPin = Pin(context: dataController.viewContext)
        newPin.latitude = location.latitude
        newPin.longitude = location.longitude
        MyPointAnnotation.putPin(mapView: mapView, pin: newPin)
        dataController.saveContext()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return MyPointAnnotation.viewForAnnotation(annotation: annotation)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        var centerArr = fetchRecordsForEntity("Map", inManagedObjectContext: dataController.viewContext) as! [Map]
        var currentCenter: Map!
        if centerArr.count > 0 {
            currentCenter = centerArr[0]
        }
        else {
            currentCenter = Map(context: dataController.viewContext)
        }
        currentCenter.setValuesForKeys(["longitudeDelta": mapView.region.span.longitudeDelta, "latitudeDelta": mapView.region.span.latitudeDelta, "centerLatitude": mapView.region.center.latitude, "centerLongitude": mapView.region.center.longitude])
        dataController.saveContext()
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let photoAlbumVC = storyboard!.instantiateViewController(withIdentifier: "photoVC") as! PhotoAlbumViewController
        let myAnnotation = view.annotation as! MyPointAnnotation
        let latitude = myAnnotation.pin.latitude
        let longitude = myAnnotation.pin.longitude
        photoAlbumVC.currentPin = myAnnotation.pin
        setupFetchedResultsController(pin: myAnnotation.pin)
        if let sections = fetchedImagesController.sections, sections.count > 0, sections[0].numberOfObjects > 0 {
            photoAlbumVC.fetchedImagesController = fetchedImagesController
            self.navigationController!.pushViewController(photoAlbumVC, animated: true)
        }
        else {
            FlickrApiClient.getImageUrls(latitude: latitude, longitude: longitude) {(result, title, error) in
                guard let urls = result, let titles = title else {
                    print(error!.localizedDescription)
                    return
                }
                photoAlbumVC.imageUrls = urls
                photoAlbumVC.titles = titles
                photoAlbumVC.dataController = self.dataController
                self.navigationController!.pushViewController(photoAlbumVC, animated: true)
            }
        }
    }
}
