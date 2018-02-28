//
//  AMGifDataService.swift
//  AMGifPicker
//
//  Created by Alexander Momotiuk on 09.01.18.
//  Copyright © 2018 Alexander Momotiuk. All rights reserved.
//

import Foundation
import GiphyCoreSDK

class AMGifDataService {
    
    private let client: GPHClient
    
    private var trendingLoadingOperation: Operation?
    private var searchLoadingOperation: Operation?
    
    init(apiKey key: String) {
        self.client = GPHClient(apiKey: key)
    }
    
    func loadGiphy(_ search: String? = nil, offset: Int = 0, limit: Int, completion: @escaping (_ data: [GPHMedia]?) -> Void) {
        // Search
        if let search = search {
            getSearchGifs(search, offset: offset, limit: limit, completion: { (items) in
                completion(items)
            })
        }
        // Trending
        else {
            getTrendingGifs(offset: offset, limit: limit, completion: { (items) in
                completion(items)
            })
        }
    }
    
    private func getSearchGifs(_ search: String, offset: Int, limit: Int, completion: @escaping (_ data: [GPHMedia]?) -> Void) {
        searchLoadingOperation?.cancel()
        searchLoadingOperation = client.search(search, offset: offset, limit: limit, completionHandler: { (responce, error) in
            guard let responceItems = responce?.data else {
                completion(nil)
                return
            }
            completion(responceItems)
        })
    }
    
    private func getTrendingGifs(offset: Int, limit: Int, completion: @escaping (_ data: [GPHMedia]?) -> Void) {
        trendingLoadingOperation?.cancel()
        trendingLoadingOperation = client.trending(offset: offset, limit: limit) { (responce, error) in
            guard let responceItems = responce?.data else {
                completion(nil)
                return
            }
            completion(responceItems)
        }
    }
}
