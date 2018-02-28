//
//  AMGifWrapper.swift
//  AMGiphyPicker
//
//  Created by Alexander Momotiuk on 11.01.18.
//  Copyright © 2018 Alexander Momotiuk. All rights reserved.
//

import UIKit

public protocol AMGifWrapper {
    
    var key: String { get }
    
    func possibleQuality(preferred quality: AMGifQuality) -> AMGifQuality
    func gifUrl(with quality: AMGifQuality) -> String
    func thumbnailUrl(with quality: AMGifQuality) -> String
    func size(with quality: AMGifQuality) -> CGSize
}


