//
//  GPHMediaWrapper.swift
//  AMGifPicker
//
//  Created by Alexander Momotiuk on 2/15/18.
//  Copyright © 2018 Alexander Momotiuk. All rights reserved.
//

import Foundation
import GiphyCoreSDK

fileprivate struct Constants {
    static let defaultHeight = 100
    static let defaultWidth = 100
}

extension GPHMedia: AMGifWrapper {

    public var key: String {
        return id
    }
    
    public func possibleQuality(preferred quality: AMGifQuality) -> AMGifQuality {
        switch quality {
        case .veryLow:
            if let url = images?.fixedHeightSmall?.gifUrl, url.count > 0
            { return .veryLow }
            fallthrough
        case .low:
            if let url = images?.fixedHeight?.gifUrl, url.count > 0
            { return .low }
            fallthrough
        case .medium:
            if let url = images?.downsizedSmall?.gifUrl, url.count > 0
            { return .medium }
            fallthrough
        case .high:
            if let url = images?.downsized?.gifUrl, url.count > 0
            { return .high }
            fallthrough
        case .veryHigh:
            if let url = images?.downsizedMedium?.gifUrl, url.count > 0
            { return .veryHigh }
            fallthrough
        default:
            return .original
        }
    }
    
    public func gifUrl(with quality: AMGifQuality) -> String {
        switch quality {
        case .veryLow:
            if let url = images?.fixedHeightSmall?.gifUrl, url.count > 0
            { return url }
            fallthrough
        case .low:
            if let url = images?.fixedHeight?.gifUrl, url.count > 0
            { return url }
            fallthrough
        case .medium:
            if let url = images?.downsizedSmall?.gifUrl, url.count > 0
            { return url}
            fallthrough
        case .high:
            if let url = images?.downsized?.gifUrl, url.count > 0
            { return url }
            fallthrough
        case .veryHigh:
            if let url = images?.downsizedMedium?.gifUrl, url.count > 0
            { return url }
            fallthrough
        default:
            return images?.original?.gifUrl ?? ""
        }
    }
    
    public func thumbnailUrl(with quality: AMGifQuality) -> String {
        switch quality {
        case .veryLow:
            if let url = images?.fixedHeightSmallStill?.gifUrl, url.count > 0
            { return url }
            fallthrough
        case .low:
            if let url = images?.fixedHeightStill?.gifUrl, url.count > 0
            { return url }
            fallthrough
        case .medium:
            if let url = images?.downsizedStill?.gifUrl, url.count > 0
            { return url }
            fallthrough
        default:
            return images?.originalStill?.gifUrl ?? ""
        }
    }
    
    public func size(with quality: AMGifQuality) -> CGSize {
        switch quality {
        case .veryLow:
            if let height = images?.fixedHeightSmall?.height, let width = images?.fixedHeightSmall?.width, height > 0, width > 0
            { return CGSize(width: width, height: height) }
            fallthrough
        case .low:
            if let height = images?.fixedHeight?.height, let width = images?.fixedHeight?.width, height > 0, width > 0
            { return CGSize(width: width, height: height) }
            fallthrough
        case .medium:
            if let height = images?.downsizedSmall?.height, let width = images?.fixedHeightSmall?.width, height > 0, width > 0
            { return CGSize(width: width, height: height) }
            fallthrough
        case .high:
            if let height = images?.downsized?.height, let width = images?.fixedHeightSmall?.width, height > 0, width > 0
            { return CGSize(width: width, height: height) }
            fallthrough
        case .veryHigh:
            if let height = images?.downsizedMedium?.height, let width = images?.fixedHeightSmall?.width, height > 0, width > 0
            { return CGSize(width: width, height: height) }
            fallthrough
        case .original:
            if let height = images?.fixedHeightSmall?.height, let width = images?.fixedHeightSmall?.width, height > 0, width > 0
            { return CGSize(width: width, height: height) }
            fallthrough
        default:
            return CGSize(width: 100, height: 100)
        }
    }
}
