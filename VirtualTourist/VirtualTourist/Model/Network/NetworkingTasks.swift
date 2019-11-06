//
//  NetworkingTasks.swift
//  OnTheMap
//
//  Created by Anna KULAIEVA on 10/24/19.
//  Copyright © 2019 Anna Kulaieva. All rights reserved.
//

import Foundation

class NetworkingTasks {
    
    //Static function to perform all kinds of networking requests
    class func taskForRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            do {
                let decoder = JSONDecoder()
                let range = 14..<data.count - 1
                let newData = data.subdata(in: range)
                let response = try decoder.decode(ResponseType.self, from: newData)
                DispatchQueue.main.async {
                    completion(response, nil)
                }
            }
            catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        task.resume()
    }
    
}
