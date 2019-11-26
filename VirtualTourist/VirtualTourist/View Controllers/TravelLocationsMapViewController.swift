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

class TravelLocationsMapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var deletePinsLabel: UILabel!
    
    var dataController: DataController!
    var pins: [Pin] = []
    var imageForPinUrls: [URL] = []
    var titlesForPin: [String] = []
    
    // Sets delegates, configures gesture recognizer, fetches already saved in CoreData pins to display
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longTap))
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
        pins = dataController.fetchRecordsForEntity("Pin", inManagedObjectContext: dataController.viewContext, predicate: nil) as! [Pin]
        placeSavedPins()
    }
    
    // Prepares for showing the VC: hides delete pin label and centers the map view to the last chosen location
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        deletePinsLabel.isHidden = true
        let currentCenterArr = dataController.fetchRecordsForEntity("Map", inManagedObjectContext: dataController.viewContext, predicate: nil)
        if (currentCenterArr.count > 0) {
            let currentCenter = currentCenterArr[0] as! Map
            mapView.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: currentCenter.centerLatitude, longitude: currentCenter.centerLongitude), span: MKCoordinateSpan(latitudeDelta: currentCenter.latitudeDelta, longitudeDelta: currentCenter.longitudeDelta))
        }
    }
    
    // Checks, if any pins have already been saved
    func checkImagesForPin(currentPin: Pin) -> Bool {
        let predicate = NSPredicate(format: "pin == %@", currentPin)
        let result = dataController.fetchRecordsForEntity("Photo", inManagedObjectContext: dataController.viewContext, predicate: predicate)
        if result.count == 0 {
            return false
        }
        return true
    }
    
    // Configures the state of the Bar Button
    fileprivate func changeEditButton(isEditing: Bool, button: UIBarButtonItem) {
        self.setEditing(!self.isEditing, animated: true)
        if isEditing {
            button.title = "Done"
        }
        else {
            button.title = "Edit"
        }
        deletePinsLabel.isHidden = !isEditing
    }
    
    // Calls the function to configure the Bar Button when it is tapped
    @IBAction func editButtonTapped(_ sender: UIBarButtonItem) {
        if sender.title == "Edit" {
            changeEditButton(isEditing: true, button:  sender)
        }
        else if sender.title == "Done" {
            changeEditButton(isEditing: false, button: sender)
        }
    }
    
    // Calls the function, that crates Core Data entries for placed pin
    fileprivate func dataForPin(currentPin: Pin, photoAlbumVC: PhotoAlbumViewController) {
        FlickrApiClient.createDataEntries(currentPin: currentPin, dataController: dataController) { (success, error) in
            if !success {
                print(error!.localizedDescription)
            }
            else {
                self.navigationController!.pushViewController(photoAlbumVC, animated: true)
            }
        }
    }
}

// Manages Map View delegate functionality
extension TravelLocationsMapViewController: MKMapViewDelegate, UIGestureRecognizerDelegate {
    
    // Places on the map pre-saved pins
    func placeSavedPins() {
        for pin in pins {
            MyPointAnnotation.createAnnotationForPin(mapView: mapView, pin: pin)
        }
    }
    
    // Drops the new pin at the long tap
    @objc func longTap(sender: UITapGestureRecognizer){
        if sender.state == .began {
            let locationInView = sender.location(in: mapView)
            let locationOnMap = mapView.convert(locationInView, toCoordinateFrom: mapView)
            addNewPin(location: locationOnMap)
        }
    }
    
    // Creates new pin Core Data entry
    func addNewPin(location: CLLocationCoordinate2D) {
        let newPin = Pin(context: dataController.viewContext)
        newPin.latitude = location.latitude
        newPin.longitude = location.longitude
        MyPointAnnotation.createAnnotationForPin(mapView: mapView, pin: newPin)
        dataController.saveContext()
    }
    
    // Returns view fo annotation
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return MyPointAnnotation.viewForAnnotation(annotation: annotation, mapView: mapView)
    }
    
    // Changes the map center Core data entry to the newly changed one
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
    
    // According to the Edit button state, navigates to PhotoAlbumVC or deletes the chosen pins
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let myAnnotation = view.annotation as! MyPointAnnotation
        if deletePinsLabel.isHidden {
            let photoAlbumVC = storyboard!.instantiateViewController(withIdentifier: "photoVC") as! PhotoAlbumViewController
            photoAlbumVC.currentPin = myAnnotation.pin
            photoAlbumVC.dataController = dataController
            if !checkImagesForPin(currentPin: myAnnotation.pin) {
                dataForPin(currentPin: myAnnotation.pin, photoAlbumVC: photoAlbumVC)
            }
            else {
                self.navigationController!.pushViewController(photoAlbumVC, animated: true)
            }
        }
        else {
            mapView.removeAnnotation(myAnnotation)
            dataController.viewContext.delete(myAnnotation.pin)
            dataController.saveContext()
        }
        mapView.deselectAnnotation(view.annotation, animated: true)
    }
}
