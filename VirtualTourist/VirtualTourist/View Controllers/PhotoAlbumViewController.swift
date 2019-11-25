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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib.init(nibName: "CustomCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "photoCell")
    }
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if let currentPin = currentPin {
            setupFetchedResultsController(currentPin: currentPin)
            let mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: currentPin.latitude, longitude: currentPin.longitude), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
            mapView.setRegion(mapRegion, animated: true)
            MyPointAnnotation.putPin(mapView: mapView, pin: currentPin)
            noImagesLabel.isHidden = true
            if fetchedImagesController.sections?.count == 0 || fetchedImagesController.sections?[0].numberOfObjects == 0 {
                noImagesLabel.isHidden = false
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedImagesController = nil
        for operation in fetchedResultsProcessingOperations {
            operation.cancel()
        }
        fetchedResultsProcessingOperations.removeAll()
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
    
    @IBAction func collectionsButtonTapped(_ sender: UIBarButtonItem) {
        if sender.title == "New Collection" {
            collectionsButton.isEnabled = false
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

// MapKit view delegate methods
extension PhotoAlbumViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return MyPointAnnotation.viewForAnnotation(annotation: annotation)
    }
}

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
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert: collectionView.insertSections(indexSet)
        case .delete: collectionView.deleteSections(indexSet)
        case .update, .move:
            fatalError("Invalid change type in controller(_:didChange:atSectionIndex:for:). Only .insert or .delete should be possible.")
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
