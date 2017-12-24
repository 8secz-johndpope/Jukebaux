//
//  Changeset.swift
//  SwiftGoal
//
//  Created by Martin Richter on 01/06/15.
//  Copyright (c) 2015 Martin Richter. All rights reserved.
//

import Foundation

struct Changeset<T: Equatable> {
    
    var deletions: [NSIndexPath]
    var modifications: [NSIndexPath]
    var insertions: [NSIndexPath]
    
    typealias ContentMatches = (T, T) -> Bool
    
    init(oldItems: [T], newItems: [T], contentMatches: ContentMatches) {
        
        deletions = oldItems.difference(otherArray: newItems).map { item in
            return Changeset.indexPathForIndex(index: oldItems.index(of: item)!)
        }
        
        modifications = oldItems.intersection(otherArray: newItems)
            .filter({ item in
                let newItem = newItems[newItems.index(of: item)!]
                return !contentMatches(item, newItem)
            })
            .map({ item in
                return Changeset.indexPathForIndex(index: oldItems.index(of: item)!)
            })
        
        insertions = newItems.difference(otherArray: oldItems).map { item in
            return NSIndexPath(row: newItems.index(of: item)!, section: 0)
        }
    }
    
    private static func indexPathForIndex(index: Int) -> NSIndexPath {
        return NSIndexPath(row: index, section: 0)
    }
}
