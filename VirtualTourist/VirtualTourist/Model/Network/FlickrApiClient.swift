//
//  FlickrApiClient.swift
//  VirtualTourist
//
//  Created by Anna Kulaieva on 11/3/19.
//  Copyright © 2019 Anna Koulaeva. All rights reserved.
//

import Foundation
import UIKit

public enum MyError: Error {
    case dataConvertError
}

extension MyError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .dataConvertError:
            return NSLocalizedString("Could not convert downloaded data to UIImage.", comment: "Data Convert Error")
        }
    }
}

class FlickrApiClient {
    
    static let apiKey = "88bfcc4e3840926ce88b943fa2f6b80f"
    static let imgSize = "n"
    static let searchStr = "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=88bfcc4e3840926ce88b943fa2f6b80f&format=json&"
    
    class func getLocationPicsList(latitude: Double, longitude: Double, completion: @escaping ([URL]?, [String]?, Error?) -> Void) {
        let page = Int.random(in: 1...250)
        let url = URL(string: searchStr + "lat=\(latitude)&lon=\(longitude)&page=\(page)")!
        NetworkingTasks.taskForRequest(requestMethod: "GET", url: url, responseType: PhotoSearchResponse.self) { (result, error) in
            guard error == nil else {
                completion(nil, nil, error)
                return
            }
            if let result = result {
                var imageUrls: [URL] = []
                var titles: [String] = []
                for photo in result.photos.photo {
                    let imageStrTmp = "https://farm\(photo.farm).staticflickr.com/\(photo.server)/\(photo.id)_\(photo.secret)_q.jpg"
                    imageUrls.append(URL(string: imageStrTmp)!)
                    titles.append(photo.title)
                }
                DispatchQueue.main.async {
                    completion(imageUrls, titles, nil)
                }
            }
        }
    }
    
    class func getImageUrls(latitude: Double, longitude: Double, completion: @escaping ([URL]?, [String]?, Error?) -> Void) {
        FlickrApiClient.getLocationPicsList(latitude: latitude, longitude: longitude) { (response, titles, error) in
            guard let response = response else {
                completion(nil, nil, error)
                return
            }
            DispatchQueue.main.async {
                completion(response, titles, nil)
            }
        }
    }
    
    class func downloadImage(url: URL, completion: @escaping (UIImage?, Data?, Error?) ->Void) {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                completion(nil, nil, error)
                return
            }
            guard let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    completion(nil, nil, MyError.dataConvertError)
                }
                return
            }
            DispatchQueue.main.async {
                completion(image, data, nil)
            }
        }
        task.resume()
    }
}
