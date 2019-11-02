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
        let mapCenters = fetchRecordsForEntity("Map", inManagedObjectContext: dataController.viewContext) as! [Map]
        if mapCenters.count == 1 {
            let mapCenter = mapCenters[0]
            let span = MKCoordinateSpan(latitudeDelta: mapCenter.latitudeDelta, longitudeDelta: mapCenter.longitudeDelta)
            let newRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: mapCenter.centerLatitude, longitude: mapCenter.centerLatitude), span: span)
            mapView.region = newRegion
        }
        placeSavedPins()
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
            putPin(location: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude))
        }
    }
    
    @objc func longTap(sender: UITapGestureRecognizer){
        if sender.state == .began {
            let locationInView = sender.location(in: mapView)
            let locationOnMap = mapView.convert(locationInView, toCoordinateFrom: mapView)
            addAnnotation(location: locationOnMap)
        }
    }

    func putPin(location: CLLocationCoordinate2D) {
        let annotation = MyPointAnnotation(coordinate: location, color: .red)
        mapView.addAnnotation(annotation)
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
        putPin(location: location)
        let newPin = Pin(context: dataController.viewContext)
        newPin.latitude = location.latitude
        newPin.longitude = location.longitude
        saveContext()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? MyPointAnnotation
        {
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "")
            view.animatesDrop = true
            view.pinTintColor = annotation.color
            view.canShowCallout = false
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        var mapCenters = fetchRecordsForEntity("Map", inManagedObjectContext: dataController.viewContext) as! [Map]
        if mapCenters.count == 0 {
            let mapCenter = Map(context: dataController.viewContext)
            mapCenter.longitudeDelta = mapView.region.span.longitudeDelta
            mapCenter.latitudeDelta = mapView.region.span.latitudeDelta
            mapCenter.centerLatitude = mapView.region.center.latitude
            mapCenter.centerLongitude = mapView.region.center.longitude
        }
        if mapCenters.count == 1 {
            let mapCenter = mapCenters[0]
            mapCenter.longitudeDelta = mapView.region.span.longitudeDelta
            mapCenter.latitudeDelta = mapView.region.span.latitudeDelta
            mapCenter.centerLatitude = mapView.region.center.latitude
            mapCenter.centerLongitude = mapView.region.center.longitude
        }
        saveContext()
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("here")
    }
}
