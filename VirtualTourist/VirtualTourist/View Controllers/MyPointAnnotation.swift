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
    let pin: Pin
    
    init(pin: Pin, color: UIColor)
    {
        self.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        self.color = color
        self.pin = pin
        super.init()
    }
    
    class func createAnnotationForPin(mapView: MKMapView, pin: Pin) {
        let annotation = MyPointAnnotation(pin: pin, color: .red)
        mapView.addAnnotation(annotation)
    }
    
    class func viewForAnnotation(annotation: MKAnnotation, mapView: MKMapView) -> MKAnnotationView? {
        if let annotation = annotation as? MyPointAnnotation
        {
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "\(annotation.pin.latitude):\(annotation.pin.longitude)")
            view.animatesDrop = true
            view.pinTintColor = annotation.color
            view.canShowCallout = false
            return view
        }
        return nil
    }
}
