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
    var urls: [URL] = []
    var titles: [String] = []
    var fetchedImagesController: NSFetchedResultsController<Photo>!
    var picNum: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longTap))
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        pins = dataController.fetchRecordsForEntity("Pin", inManagedObjectContext: dataController.viewContext, predicate: nil) as! [Pin]
        placeSavedPins()
        let currentCenterArr = dataController.fetchRecordsForEntity("Map", inManagedObjectContext: dataController.viewContext, predicate: nil)
        if (currentCenterArr.count > 0) {
            let currentCenter = currentCenterArr[0] as! Map
            mapView.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: currentCenter.centerLatitude, longitude: currentCenter.centerLongitude), span: MKCoordinateSpan(latitudeDelta: currentCenter.latitudeDelta, longitudeDelta: currentCenter.longitudeDelta))
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedImagesController = nil
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
        var centerArr = dataController.fetchRecordsForEntity("Map", inManagedObjectContext: dataController.viewContext, predicate: nil) as! [Map]
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
    
    fileprivate func getUrls(currentPin: Pin, photoAlbumVC: PhotoAlbumViewController) {
        FlickrApiClient.getImageUrls(pin: currentPin) {(result, title, error) in
            guard let urls = result, let titles = title else {
                print(error!.localizedDescription)
                return
            }
            self.urls = urls
            self.titles = titles
            self.picNum = urls.count
            currentPin.urls = []
            currentPin.titles = []
            for url in self.urls {
                currentPin.urls!.append(url.absoluteString)
            }
            for title in self.titles {
                currentPin.titles!.append(title)
            }
            self.navigationController!.pushViewController(photoAlbumVC, animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let photoAlbumVC = storyboard!.instantiateViewController(withIdentifier: "photoVC") as! PhotoAlbumViewController
        let myAnnotation = view.annotation as! MyPointAnnotation
        photoAlbumVC.currentPin = myAnnotation.pin
        photoAlbumVC.dataController = dataController
        if myAnnotation.pin.urls == nil {
            getUrls(currentPin: myAnnotation.pin, photoAlbumVC: photoAlbumVC)
        }
        else {
            self.navigationController!.pushViewController(photoAlbumVC, animated: true)
        }
    }
}
