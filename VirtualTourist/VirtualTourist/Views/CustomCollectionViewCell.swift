//
//  CustomCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Anna Koulaeva on 01.11.2019.
//  Copyright © 2019 Anna Koulaeva. All rights reserved.
//

import UIKit

class CustomCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!

    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = nil
    }
}
