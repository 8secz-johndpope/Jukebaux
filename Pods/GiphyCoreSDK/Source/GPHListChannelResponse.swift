//
//  GPHListCategoryResponse.swift
//  GiphyCoreSDK
//
//  Created by Cem Kozinoglu, Gene Goykhman, Giorgia Marenda, David Hargat on 4/24/17.
//  Copyright © 2017 Giphy. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

import Foundation

/// Represents a Giphy List Channel Response
///
@objcMembers public class GPHListChannelResponse: GPHResponse {
    // MARK: Properties
    
    /// Category Objects.
    public fileprivate(set) var data: [GPHChannel]?
    
    /// Pagination info.
    public fileprivate(set) var pagination: GPHPagination?
    
    // MARK: Initializers
    
    /// Convenience Initializer
    ///
    /// - parameter meta: init with a GPHMeta object.
    /// - parameter data: GPHChannel array (optional).
    /// - parameter pagination: GPHPagination object (optional).
    ///
    convenience public init(_ meta: GPHMeta, data: [GPHChannel]?, pagination: GPHPagination?) {
        self.init()
        self.data = data
        self.pagination = pagination
        self.meta = meta
    }
    
}

// MARK: Extension -- Human readable

/// Make objects human readable.
///
extension GPHListChannelResponse {
    
    override public var description: String {
        return "GPHListChannelResponse(\(self.meta.responseId) status: \(self.meta.status) msg: \(self.meta.msg))"
    }
    
}

// MARK: Extension -- Parsing & Mapping

/// For parsing/mapping protocol.
///
extension GPHListChannelResponse: GPHMappable {
    
    /// This is where the magic/mapping happens + error handling.
    static func mapData(_ root: GPHChannel?,
                        data jsonData: GPHJSONObject,
                        request requestType: GPHRequestType,
                        media mediaType: GPHMediaType = .gif,
                        rendition renditionType: GPHRenditionType = .original) throws -> GPHListChannelResponse {
        guard
            let metaData = jsonData["meta"] as? GPHJSONObject
            else {
                throw GPHJSONMappingError(description: "Couldn't map GPHListChannelResponse due to Meta missing for \(jsonData)")
        }
//        guard
//            let paginationData = jsonData["pagination"] as? GPHJSONObject
//            else {
//                throw GPHJSONMappingError(description: "Couldn't map GPHMediaResponse due to Pagination missing for \(jsonData)")
//        }
        guard
            let resultsData = jsonData["data"] as? [GPHJSONObject]
            else {
                throw GPHJSONMappingError(description: "Couldn't map GPHListChannelResponse due to Results missing for \(jsonData)")
        }
        
        let meta = try GPHMeta.mapData(nil, data: metaData, request: requestType, media: mediaType, rendition: renditionType)
        
        // Get Results
        var results: [GPHChannel] = []
        
        for result in resultsData {
            let result = try GPHChannel.mapData(root, data: result, request: requestType, media: mediaType)
            results.append(result)
        }
        
        // TODO: pagination
        let obj = GPHListChannelResponse(meta, data: results, pagination: nil)
        return obj
    }
}


