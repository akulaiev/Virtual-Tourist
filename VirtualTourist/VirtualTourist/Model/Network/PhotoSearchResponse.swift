//
//  PhotoSearchResponse.swift
//  VirtualTourist
//
//  Created by Anna Kulaieva on 11/3/19.
//  Copyright © 2019 Anna Koulaeva. All rights reserved.
//

import Foundation

struct PicData: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
}

struct Pics: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo: [PicData]
}

struct PhotoSearchResponse: Codable {
    let photos: Pics
    let stat: String
}
