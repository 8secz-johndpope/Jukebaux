//
//  AMGifPickerModel.swift
//  AMGiphyPicker
//
//  Created by Alexander Momotiuk on 25.01.18.
//  Copyright © 2018 Alexander Momotiuk. All rights reserved.
//

import Foundation
import GiphyCoreSDK

private struct Configuration {
    static let limit = 40
}

protocol AMGifPickerModelDelegate: class {
    
    func modelDidUpdatedData(_ model: AMGifPickerModel)
    func model(_ model: AMGifPickerModel, didInsert indexPath: [IndexPath])
}

class AMGifPickerModel {
    
    weak var delegate: AMGifPickerModelDelegate?
    
    private var configuration: AMGifPickerConfiguration
    
    private var trendingGifs: [AMGifViewModel] = []
    private var searchGifs: [AMGifViewModel] = []
    
    private var searchString: String? = nil
    private var isLoading: Bool = false
    
    private var provider: AMGifDataService
    
    init(config: AMGifPickerConfiguration) {
        configuration = config
        provider = AMGifDataService(apiKey: config.apiKey)
        
        AMGifCache.shared.cleanCache()
        
        loadData()
    }
}

//MARK: - Fetching Data Methods
extension AMGifPickerModel {
    
    //First Fetching
    private func loadData() {
        isLoading = true
        provider.loadGiphy(nil, offset: 0, limit: Configuration.limit) {[weak self] (gifs) in
            self?.isLoading = false
            guard let gifs = gifs, let strongSelf = self else { return }
            strongSelf.appendTrending(gifs)
            strongSelf.delegate?.modelDidUpdatedData(strongSelf)
        }
    }
    
    private func appendTrending(_ gifs: [GPHMedia]) {
        let gifsViewModel = gifs.map { (media) -> AMGifViewModel in
            let model = AMGif(media, preferred: configuration.dataQuality)
            return AMGifViewModel(model)
        }
        self.trendingGifs.append(contentsOf: gifsViewModel)
    }
    
    func search(_ search: String?) {
        if let newSearch = search, newSearch.count > 0 {
            if newSearch != searchString {
                searchString = newSearch
                self.searchGifs = []
                delegate?.modelDidUpdatedData(self)
                provider.loadGiphy(newSearch, offset: 0, limit: Configuration.limit, completion: {[weak self] (newGifs) in
                    guard let gifs = newGifs, let strongSelf = self else { return }
                    let gifsViewModel = gifs.map { (media) -> AMGifViewModel in
                        let model = AMGif(media, preferred: strongSelf.configuration.dataQuality)
                        return AMGifViewModel(model)
                    }
                    strongSelf.searchGifs = gifsViewModel
                    strongSelf.delegate?.modelDidUpdatedData(strongSelf)
                })
            }
        } else {
            //Clean search cache and cancel all loading operation
            searchGifs.forEach { $0.cancelFetching() }
            searchGifs.removeAll()
            searchString = nil
            //If trending gifs already exist
            if trendingGifs.count < Configuration.limit {
                provider.loadGiphy(limit: Configuration.limit, completion: {[weak self] (newGifs) in
                    guard let gifs = newGifs, let strongSelf = self else { return }
                    strongSelf.appendTrending(gifs)
                    strongSelf.delegate?.modelDidUpdatedData(strongSelf)
                })
            } else {
                self.delegate?.modelDidUpdatedData(self)
            }
        }
    }
    
    func loadNext() {
        if let search = searchString, searchGifs.count < configuration.maxLoadCount {
            let limit = configuration.maxLoadCount - searchGifs.count > Configuration.limit ? Configuration.limit : configuration.maxLoadCount - searchGifs.count
            provider.loadGiphy(search, offset: searchGifs.count, limit: limit, completion: {[weak self] (newGifs) in
                guard let gifs = newGifs, let strongSelf = self else { return }
                let gifsViewModel = gifs.map { (media) -> AMGifViewModel in
                    let model = AMGif(media, preferred: strongSelf.configuration.dataQuality)
                    return AMGifViewModel(model)
                }
                let startIndex = strongSelf.searchGifs.count
                let isInsert = strongSelf.searchGifs.count > 0
                strongSelf.searchGifs.append(contentsOf: gifsViewModel)
                if isInsert {
                    var indexes: [IndexPath] = []
                    for (index, _) in gifsViewModel.enumerated() {
                        indexes.append(IndexPath(row: startIndex + index, section: 0))
                    }
                    strongSelf.delegate?.model(strongSelf, didInsert: indexes)
                } else {
                    strongSelf.delegate?.modelDidUpdatedData(strongSelf)
                }
            })
        } else if trendingGifs.count < configuration.maxLoadCount && searchString.emptyIfNil == 0 {
            let limit = configuration.maxLoadCount - trendingGifs.count > Configuration.limit ? Configuration.limit : configuration.maxLoadCount - trendingGifs.count
            provider.loadGiphy(nil, offset: trendingGifs.count, limit: limit, completion: {[weak self] (newGifs) in
                guard let gifs = newGifs, let strongSelf = self else { return }
                let startIndex = strongSelf.trendingGifs.count
                let isInsert = strongSelf.trendingGifs.count > 0
                strongSelf.appendTrending(gifs)
                if isInsert {
                    var indexes: [IndexPath] = []
                    for (index, _) in gifs.enumerated() {
                        indexes.append(IndexPath(row: startIndex + index, section: 0))
                    }
                    strongSelf.delegate?.model(strongSelf, didInsert: indexes)
                } else {
                    strongSelf.delegate?.modelDidUpdatedData(strongSelf)
                }
            })
        }
    }
}

//MARK: - Data Source Methods
extension AMGifPickerModel {
    
    func numberOfItems() -> Int {
        if let search = searchString, search.count > 0 {
            return searchGifs.count
        }
        return trendingGifs.count
    }
    
    func item(at index: Int) -> AMGifViewModel? {
        if searchString != nil {
            return index < searchGifs.count ? searchGifs[index] : nil
        }
        return index < trendingGifs.count ? trendingGifs[index] : nil
    }
}

