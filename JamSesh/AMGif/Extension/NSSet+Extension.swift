//
//  NSSet+Extension.swift
//  AMGiphyPicker
//
//  Created by Alexander Momotiuk on 01.26.18.
//  Copyright © 2018 Alexander Momotiuk. All rights reserved.
//

import Foundation

extension Set where Element == AMGifViewModel {
    
    subscript(index: Int) -> AMGifViewModel? {
        for (elementIndex, element) in self.enumerated() {
            if elementIndex == index {
                return element
            }
        }
        return nil
    }
}

