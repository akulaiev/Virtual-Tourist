//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Anna Koulaeva on 01.11.2019.
//  Copyright © 2019 Anna Koulaeva. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    var dataController: DataController!
    var currentPin: CLLocationCoordinate2D!
    var imageUrls: [URL] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib.init(nibName: "CustomCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "photoCell")
//        imageUrls = FlickrApiClient.getImageUrls(latitude: currentPin.latitude, longitude: currentPin.longitude)
//        print(imageUrls)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if let currentPin = currentPin {
            let mapRegion = MKCoordinateRegion(center: currentPin, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
            mapView.setRegion(mapRegion, animated: true)
            MyPointAnnotation.putPin(location: currentPin, mapView: mapView)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return MyPointAnnotation.viewForAnnotation(annotation: annotation)
    }
    
    // Returns number of collection cells
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageUrls.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! CustomCollectionViewCell
        cell.photoImageView.layer.borderWidth = 1.5
        cell.photoImageView.layer.borderColor = UIColor.lightGray.cgColor
        cell.indicatorView.startAnimating()
        if imageUrls.count > 0 {
            FlickrApiClient.downloadImage(url: imageUrls[indexPath.row]) { (image, error) in
                guard let image = image else {
                    print(error!.localizedDescription)
                    return
                }
                cell.indicatorView.stopAnimating()
                cell.photoImageView.layer.borderWidth = 0
                cell.photoImageView.image = image
            }
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
