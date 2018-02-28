//
//  GPHListMediaResponse.swift
//  GiphyCoreSDK
//
//  Created by Cem Kozinoglu, Gene Goykhman, Giorgia Marenda on 4/24/17.
//  Copyright © 2017 Giphy. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

import Foundation

/// Represents a Giphy List Media Response (multiple results)
///
@objcMembers public class GPHListMediaResponse: GPHResponse {
    // MARK: Properties

    /// Gifs/Stickers.
    public fileprivate(set) var data: [GPHMedia]?
    
    /// Pagination info.
    public fileprivate(set) var pagination: GPHPagination?
    
    
    // MARK: Initializers
    
    /// Convenience Initializer
    ///
    /// - parameter meta: init with a GPHMeta object.
    /// - parameter data: GPHMedia array (optional).
    /// - parameter pagination: GPHPagination object (optional).
    ///
    convenience public init(_ meta:GPHMeta, data: [GPHMedia]?, pagination: GPHPagination?) {
        self.init()
        self.data = data
        self.pagination = pagination
        self.meta = meta
    }
    
}

// MARK: Extension -- Human readable

/// Make objects human readable.
///
extension GPHListMediaResponse {
    
    override public var description: String {
        return "GPHListMediaResponse(\(self.meta.responseId) status: \(self.meta.status) msg: \(self.meta.msg))"
    }
    
}

// MARK: Extension -- Parsing & Mapping

/// For parsing/mapping protocol.
///
extension GPHListMediaResponse: GPHMappable {
    
    /// This is where the magic/mapping happens + error handling.
    static func mapData(_ root: GPHMedia?,
                               data jsonData: GPHJSONObject,
                               request requestType: GPHRequestType,
                               media mediaType: GPHMediaType = .gif,
                               rendition renditionType: GPHRenditionType = .original) throws -> GPHListMediaResponse {
        guard
            let metaData = jsonData["meta"] as? GPHJSONObject
            else {
                throw GPHJSONMappingError(description: "Couldn't map GPHMediaResponse due to Meta missing for \(jsonData)")
        }
        let meta = try GPHMeta.mapData(nil, data: metaData, request: requestType, media: mediaType, rendition: renditionType)
        
        var pagination: GPHPagination? = nil
        if let paginationData = jsonData["pagination"] as? GPHJSONObject {
            pagination = try GPHPagination.mapData(nil, data: paginationData, request: requestType, media: mediaType)
        }
        
        var results: [GPHMedia]? = nil
        if let mediaData = jsonData["data"] as? [GPHJSONObject] {
            results = []
            for result in mediaData {
                let result = try GPHMedia.mapData(nil, data: result, request: requestType, media: mediaType)
                results?.append(result)
            }
        }
        
        // No image and pagination data, return the meta data
        let obj = GPHListMediaResponse(meta, data: results, pagination: pagination)
        return obj
    }
    
}
