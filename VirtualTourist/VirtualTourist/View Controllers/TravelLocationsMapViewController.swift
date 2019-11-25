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
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var deletePinsButton: UIButton!
    
    var dataController: DataController!
    var pins: [Pin] = []
    var pinsToDelete: [Pin] = []
    var fetchedImagesController: NSFetchedResultsController<Photo>!
    var imageForPinUrls: [URL] = []
    var titlesForPin: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longTap))
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
    }
    
    fileprivate func changeDeleteButtonState(isEditing: Bool) {
        deletePinsButton.isEnabled = isEditing
        deletePinsButton.isHidden = !isEditing
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        changeDeleteButtonState(isEditing: false)
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
    
    fileprivate func createDataEntries(currentPin: Pin, photoAlbumVC: PhotoAlbumViewController) {
        FlickrApiClient.getImageUrls(pin: currentPin) {(result, title, error) in
            guard let urls = result, let titles = title else {
                print(error!.localizedDescription)
                return
            }
            self.imageForPinUrls = urls
            self.titlesForPin = titles
            for index in 0..<self.imageForPinUrls.count {
                let coreImage = Photo(context: self.dataController.viewContext)
                coreImage.setValuesForKeys(["url": self.imageForPinUrls[index].absoluteString, "title": self.titlesForPin[index], "pin": currentPin])
                self.dataController.saveContext()
            }
            self.navigationController!.pushViewController(photoAlbumVC, animated: true)
        }
    }
    
    func checkImagesForPin(currentPin: Pin) -> Bool {
        let predicate = NSPredicate(format: "pin == %@", currentPin)
        let result = dataController.fetchRecordsForEntity("Photo", inManagedObjectContext: dataController.viewContext, predicate: predicate)
        if result.count == 0 {
            return false
        }
        return true
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let myAnnotation = view.annotation as! MyPointAnnotation
        if deletePinsButton.isHidden {
            let photoAlbumVC = storyboard!.instantiateViewController(withIdentifier: "photoVC") as! PhotoAlbumViewController
            photoAlbumVC.currentPin = myAnnotation.pin
            photoAlbumVC.dataController = dataController
            if !checkImagesForPin(currentPin: myAnnotation.pin) {
                createDataEntries(currentPin: myAnnotation.pin, photoAlbumVC: photoAlbumVC)
            }
            else {
                self.navigationController!.pushViewController(photoAlbumVC, animated: true)
            }
        }
        else {
            pinsToDelete.append(myAnnotation.pin)
        }
    }
    
    @IBAction func editButtonTapped(_ sender: UIBarButtonItem) {
        if sender.title == "Edit" {
            self.setEditing(!self.isEditing, animated: true)
            let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: nil)
            self.navigationItem.setRightBarButton(doneButton, animated: true)
            changeDeleteButtonState(isEditing: true)
        }
    }
    
    @IBAction func deletePinButtonTapped(_ sender: UIButton) {
        for pin in pinsToDelete {
            dataController.viewContext.delete(pin)
            dataController.saveContext()
        }
    }
}
