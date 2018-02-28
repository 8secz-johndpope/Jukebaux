//
//  AMGifBaseLayout.swift
//  AMGifPicker
//
//  Created by Alexander Momotiuk on 03.02.18.
//  Copyright © 2018 Alexander Momotiuk. All rights reserved.
//

import UIKit

protocol AMGifBaseLayoutDelegate: class {
    
}

class AMGifBaseLayout: UICollectionViewLayout {
    
    weak var delegate: AMGifBaseLayoutDelegate?
    
    var cache: [UICollectionViewLayoutAttributes] = []
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var visibleLayoutAttributes = [UICollectionViewLayoutAttributes]()
        // Loop through the cache and look for items in the rect
        for attributes in cache {
            if attributes.frame.intersects(rect) {
                visibleLayoutAttributes.append(attributes)
            }
        }
        return visibleLayoutAttributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath.item]
    }
    
    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attribute = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)
        attribute?.alpha = 0.0
        return attribute
    }
}
