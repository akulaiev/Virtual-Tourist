//
//  MyPointAnnotation.swift
//  OnTheMap
//
//  Created by Anna Koulaeva on 28.10.2019.
//  Copyright © 2019 Anna Kulaieva. All rights reserved.
//

import Foundation
import MapKit

//Custom annotation class
class MyPointAnnotation: NSObject, MKAnnotation
{
    let coordinate: CLLocationCoordinate2D
    let color: UIColor
    
    init(coordinate: CLLocationCoordinate2D, color: UIColor)
    {
        self.coordinate = coordinate
        self.color = color
        super.init()
    }
    
    class func putPin(location: CLLocationCoordinate2D, mapView: MKMapView) {
        let annotation = MyPointAnnotation(coordinate: location, color: .red)
        mapView.addAnnotation(annotation)
    }
    
    class func viewForAnnotation(annotation: MKAnnotation) -> MKAnnotationView? {
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
}
