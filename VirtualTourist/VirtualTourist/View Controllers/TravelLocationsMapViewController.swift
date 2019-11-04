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

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var dataController: DataController!
    var pins: [Pin] = []
    
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
    
    private func fetchRecordsForEntity(_ entity: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> [NSManagedObject] {
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
            MyPointAnnotation.putPin(location: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude), mapView: mapView)
        }
    }
    
    @objc func longTap(sender: UITapGestureRecognizer){
        if sender.state == .began {
            let locationInView = sender.location(in: mapView)
            let locationOnMap = mapView.convert(locationInView, toCoordinateFrom: mapView)
            addAnnotation(location: locationOnMap)
        }
    }
    
    fileprivate func saveContext() {
        do {
            try dataController.viewContext.save()
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func addAnnotation(location: CLLocationCoordinate2D) {
        MyPointAnnotation.putPin(location: location, mapView: mapView)
        let newPin = Pin(context: dataController.viewContext)
        newPin.latitude = location.latitude
        newPin.longitude = location.longitude
        saveContext()
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
        currentCenter.setValuesForKeys(["longitudeDelta" : mapView.region.span.longitudeDelta, "latitudeDelta" : mapView.region.span.latitudeDelta, "centerLatitude" : mapView.region.center.latitude, "centerLongitude" : mapView.region.center.longitude])
        saveContext()
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let photoAlbumVC = storyboard!.instantiateViewController(withIdentifier: "photoVC") as! PhotoAlbumViewController
        let myAnnotation = view.annotation as! MyPointAnnotation
        photoAlbumVC.currentPin = myAnnotation.coordinate
        FlickrApiClient.getImageUrls(latitude: myAnnotation.coordinate.latitude, longitude: myAnnotation.coordinate.longitude) {(result, error) in
                guard let urls = result else {
                    print(error!.localizedDescription)
                    return
                }
                photoAlbumVC.imageUrls = urls
                photoAlbumVC.dataController = self.dataController
                self.navigationController!.pushViewController(photoAlbumVC, animated: true)
            }
    }
}
