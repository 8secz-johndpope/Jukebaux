//
//  AMGiphyPickerSettings.swift
//  AMGiphyPicker
//
//  Created by Alexander Momotiuk on 1/23/18.
//  Copyright © 2018 Alexander Momotiuk. All rights reserved.
//

import Foundation

public enum AMGifPickerScrollDirection {
    case horizontal
    case vertical
}

public struct AMGifPickerConfiguration {
    
    public let apiKey: String
    public let numberRows: Int
    public let scrollDirection: AMGifPickerScrollDirection
    
    // Maximum gifs for one search string
    public let maxLoadCount: Int
    public let dataQuality: AMGifQuality
    
    public init(apiKey key: String, rows: Int = 1, direction: AMGifPickerScrollDirection = .horizontal, quality: AMGifQuality = .veryLow, maxCount: Int = 200) {
        apiKey = key
        numberRows = rows
        scrollDirection = direction
        maxLoadCount = maxCount
        dataQuality = quality
    }
}
