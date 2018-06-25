//
//  FlickrConvenience.swift
//  project4
//
//  Created by mohsina rahman on 6/10/18.
//  Copyright © 2018 mohsina rahman. All rights reserved.
//

import Foundation
import MapKit

extension FlickrClient
{
    func getPhotos(latitude: CLLocationDegrees?, longitude:CLLocationDegrees?, completionHandler: @escaping (_ success: Bool,_ totalImages: Int, _ pages: Int, _ perPage: Int, _ errorString: String?)->Void)
    {
        // Build URL
        let URL : URL
        var parameters : [String: AnyObject] = [:]
        
        // Add the method
        parameters[Constants.Parameters.MethodKey] = Constants.Parameters.MethodValue as AnyObject
        parameters[Constants.Parameters.FormatKey] = Constants.Parameters.FormatValue as AnyObject
        parameters[Constants.Parameters.APIKey] = Constants.Parameters.APIValue as AnyObject
        parameters[Constants.Parameters.BoundingBoxKey] = bboxString(latitude: latitude!, longitude: longitude!) as AnyObject
        parameters[Constants.Parameters.SafeSearchKey] = Constants.Parameters.SafeSearchValue as AnyObject
        parameters[Constants.Parameters.NoJSONCallbackKey] = Constants.Parameters.NoJSONCallbackValue as AnyObject
        
        URL = buildURL(host: Constants.ApiHost, apiPath: Constants.ApiPath, parameters: parameters)
        
        let request = configureRequest(url: URL, methodType: "GET", headers: nil, jsonBody: nil)
        
        makeNetworkRequest(request: request, ignoreInitialCharacters: false)
        {
            (results: AnyObject?, error: Error?)->Void in
            
            // Check for error
            guard (error == nil) else
            {
                print(error!)
                if((error! as NSError).domain == "noInternetConnection")
                {
                    completionHandler(false, 0, 0, 0, "No Internet Connection")
                }
                else
                {
                    completionHandler(false, 0, 0, 0, "Error downloading results from Flickr")
                }
                
                return
            }
            
            
            let photos = results?["photos"] as! [String: AnyObject]
            let totalImages = Int((photos["total"]! as? String)!)
            let pages = photos["pages"]! as? Int
            let perpage = photos["perpage"]! as? Int
            
            completionHandler(true, totalImages!,pages!,perpage!, nil)
        }
    }
    
    func getRandomPhotos(latitude: CLLocationDegrees?, longitude:CLLocationDegrees?, totalImages: Int, totalPages: Int, perPage: Int, maxPhotos: Int, completionHandler: @escaping (_ success: Bool,_ imageURLs:[String],_ errorString: String?)->Void)
    {
        // Build URL
        let URL : URL
        var parameters : [String: AnyObject] = [:]
       
        let highestPageIndex = min(totalPages, 4000/perPage)
        let randomPageIndex = Int(arc4random_uniform(UInt32(highestPageIndex))) + 1
        
        
        // Add the method
        parameters[Constants.Parameters.MethodKey] = Constants.Parameters.MethodValue as AnyObject
        parameters[Constants.Parameters.FormatKey] = Constants.Parameters.FormatValue as AnyObject
        parameters[Constants.Parameters.APIKey] = Constants.Parameters.APIValue as AnyObject
        parameters[Constants.Parameters.BoundingBoxKey] = bboxString(latitude: latitude!, longitude: longitude!) as AnyObject
        parameters[Constants.Parameters.SafeSearchKey] = Constants.Parameters.SafeSearchValue as AnyObject
        parameters[Constants.Parameters.ExtrasKey] = Constants.Parameters.ExtrasValue as AnyObject
        parameters[Constants.Parameters.NoJSONCallbackKey] = Constants.Parameters.NoJSONCallbackValue as AnyObject
        parameters[Constants.Parameters.PageKey] = randomPageIndex as AnyObject
        parameters[Constants.Parameters.PerPageKey] = perPage as AnyObject
        
        URL = buildURL(host: Constants.ApiHost, apiPath: Constants.ApiPath, parameters: parameters)
        
        let request = configureRequest(url: URL, methodType: "GET", headers: nil, jsonBody: nil)
        
        makeNetworkRequest(request: request, ignoreInitialCharacters: false)
        {
            (results: AnyObject?, error: Error?)->Void in
            
            // Check for error
            guard (error == nil) else
            {
                print(error!)
                if((error! as NSError).domain == "noInternetConnection")
                {
                    completionHandler(false, [], "No Internet Connection")
                }
                else
                {
                    completionHandler(false, [], "Error downloading results from Flickr")
                }
                
                return
            }
            
            let photos = results?["photos"] as! [String: AnyObject]
            let photoArray = photos["photo"] as! [[String: AnyObject]]
            
            // Create a set of integers, with a random list of photo indexes with no repetition
            let numPhotos = min(photoArray.count, maxPhotos)
            var indexSet = Set<Int>()
            var randomPhotoIndex: Int
            while(indexSet.count < numPhotos)
            {
                // Generate a random number not yet in the set
                repeat
                {
                    randomPhotoIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
                }
                    while(indexSet.contains(randomPhotoIndex))
                
                indexSet.insert(randomPhotoIndex)
            }
            
            
            var imageURLs: [String] = []
            for index in indexSet
            {
                if(imageURLs.count < numPhotos)
                {
                    imageURLs.append(photoArray[index]["url_m"] as! String)
                }
                else
                {
                    break
                }
            }
            completionHandler(true, imageURLs, nil)
        }
    }
    
    func getImageFromUrl(urlString: String, completionHandler: @escaping (_ success: Bool, _ urlString:String?, _ imageData: Data?, _ errorString: String?)->Void)
    {
        // Build the URL
        let url = URL(string: urlString)
        
        // Start the taks
        let task = URLSession.shared.dataTask(with: url!)
        {
            data, response, error in
            
            func sendError(_ error: String)
            {
                print(error)
                let internetOfflineErrorMessage = "NSURLErrorDomain Code=-1009"
                // let userInfo = [NSLocalizedDescriptionKey : error]
                if(error.contains(internetOfflineErrorMessage))
                {
                    completionHandler(false, nil, nil, error)
                }
                else
                {
                    completionHandler(false, nil, nil, error)
                }
            }
            
            // GUARD: Was there an error?
            guard (error == nil) else
            {
                sendError("There was an error with your request: \(error!)")
                return
            }
            
            // GUARD: Did we get a successful 2XX response?
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else
            {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            // GUARD: Was there any data returned?
            guard let data = data else
            {
                sendError("No data was returned by the request!")
                return
            }
            
            completionHandler(true, urlString, data, nil)
        }
        
        task.resume()
    }
    
    
    private func bboxString(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> String
    {
        let minimumLon = max(longitude - Constants.SearchBBoxHalfWidth, Constants.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.SearchBBoxHalfHeight, Constants.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.SearchBBoxHalfWidth, Constants.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.SearchBBoxHalfHeight, Constants.SearchLatRange.1)
        
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
}
