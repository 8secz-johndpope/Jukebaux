//
//  Extensions.swift
//  Jukebaux
//
//  Created by Adam Moffitt on 12/22/17.
//  Copyright © 2017 Adam's Apps. All rights reserved.
//

import Foundation

extension Array {
    func difference<T: Equatable>(otherArray: [T]) -> [T] {
        var result = [T]()
        
        for e in self {
            if let element = e as? T {
                if !otherArray.contains(element) {
                    result.append(element)
                }
            }
        }
        
        return result
    }
    
    func intersection<T: Equatable>(otherArray: [T]) -> [T] {
        var result = [T]()
        
        for e in self {
            if let element = e as? T {
                if otherArray.contains(element) {
                    result.append(element)
                }
            }
        }
        
        return result
    }

    mutating func rearrange(from: Int, to: Int) {
        precondition(from != to && indices.contains(from) && indices.contains(to), "invalid indexes")
        insert(remove(at: from), at: to)
    }
}

