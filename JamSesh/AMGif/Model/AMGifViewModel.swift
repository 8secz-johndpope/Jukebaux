//
//  AMGifViewModel.swift
//  AMGifPicker
//
//  Created by Alexander Momotiuk on 18.01.18.
//  Copyright © 2018 Alexander Momotiuk. All rights reserved.
//

import UIKit
import Alamofire
import Cache

public protocol AMGifViewModelDelegate: class {
    
    func giphyModelDidBeginLoadingThumbnail(_ item: AMGifViewModel?)
    func giphyModelDidEndLoadingThumbnail(_ item: AMGifViewModel?)
    
    func giphyModelDidBeginLoadingGif(_ item: AMGifViewModel?)
    
    func giphyModel(_ item: AMGifViewModel?, thumbnail data: Data?)
    func giphyModel(_ item: AMGifViewModel?, gifData data: Data?)
    
    func giphyModel(_ item: AMGifViewModel?, gifProgress progress: CGFloat)
}

public class AMGifViewModel {
    
    public weak var delegate: AMGifViewModelDelegate?
    
    public let gifItem: AMGif
    public var expiryTime: Double = 60*60
    private var previewRequest: DownloadRequest?
    private var gifRequest: DownloadRequest?
    
    private var cacheUid: String {
        return "\(gifItem.gifUrl.hash)"
    }
    
    public init(_ item: AMGif) {
        gifItem = item
    }
    
    //MARK: - Fetch Data
    public func fetchData() {
        if AMGifCache.shared.existGif(cacheUid) {
            self.delegate?.giphyModel(self, gifData: AMGifCache.shared.gifCache(for: cacheUid))
            return
        }
        if AMGifCache.shared.existThumbnail(cacheUid) {
            self.delegate?.giphyModel(self, thumbnail: AMGifCache.shared.thumbnailCache(for: cacheUid))
            fetchGifData()
            return
        }
        fetchThumbnail({[weak self] in
            self?.fetchGifData()
        })
    }
    
    public func stopFetching() {
        previewRequest?.suspend()
        gifRequest?.suspend()
    }
    
    //MARK: - Pre-fetching methods
    public func prefetchData() {
        if AMGifCache.shared.existGif(cacheUid) {
            self.delegate?.giphyModel(self, gifData: AMGifCache.shared.gifCache(for: cacheUid))
            return
        }
        if !AMGifCache.shared.existThumbnail(cacheUid) {
            fetchThumbnail()
        }
    }
    
    public func cancelPrefecth() {
        previewRequest?.suspend()
    }
    
    //MARK: - Cancel
    public func cancelFetching() {
        previewRequest?.cancel()
        gifRequest?.cancel()
    }
    
    //MARK: - Private Methods
    private func fetchThumbnail(_ completion: (()->Void)? = nil) {
        delegate?.giphyModelDidBeginLoadingThumbnail(self)
        
        if previewRequest != nil, let suspend = previewRequest?.delegate.queue.isSuspended, suspend, previewRequest?.delegate == nil {
            self.previewRequest?.resume()
        } else {
            self.previewRequest = Alamofire.download(gifItem.thumbnailUrl, to: FileManager.tempCacheDestination(cacheUid + "_thumbnail"))
            self.previewRequest?.responseData(completionHandler: {[weak self] (responce) in
                if responce.error != nil {
                    self?.previewRequest = nil
                    return
                }
                
                if let data = responce.value, data.count > 0, let strongSelf = self {
                    AMGifCache.shared.cacheThumbnail(data, with: strongSelf.cacheUid, expiry: strongSelf.expiryTime, completion: { (success) in
                        if success {
                            DispatchQueue.main.async {
                                self?.delegate?.giphyModelDidEndLoadingThumbnail(self)
                                self?.delegate?.giphyModel(self, thumbnail: responce.value)
                            }
                        }
                    })
                }
                
                FileManager.removeTempCache(file: responce.destinationURL)
                self?.previewRequest = nil
                
                if let callback = completion {
                    callback()
                }
            })
        }
    }
    
    private func fetchGifData() {
        self.delegate?.giphyModelDidBeginLoadingGif(self)
        
        if gifRequest != nil, let suspend = gifRequest?.delegate.queue.isSuspended, suspend, gifRequest?.delegate == nil {
            self.gifRequest?.resume()
        } else {
            self.gifRequest = Alamofire.download(gifItem.gifUrl, to: FileManager.tempCacheDestination(cacheUid))
            self.gifRequest?.responseData(completionHandler: {[weak self] (responce) in
                if responce.error != nil {
                    self?.gifRequest = nil
                    return
                }
                if let data = responce.value, data.count > 0, let strongSelf = self {
                    AMGifCache.shared.cacheGif(data, with: strongSelf.cacheUid, expiry: strongSelf.expiryTime, completion: { (success) in
                        if success {
                            DispatchQueue.main.async {
                                self?.delegate?.giphyModel(self, gifData: data)
                            }
                        }
                    })
                }
                FileManager.removeTempCache(file: responce.destinationURL)
                self?.gifRequest = nil
            })
            self.gifRequest?.downloadProgress(queue: DispatchQueue.main, closure: {[weak self] (progress) in
                self?.delegate?.giphyModel(self, gifProgress: CGFloat(progress.fractionCompleted))
            })
        }
    }
    
    private func getGifData()->Data {
        self.delegate?.giphyModelDidBeginLoadingGif(self)
        
        if gifRequest != nil, let suspend = gifRequest?.delegate.queue.isSuspended, suspend, gifRequest?.delegate == nil {
            self.gifRequest?.resume()
        } else {
            self.gifRequest = Alamofire.download(gifItem.gifUrl, to: FileManager.tempCacheDestination(cacheUid))
            self.gifRequest?.responseData(completionHandler: {[weak self] (responce) in
                if responce.error != nil {
                    self?.gifRequest = nil
                    return
                }
                if let data = responce.value, data.count > 0, let strongSelf = self {
                    AMGifCache.shared.cacheGif(data, with: strongSelf.cacheUid, expiry: strongSelf.expiryTime, completion: { (success) in
                        if success {
                            DispatchQueue.main.async {
                                self?.delegate?.giphyModel(self, gifData: data)
                            }
                        }
                    })
                }
                FileManager.removeTempCache(file: responce.destinationURL)
                self?.gifRequest = nil
            })
            self.gifRequest?.downloadProgress(queue: DispatchQueue.main, closure: {[weak self] (progress) in
                self?.delegate?.giphyModel(self, gifProgress: CGFloat(progress.fractionCompleted))
            })
        }
        return Data()
    }
}

extension AMGifViewModel: Hashable {
    
    public static func ==(lhs: AMGifViewModel, rhs: AMGifViewModel) -> Bool {
        return lhs.gifItem.key == rhs.gifItem.key
    }
    
    public var hashValue: Int {
        return gifItem.key.hashValue
    }
}

