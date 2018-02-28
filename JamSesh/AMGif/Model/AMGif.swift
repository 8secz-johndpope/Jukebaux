//
//  AMGif.swift
//  AMGifPicker
//
//  Created by Alexander Momotiuk on 2/16/18.
//  Copyright © 2018 Alexander Momotiuk. All rights reserved.
//

import UIKit
import GiphyCoreSDK

public final class AMGif {
    
    private let gif: AMGifWrapper
    public private(set) var quality: AMGifQuality
    
    public init(_ gif: AMGifWrapper, preferred quality: AMGifQuality) {
        self.gif = gif
        self.quality = gif.possibleQuality(preferred: quality)
    }
    
    public var key: String {
        return gif.key
    }
    
    public var gifUrl: String {
        return gif.gifUrl(with: quality)
    }
    
    public var thumbnailUrl: String {
        return gif.thumbnailUrl(with: quality)
    }
    public var size: CGSize {
        return gif.size(with: quality)
    }
    
    public func translate(preferred quality: AMGifQuality) -> AMGif {
        return AMGif(gif, preferred: quality)
    }
}
