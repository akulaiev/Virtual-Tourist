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
}
