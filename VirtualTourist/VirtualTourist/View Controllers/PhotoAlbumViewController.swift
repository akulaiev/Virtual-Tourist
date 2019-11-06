//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Anna Koulaeva on 01.11.2019.
//  Copyright © 2019 Anna Koulaeva. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var collectionsButton: UIBarButtonItem!
    
    var dataController: DataController!
    var currentPin: Pin!
    var imageUrls: [URL] = []
    var titles: [String] = []
    var fetchedImagesController: NSFetchedResultsController<Photo>!
    var titleToDel: String?
    var indexPathToDel: [IndexPath]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib.init(nibName: "CustomCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "photoCell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if let currentPin = currentPin {
            let mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: currentPin.latitude, longitude: currentPin.longitude), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
            mapView.setRegion(mapRegion, animated: true)
            MyPointAnnotation.putPin(mapView: mapView, pin: currentPin)
            noImagesLabel.isHidden = true
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedImagesController = nil
    }
    
    fileprivate func updateCellUI(_ cell: CustomCollectionViewCell, isDownloading: Bool) {
        if isDownloading {
            cell.photoImageView.layer.borderWidth = 1.5
            cell.photoImageView.layer.borderColor = UIColor.lightGray.cgColor
            cell.indicatorView.startAnimating()
        }
        else {
            cell.indicatorView.stopAnimating()
            cell.photoImageView.layer.borderWidth = 0
        }
    }
    
    fileprivate func getImageFromNetwork(_ cell: CustomCollectionViewCell, _ indexPath: IndexPath) {
        updateCellUI(cell, isDownloading: true)
        FlickrApiClient.downloadImage(url: imageUrls[indexPath.row]) { (image, data, error) in
            guard let image = image else {
                print(error!.localizedDescription)
                return
            }
            self.updateCellUI(cell, isDownloading: false)
            cell.photoImageView.image = image
            let coreImage = Photo(context: self.dataController.viewContext)
            coreImage.setValuesForKeys(["photoImg": data!, "title": self.titles[indexPath.row], "pin": self.currentPin!])
            self.dataController.saveContext()
            
        }
    }
    
    fileprivate func updateCollectionView() {
        imageUrls = []
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        let predicate = NSPredicate(format: "pin == %@", currentPin)
        deleteFetch.predicate = predicate
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        do {
            try dataController.viewContext.execute(deleteRequest)
            dataController.saveContext()
        }
        catch {
            print(error.localizedDescription)
        }
        self.collectionView.reloadData()
        FlickrApiClient.getImageUrls(pin: currentPin, completion: { (result, titles, error) in
            guard let imageUrls = result, let titles = titles else {
                print(error!.localizedDescription)
                return
            }
            self.imageUrls = imageUrls
            self.titles = titles
            self.collectionView.reloadData()
            self.collectionsButton.isEnabled = true
        })
    }
    
    @IBAction func collectionsButtonTapped(_ sender: UIBarButtonItem) {
        if sender.title == "New Collection" {
            collectionsButton.isEnabled = false
            updateCollectionView()
        }
        else if sender.title == "Remove Selected Pictures" {
            if let titleToDel = titleToDel, let indexPath = indexPathToDel {
                let predicate = NSPredicate(format: "title == %@ AND pin == %@", titleToDel, currentPin)
                let objToDel = dataController.fetchRecordsForEntity("Photo", inManagedObjectContext: dataController.viewContext, predicate: predicate) as! [Photo]
                print(objToDel.count)
                print(objToDel[0].title!)
                dataController.viewContext.delete(objToDel[0])
                collectionView.deleteItems(at: indexPath)
                collectionView.reloadData()
                dataController.saveContext()
                collectionsButton.tintColor = .blue
                collectionsButton.title = "New Collection"
            }
        }
    }
}

// Collection view delegate methods
extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let fetchedRes = fetchedImagesController, let sections = fetchedRes.sections {
            return sections.count
        }
        return 1
    }
    
    // Returns number of collection cells (downloaded from Flickr or stored in Core Data)
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fetchedImagesController = fetchedImagesController, let sections = fetchedImagesController.sections, sections.count > 0, sections[section].numberOfObjects > 0 {
            return sections[section].numberOfObjects
        }
        else if imageUrls.count == 0 {
            if titles.count == 0 {
                noImagesLabel.isHidden = false
            }
            return 0
        }
        else {
            return imageUrls.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionsButton.title = "Remove Selected Pictures"
        collectionsButton.tintColor = .red
        titleToDel = titles[indexPath.row]
        indexPathToDel = [indexPath]
    }
    
    // Calculates and returnes cells' size
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfItemsPerRow: CGFloat = 3
        let borderSpacing: CGFloat = 3.5
        let totalSpacing = borderSpacing * numberOfItemsPerRow
        if let collection = self.collectionView {
            let width = (collection.bounds.width - totalSpacing) / numberOfItemsPerRow
            return CGSize(width: width, height: width)
        }
        else {
            return CGSize(width: 0, height: 0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! CustomCollectionViewCell
        if let fetchedController = fetchedImagesController, let sections = fetchedController.sections, sections.count > 0, sections[indexPath.section].numberOfObjects > 0 {
            let pic = fetchedImagesController.object(at: indexPath)
            if let coreImg = pic.photoImg, let image = UIImage(data: coreImg) {
                cell.photoImageView.image = image
            }
        }
        else if imageUrls.count > 0 {
            getImageFromNetwork(cell, indexPath)
        }
        return cell
    }
}

// MapKit view delegate methods
extension PhotoAlbumViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return MyPointAnnotation.viewForAnnotation(annotation: annotation)
    }
}
