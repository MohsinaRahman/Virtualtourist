//
//  FlickrConstants.swift
//  project4
//
//  Created by mohsina rahman on 6/8/18.
//  Copyright © 2018 mohsina rahman. All rights reserved.
//

import Foundation

extension FlickrClient
{
    struct Constants
    {
        static let ApiScheme = "https"
        static let ApiHost = "api.flickr.com"
        static let ApiPath = "/services/rest"
        
        struct Parameters
        {
            static let MethodKey = "method"
            static let APIKey = "api_key"
            static let ExtrasKey = "extras"
            static let FormatKey = "format"
            static let NoJSONCallbackKey = "nojsoncallback"
            static let SafeSearchKey = "safe_search"
            static let BoundingBoxKey = "bbox"
            static let PageKey = "page"
            static let PerPageKey = "perpage"
            
            static let MethodValue = "flickr.photos.search"
            static let APIValue = "5414efea98b088ca63ffaeddb5dfa561"
            static let ExtrasValue = "url_m"
            static let FormatValue = "json"
            static let NoJSONCallbackValue = "1"
            static let SafeSearchValue = "1"
        }
        
        struct JSONResponseKeys
        {
            static let Status = "stat"
            static let Photos = "photos"
            static let Photo = "photo"
            static let Title = "title"
            static let MediumURL = "url_m"
            static let Pages = "pages"
            static let Total = "total"
        }
        
        static let SearchBBoxHalfWidth = 0.05
        static let SearchBBoxHalfHeight = 0.05
        static let SearchLatRange = (-90.0, 90.0)
        static let SearchLonRange = (-180.0, 180.0)
        
        static let maxImagesPerAlbum = 21
    }
}
