//
//  FileManager+Extension.swift
//  AMGifPicker
//
//  Created by Alexander Momotiuk on 2/15/18.
//  Copyright © 2018 Alexander Momotiuk. All rights reserved.
//

import Foundation
import Alamofire

extension FileManager {
    
    static func tempCacheDestination(_ name: String) -> DownloadRequest.DownloadFileDestination {
        return { _, _ in
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let documentsURL = URL(fileURLWithPath: documentsPath + "/giphy-temporary-cache", isDirectory: true)
            let fileURL = documentsURL.appendingPathComponent(name)
            _ = try? FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true, attributes: nil)
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
    }
    
    static func removeTempCache(file url: URL?) {
        guard let temporaryURL = url else {
            return
        }
        try? FileManager.default.removeItem(at: temporaryURL)
    }
    
}
