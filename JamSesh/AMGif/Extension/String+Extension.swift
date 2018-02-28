//
//  String+Extension.swift
//  AMGiphyPicker
//
//  Created by Alexander Momotiuk on 01.26.18.
//  Copyright © 2018 Alexander Momotiuk. All rights reserved.
//

import Foundation

extension Optional where Wrapped == String {
    
    var emptyIfNil: Int {
        guard let value = self else {
            return 0
        }
        return value.count
    }
}
