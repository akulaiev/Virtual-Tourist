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
    var fetchedImagesController: NSFetchedResultsController<Photo>!
    var fetchedResultsProcessingOperations: [BlockOperation] = []
    var pathToDelete: IndexPath!
    
    var shouldReloadCollectionView: Bool = false
    
    // Sets the delegates and registeres the custom cell
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib.init(nibName: "CustomCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "photoCell")
    }
    
    // Sets up the fetched results controller for Photo data entries
    func setupFetchedResultsController(currentPin: Pin) {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", currentPin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedImagesController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(currentPin.latitude)" + " " + "\(currentPin.longitude)")
        fetchedImagesController.delegate = self
        do {
            try fetchedImagesController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    // Prepares the interface for showing
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if let currentPin = currentPin {
            setupFetchedResultsController(currentPin: currentPin)
            let mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: currentPin.latitude, longitude: currentPin.longitude), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
            mapView.setRegion(mapRegion, animated: true)
            MyPointAnnotation.createAnnotationForPin(mapView: mapView, pin: currentPin)
            noImagesLabel.isHidden = true
            if fetchedImagesController.sections?.count == 0 || fetchedImagesController.sections?[0].numberOfObjects == 0 {
                noImagesLabel.isHidden = false
            }
        }
    }
    
    // Clears the fetched results controller
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedImagesController = nil
        for operation in fetchedResultsProcessingOperations {
            operation.cancel()
        }
        fetchedResultsProcessingOperations.removeAll()
    }
    
    // Updates cells based on the data downloading state
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
    
    // Refreshes cells' images
    func refreshCollection(completion: @escaping (Bool, Error?) -> Void) {
        FlickrApiClient.getImageUrls(pin: currentPin) { (urls, titles, error) in
            guard let urls = urls, let titles = titles else {
                completion(false, error)
                return
            }
            for index in 0..<self.fetchedImagesController.fetchedObjects!.count {
                let entryToUpdate = self.fetchedImagesController.fetchedObjects![index]
                entryToUpdate.photoImg = nil
                entryToUpdate.title = titles[index]
                entryToUpdate.url = urls[index].absoluteString
            }
            completion(true, nil)
        }
    }
    
    // According to the New Collection button state, refreshes cells or deletes the chosen photo
    @IBAction func collectionsButtonTapped(_ sender: UIBarButtonItem) {
        if sender.title == "New Collection" {
            collectionsButton.isEnabled = false
            refreshCollection { (success, error) in
                if success {
                    self.collectionsButton.isEnabled = true
                }
                else {
                    print(error!.localizedDescription)
                }
            }
        }
        else if sender.title == "Remove Selected Pictures" {
            collectionsButton.tintColor = .blue
            collectionsButton.title = "New Collection"
            if let indexPath = pathToDelete {
                let picToDelete = fetchedImagesController.object(at: indexPath)
                dataController.viewContext.delete(picToDelete)
                try? dataController.viewContext.save()
            }
        }
    }
}

// Collection view delegate methods
extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedImagesController.sections?.count ?? 1
    }
    
    // Returns number of collection cells stored in Core Data
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedImagesController.sections?[0].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionsButton.title = "Remove Selected Pictures"
        collectionsButton.tintColor = .red
        pathToDelete = indexPath
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
    
    // Gets the image for cell
    func getImageFromNetwork(imageUrl: URL, cell: CustomCollectionViewCell, indexPath: IndexPath) {
        updateCellUI(cell, isDownloading: true)
        FlickrApiClient.downloadImage(url: imageUrl) { (data, error) in
            guard let data = data else {
                print(error!.localizedDescription)
                return
            }
            self.updateCellUI(cell, isDownloading: false)
            cell.photoImageView.image = UIImage(data: data)!
            let photoEntity = self.fetchedImagesController.object(at: indexPath)
            photoEntity.photoImg = data
            self.dataController.saveContext()
        }
    }
    
    // Deques reusable cell
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! CustomCollectionViewCell
        if let image = fetchedImagesController.object(at: indexPath).photoImg {
            cell.photoImageView.image = UIImage(data: image)
        }
        else {
            getImageFromNetwork(imageUrl: URL(string: fetchedImagesController.object(at: indexPath).url!)!, cell: cell, indexPath: indexPath)
        }
        return cell
    }
}

// MapKit view delegate method
extension PhotoAlbumViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return MyPointAnnotation.viewForAnnotation(annotation: annotation, mapView: mapView)
    }
}

// FetchedResultsController delegate methods
extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
 
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            collectionView.insertItems(at: [newIndexPath!])
            break
        case .delete:
            collectionView.deleteItems(at: [indexPath!])
            break
        case .update:
            collectionView.reloadItems(at: [indexPath!])
        case .move:
            collectionView.moveItem(at: indexPath!, to: newIndexPath!)
        @unknown default:
            fatalError()
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert: collectionView.insertSections(indexSet)
        case .delete: collectionView.deleteSections(indexSet)
        case .update, .move:
            fatalError("Invalid change type in controller(_:didChange:atSectionIndex:for:). Only .insert or .delete should be possible.")
        @unknown default:
            fatalError()
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView!.performBatchUpdates({ () -> Void in
            for operation in self.fetchedResultsProcessingOperations {
                operation.start()
            }
        }, completion: { (finished) -> Void in
            self.fetchedResultsProcessingOperations.removeAll(keepingCapacity: false)
        })
    }
}
