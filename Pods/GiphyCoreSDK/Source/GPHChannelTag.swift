//
//  GPHChannel.swift
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

/// Represents Giphy A Channel Tag Object
///
@objcMembers public class GPHChannelTag: NSObject, NSCoding {
    // MARK: Properties
    
    /// ID of this Channel.
    public fileprivate(set) var id: Int?
    
    /// Slug of the Channel.
    public fileprivate(set) var channel: Int?
    
    /// Display name of the Channel.
    public fileprivate(set) var tag: String?
    
    /// Shortd display name of the Channel.
    public fileprivate(set) var rank: Int?
    
    /// JSON Representation.
    public fileprivate(set) var jsonRepresentation: GPHJSONObject?
    
    required convenience public init?(coder aDecoder: NSCoder) {
        self.init()
        
        self.id = aDecoder.decodeObject(forKey: "id") as? Int
        self.channel = aDecoder.decodeObject(forKey: "channel") as? Int
        self.tag = aDecoder.decodeObject(forKey: "tag") as? String
        self.rank = aDecoder.decodeObject(forKey: "rank") as? Int
        
        self.jsonRepresentation = aDecoder.decodeObject(forKey: "jsonRepresentation") as? GPHJSONObject
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.id, forKey: "id")
        aCoder.encode(self.channel, forKey: "channel")
        aCoder.encode(self.tag, forKey: "tag")
        aCoder.encode(self.rank, forKey: "rank")

        aCoder.encode(self.jsonRepresentation, forKey: "jsonRepresentation")
    }
}

/// Make objects human readable.
///
extension GPHChannelTag {
    
    override public var description: String {
        return "GPHChannelTag(\(self.tag ?? "unknown"))"
    }
    
}

extension GPHChannelTag: GPHMappable {
    
    /// This is where the magic/mapping happens + error handling.
    static func mapData(_ root: GPHChannelTag?,
                        data jsonData: GPHJSONObject,
                        request requestType: GPHRequestType,
                        media mediaType: GPHMediaType = .gif,
                        rendition renditionType: GPHRenditionType = .original) throws -> GPHChannelTag {
        
        let obj = GPHChannelTag()
        
        obj.id = (jsonData["id"] as? Int)
        obj.channel = (jsonData["channel"] as? Int)
        obj.tag = (jsonData["tag"] as? String)
        obj.rank = (jsonData["rank"] as? Int)
        
        obj.jsonRepresentation = jsonData
        
        return obj
    }
    
}
