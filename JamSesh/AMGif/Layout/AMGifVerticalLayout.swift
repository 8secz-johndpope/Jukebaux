//
//  AMGifVerticalLayout.swift
//  AMGifPicker
//
//  Created by Alexander Momotiuk on 03.02.18.
//  Copyright © 2018 Alexander Momotiuk. All rights reserved.
//

import UIKit

protocol AMGifVerticalLayoutDelegate: AMGifBaseLayoutDelegate {
    
    func numberOfColumns(_ collectionView: UICollectionView) -> Int
    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath, withWidth width: CGFloat) -> CGFloat
}

class AMGifVerticalLayout: AMGifBaseLayout {
    
    var contentWidth: CGFloat {
        return collectionView?.bounds.width ?? 0.0
    }
    var contentHeight: CGFloat = 0.0
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if let oldWidth = collectionView?.bounds.width {
            return oldWidth != newBounds.width
        }
        return false
    }
    
    override func prepare() {
        guard let collectionView = collectionView, let delegate = delegate as? AMGifVerticalLayoutDelegate else {
            return
        }
        contentHeight = 0
        cache.removeAll()
        
        let numberOfColumns = delegate.numberOfColumns(collectionView)
        
        let columnWidth = self.contentWidth / CGFloat(numberOfColumns)
        var xOffset = [CGFloat]()
        for column in 0 ..< numberOfColumns {
            xOffset.append(CGFloat(column) * columnWidth)
        }
        
        var yOffset = [CGFloat](repeating: 0, count: numberOfColumns)
        
        for item in 0 ..< collectionView.numberOfItems(inSection: 0) {
            
            let indexPath = IndexPath(item: item, section: 0)
            
            let column = yOffset.index(of: yOffset.min()!)!
            let height = delegate.collectionView(collectionView, heightForItemAt: indexPath, withWidth: columnWidth)
            let frame = CGRect(x: xOffset[column], y: yOffset[column], width: columnWidth, height: height)
            
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = frame
            cache.append(attributes)
            
            contentHeight = max(contentHeight, frame.maxY)
            yOffset[column] = yOffset[column] + height
        }
    }
}
