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

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var noImagesLabel: UILabel!
    
    var dataController: DataController!
    var currentPin: Pin!
    var imageUrls: [URL] = []
    var titles: [String] = []
    var fetchedImagesController: NSFetchedResultsController<Photo>!
    
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
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return MyPointAnnotation.viewForAnnotation(annotation: annotation)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let fetchedRes = fetchedImagesController, let sections = fetchedRes.sections {
            return sections.count
        }
        return 1
    }
    
    // Returns number of collection cells
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fetchedImagesController = fetchedImagesController, let sections = fetchedImagesController.sections, sections.count > 0, sections[section].numberOfObjects > 0 {
            return sections[section].numberOfObjects
        }
        else if imageUrls.count == 0 {
            noImagesLabel.isHidden = false
            return 0
        }
        else {
            return imageUrls.count
        }
    }
    
    fileprivate func networkImagesDownload(_ cell: CustomCollectionViewCell, _ indexPath: IndexPath) {
        cell.photoImageView.layer.borderWidth = 1.5
        cell.photoImageView.layer.borderColor = UIColor.lightGray.cgColor
        cell.indicatorView.startAnimating()
        FlickrApiClient.downloadImage(url: imageUrls[indexPath.row]) { (image, data, error) in
            guard let image = image else {
                print(error!.localizedDescription)
                return
            }
            cell.indicatorView.stopAnimating()
            cell.photoImageView.layer.borderWidth = 0
            cell.photoImageView.image = image
            self.dataController.backgroundContext.perform {
                let coreImage = Photo(context: self.dataController.viewContext)
//                coreImage.setValuesForKeys(["title": self.titles[indexPath.row], "photoImg": data!, "pin": self.currentPin!])
                coreImage.title = self.titles[indexPath.row]
                coreImage.photoImg = data!
                coreImage.pin = self.currentPin
                try? self.dataController.backgroundContext.save()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! CustomCollectionViewCell
        if imageUrls.count > 0 {
            networkImagesDownload(cell, indexPath)
        }
        else if let sections = fetchedImagesController.sections, sections.count > 0, sections[indexPath.section].numberOfObjects > 0 {
            let pic = fetchedImagesController.object(at: indexPath)
            cell.photoImageView.image = UIImage(data: pic.photoImg!)!
        }
        return cell
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
    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let showMemeVC: ShowMemeViewController
//        showMemeVC = storyboard.instantiateViewController(withIdentifier: "showMemeVC") as! ShowMemeViewController
//        let meme = self.memes[(indexPath as NSIndexPath).row]
//        showMemeVC.memeImage = meme.memedImage
//        navigationController?.pushViewController(showMemeVC, animated: true)
//    }
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
        @unknown default:
            fatalError("Unknow switch value")
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.reloadData()
    }
}
