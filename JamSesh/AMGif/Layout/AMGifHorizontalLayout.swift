//
//  AMGifHorizontalLayout.swift
//  AMGifPicker
//
//  Created by Alexander Momotiuk on 11.01.18.
//  Copyright © 2018 Alexander Momotiuk. All rights reserved.
//

import UIKit

protocol AMGifHorizontalLayoutDelegate: AMGifBaseLayoutDelegate {
    
    func numberOfRows(_ collectionView: UICollectionView) -> Int
    func collectionView(_ collectionView: UICollectionView, widthForItemAt indexPath: IndexPath, withHeight height: CGFloat) -> CGFloat
}

class AMGifHorizontalLayout: AMGifBaseLayout {
    
    var contentHeight: CGFloat {
        return collectionView?.bounds.height ?? 0.0
    }
    var contentWidth: CGFloat = 0.0
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if let oldHeight = collectionView?.bounds.height {
            return oldHeight != newBounds.height
        }
        return false
    }
    
    override func prepare() {
        guard let collectionView = collectionView, let delegate = delegate as? AMGifHorizontalLayoutDelegate else {
            return
        }
        contentWidth = 0
        cache.removeAll()
        
        let numberOfRows = delegate.numberOfRows(collectionView)
        
        let rowHeight = self.contentHeight / CGFloat(numberOfRows)
        var yOffset = [CGFloat]()
        for column in 0 ..< numberOfRows {
            yOffset.append(CGFloat(column) * rowHeight)
        }
        
        var xOffset = [CGFloat](repeating: 0, count: numberOfRows)
        
        for item in 0 ..< collectionView.numberOfItems(inSection: 0) {
            
            let indexPath = IndexPath(item: item, section: 0)
            
            let column = xOffset.index(of: xOffset.min()!)!
            let width = delegate.collectionView(collectionView, widthForItemAt: indexPath, withHeight: rowHeight)
            let frame = CGRect(x: xOffset[column], y: yOffset[column], width: width, height: rowHeight)
            
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = frame
            cache.append(attributes)
            
            self.contentWidth = max(contentWidth, frame.maxX)
            xOffset[column] = xOffset[column] + width
        }
    }
}

