//
//  AMGifCache.swift
//  AMGifPicker
//
//  Created by Alexander Momotiuk on 15.01.18.
//  Copyright © 2018 Alexander Momotiuk. All rights reserved.
//

import Foundation
import Cache

private let megabyte: UInt = 1024 * 1024
private let hour: TimeInterval = 60 * 60

class AMGifCache {
    
    static let shared = AMGifCache()
    
    private var thumbnailsStorage: Storage!
    private var gifsStorage: Storage!
    
    private init() {
        let mainDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let cacheDirectory = URL(string: mainDirectoryUrl.absoluteString + "/gif-cache")!
        
        initStorage(cacheDirectory)
    }
    
    private func initStorage(_ url: URL) {
        let thumbnailsMemoryConfig = DiskConfig(name: "thumbnails", expiry: .never, maxSize: megabyte * 40, directory: url, protectionType: nil)
        let gifsMemoryConfig = DiskConfig(name: "gifs", expiry: .never, maxSize: megabyte * 300, directory: url, protectionType: nil)
        
        thumbnailsStorage = try! Storage(diskConfig: thumbnailsMemoryConfig)
        gifsStorage = try! Storage(diskConfig: gifsMemoryConfig)
        
        try? thumbnailsStorage.removeExpiredObjects()
        try? gifsStorage.removeExpiredObjects()
    }
    
    func cacheThumbnail(_ data: Data, with key: String, completion: @escaping (Bool) -> Void) {
        cacheThumbnail(data, with: key, expiry: hour, completion: completion)
    }
    
    func cacheGif(_ data: Data, with key: String, completion: @escaping (Bool) -> Void) {
        cacheGif(data, with: key, expiry: hour, completion: completion)
    }
    
    func cacheThumbnail(_ data: Data, with key: String, expiry: Double, completion: @escaping (Bool) -> Void) {
        thumbnailsStorage.async.setObject(data, forKey: key + "_thumbnail" , expiry: .seconds(expiry)) { (result) in
            switch result {
            case .value(_):
                completion(true)
            case .error(_):
                completion(false)
            }
        }
    }
    
    func cacheGif(_ data: Data, with key: String, expiry: Double, completion: @escaping (Bool) -> Void) {
        gifsStorage.async.setObject(data, forKey: key, expiry: .seconds(expiry)) { (result) in
            switch result {
            case .value(_):
                completion(true)
            case .error(_):
                completion(false)
            }
        }
    }
    
    func thumbnailCache(for key: String) -> Data? {
        return try? thumbnailsStorage.object(ofType: Data.self, forKey: key + "_thumbnail")
    }
    
    func gifCache(for key: String) -> Data? {
        return try? gifsStorage.object(ofType: Data.self, forKey: key)
    }
    
    func existThumbnail(_ key: String) -> Bool {
        do {
            return try thumbnailsStorage.existsObject(ofType: Data.self, forKey: key + "_thumbnail")
        } catch {
            return false
        }
    }
    
    func existGif(_ key: String) -> Bool {
        do {
            return try gifsStorage.existsObject(ofType: Data.self, forKey: key)
        } catch {
            return false
        }
    }
    
    func cleanCache() {
        DispatchQueue.global().async { [weak self] in
            try? self?.gifsStorage.removeExpiredObjects()
            try? self?.thumbnailsStorage.removeExpiredObjects()
        }
    }
}
