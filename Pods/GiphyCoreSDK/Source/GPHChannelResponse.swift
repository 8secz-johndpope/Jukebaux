//
//  GPHChannelResponse.swift
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

/// Represents a Giphy List Channel Response (multiple results)
///
@objcMembers public class GPHChannelResponse: GPHResponse {
    // MARK: Properties
    
    /// Channel object.
    public fileprivate(set) var data: GPHChannel?
    
    // MARK: Initializers
    
    /// Convenience Initializer
    ///
    /// - parameter meta: init with a GPHMeta object.
    /// - parameter data: GPHChannel object.
    ///
    convenience public init(_ meta: GPHMeta, data: GPHChannel) {
        self.init()
        self.data = data
        self.meta = meta
    }
}

// MARK: Extension -- Human readable

/// Make objects human readable.
///
extension GPHChannelResponse {
    
    override public var description: String {
        return "GPHChannelResponse(\(self.meta.responseId) status: \(self.meta.status) msg: \(self.meta.msg))"
    }
    
}

// MARK: Extension -- Parsing & Mapping
extension GPHChannelResponse: GPHMappable {
    
    static func mapData(_ root: GPHChannel?,
                        data jsonData: GPHJSONObject,
                        request requestType: GPHRequestType,
                        media mediaType: GPHMediaType = .gif,
                        rendition renditionType: GPHRenditionType = .original) throws -> GPHChannelResponse {
        
        guard
            let metaData = jsonData["meta"] as? GPHJSONObject
            else {
                throw GPHJSONMappingError(description: "Couldn't map GPHChannel due to missing 'meta' field: \(jsonData)")
        }
        
        guard
            let channelData = jsonData["data"] as? GPHJSONObject
            else {
                throw GPHJSONMappingError(description: "Couldn't map GPHChannel due to missing 'data' field: \(jsonData)")
        }
        
        let meta = try GPHMeta.mapData(nil, data: metaData, request: requestType, media: mediaType, rendition: renditionType)
        let channel = try GPHChannel.mapData(nil, data: channelData, request: requestType, media: mediaType)
        
        return GPHChannelResponse(meta, data: channel)
    }
    
}
