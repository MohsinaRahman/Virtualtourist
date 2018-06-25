//
//  CollectionViewController.swift
//  project4
//
//  Created by mohsina rahman on 6/8/18.
//  Copyright © 2018 mohsina rahman. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController,UICollectionViewDelegate, UICollectionViewDataSource,MKMapViewDelegate
{

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var layout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var bottomToolbar: UIToolbar!
    
    @IBOutlet weak var newCollection: UIBarButtonItem!
    
    var pin: Pin!
    var dataController: DataController!
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    
    var saveObserverToken: Any?
    var itemsToDelete = Set<IndexPath>()
    
    var isEditMode = false
    var pinHasNoImagesLabel: UILabel?
    var totalImagesToFetch: Int = 0
    var imagesFetchedSoFar: Int = 0
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        addSaveNotificationObserver()
        
        let location = CLLocationCoordinate2D(latitude: (pin?.latitude)!, longitude: (pin?.longitude)!)
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location, 1000, 1000)
        mapView.setRegion(coordinateRegion, animated: true)
        mapView.delegate = self
        
        addMapAnnotation(pin: pin!)
        
        setFlowLayoutParams()
        collectionView.reloadData()
        
        updateControls(editing: isEditMode)
        
        if(self.pinHasNoImagesLabel == nil)
        {
            self.pinHasNoImagesLabel = UILabel(frame: CGRect(x:0, y:0, width:200, height:25))
            self.pinHasNoImagesLabel!.text = "This pin has no images"
            self.pinHasNoImagesLabel!.textColor = UIColor.red
            self.pinHasNoImagesLabel!.center = CGPoint(x: self.view.frame.width / 2, y: 200)
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
        
        setFlowLayoutParams()
        collectionView.reloadData()
        
        // Check to see if we have already downloaded an album
        if(fetchedResultsController.fetchedObjects!.count == 0)
        {
            // If not, initiate a new download
            startNewDownload()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    override func viewWillLayoutSubviews()
    {
        super.viewWillLayoutSubviews()
        
        setFlowLayoutParams()
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return min(FlickrClient.Constants.maxImagesPerAlbum, fetchedResultsController.fetchedObjects?.count ?? 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell (withReuseIdentifier: "collectionViewCell", for: indexPath) as! CollectionViewCell
        cell.layer.borderWidth = 1.0
        cell.layer.borderColor = UIColor.black.cgColor
        
        let photoObjectID = fetchedResultsController.object(at: indexPath).objectID
        var photo = dataController.backgroundContext.object(with: photoObjectID) as! Photo
        if(photo.file != nil)
        {
            // Update the image
            cell.imageView.image = UIImage(data: photo.file!)
        }
        else
        {
            cell.imageView.image = UIImage(named: "VirtualTourist_180")
            // Create the activity indicator, set it's properties and start animating
            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
            cell.addSubview(activityIndicator)
            activityIndicator.center = CGPoint(x: cell.bounds.size.width/2, y: cell.bounds.size.height/2)
            activityIndicator.color = UIColor.black
            activityIndicator.startAnimating()
            
            FlickrClient.sharedInstance().getImageFromUrl(urlString: photo.url!)
            {
                (_ success: Bool, _ imagePath: String?, _ imageData: Data?, _ errorString: String?)->Void in
                
                var allDone = false
                
                if(success)
                {
                    performUIUpdatesOnMain
                        {
                            
                            self.imagesFetchedSoFar = self.imagesFetchedSoFar + 1
                            if(self.imagesFetchedSoFar == self.totalImagesToFetch)
                            {
                                allDone = true
                                
                                if(allDone)
                                {
                                    // Re-enable the toolbar button
                                    self.newCollection.isEnabled = true
                                    // Stop the animation of the activity indicator
                                    activityIndicator.stopAnimating()
                                    activityIndicator.removeFromSuperview()
                                }
                            }
                    }
                    
                    self.dataController.backgroundContext.perform
                        {
                            photo = self.dataController.backgroundContext.object(with: photoObjectID) as! Photo
                            photo.file = imageData
                            try? self.dataController.backgroundContext.save()
                    }
                }
                else
                {
                    print("Error downloading image")
                }
                
            }
        }
        
        if(itemsToDelete.contains(indexPath))
        {
            cell.alpha = 0.5
        }
        
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        if(itemsToDelete.contains(indexPath))
        {
            itemsToDelete.remove(indexPath)
        }
        else
        {
            itemsToDelete.insert(indexPath)
        }
        
        isEditMode = itemsToDelete.count > 0
        updateControls(editing: isEditMode)
        
        collectionView.reloadData()
    }
    
    func setFlowLayoutParams()
    {
        let horizontalSpacing = 0
        let verticalSpacing = 2
        let numItems = 3
        let width = UIScreen.main.bounds.width
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: (width / CGFloat(numItems)) - CGFloat(numItems - horizontalSpacing), height: (width / CGFloat(numItems)) -  CGFloat(numItems - horizontalSpacing))
        layout.minimumInteritemSpacing = CGFloat(horizontalSpacing)
        layout.minimumLineSpacing = CGFloat(verticalSpacing)
    }
    
    func startNewDownload()
    {
        // Disable button
        newCollection.isEnabled = false
        totalImagesToFetch = FlickrClient.Constants.maxImagesPerAlbum
        imagesFetchedSoFar = 0
        
        
        performUIUpdatesOnMain
            {
                self.pinHasNoImagesLabel?.removeFromSuperview()
        }
        
        let pinID = pin.objectID
        FlickrClient.sharedInstance().getPhotos(latitude: pin!.latitude, longitude: pin?.longitude)
        {
            (_ success: Bool, _ totalImages: Int, _ pages: Int, _ perPage: Int, _ errorString: String?)->Void in
            
            if(success)
            {
                if(totalImages > 0)
                {
                    FlickrClient.sharedInstance().getRandomPhotos(latitude: self.pin!.latitude, longitude: self.pin?.longitude, totalImages: totalImages, totalPages: pages, perPage: perPage, maxPhotos: FlickrClient.Constants.maxImagesPerAlbum)
                    {
                        (_ success: Bool, _ imageURLs: [String], _ errorString: String?)->Void in
                        
                        if(success)
                        {
                            self.totalImagesToFetch = imageURLs.count
                            self.imagesFetchedSoFar = 0
                            
                            self.dataController.backgroundContext.perform
                                {
                                    for url in imageURLs
                                    {
                                        let photo = Photo(context: self.dataController.backgroundContext)
                                        photo.downloadDate = Date()
                                        photo.url = url
                                        photo.file = nil
                                        photo.pin = self.dataController.backgroundContext.object(with: pinID) as? Pin
                                    }
                                    
                                    // Save
                                    try? self.dataController.backgroundContext.save()
                            }
                            
                            performUIUpdatesOnMain
                                {
                                    self.collectionView.reloadData()
                            }
                        }
                        else
                        {
                            // Display error message
                            performUIUpdatesOnMain
                                {
                                    self.showError(message: errorString!)
                            }
                        }
                    }
                }
                else
                {
                    performUIUpdatesOnMain
                        {
                            self.view.addSubview(self.pinHasNoImagesLabel!)
                            self.newCollection.isEnabled = false
                    }
                }
            }
            else
            {
                // Display error message
                performUIUpdatesOnMain
                    {
                        self.showError(message: errorString!)
                }
            }
        }
    }
    
    @IBAction func newCollectionPressed(_ sender: Any)
    {
        if(isEditMode)
        {
            for item in itemsToDelete
            {
                let objectID = fetchedResultsController.object(at: item).objectID
                dataController.backgroundContext.perform
                    {
                        let photoToDelete = self.dataController.backgroundContext.object(with: objectID)
                        self.dataController.backgroundContext.delete(photoToDelete)
                }
            }
            itemsToDelete.removeAll()
            dataController.backgroundContext.perform
                {
                    try? self.dataController.backgroundContext.save()
            }
        }
        else
        {
            if((fetchedResultsController.fetchedObjects?.count)! > 0)
            {
                // Retrive the list of object IDs for each photo
                let photos = fetchedResultsController.fetchedObjects
                var objectIDs = [NSManagedObjectID]()
                for photo in photos!
                {
                    objectIDs.append(photo.objectID)
                }
                
                // Remove all the photos using the object IDs
                dataController.backgroundContext.perform
                    {
                        for objectID in objectIDs
                        {
                            let photoToDelete = self.dataController.backgroundContext.object(with: objectID)
                            self.dataController.backgroundContext.delete(photoToDelete)
                        }
                        
                        // Save the data
                        try? self.dataController.backgroundContext.save()
                }
                
                // Fetch photos again
                startNewDownload()
            }
        }
    }
    
    deinit
    {
        removeSaveNotificationObserver()
    }
    
    func updateControls(editing: Bool)
    {
        if(editing)
        {
            newCollection.title = "Remove Selected Pictures"
        }
        else
        {
            newCollection.title = "New Collection"
        }
    }
    
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate
{
    fileprivate func setupFetchedResultsController()
    {
        // Create the fetch request
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        // Set up the predicate
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        // Set up the sort order
        let sortDescriptor = NSSortDescriptor(key: "downloadDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Create the fetch results controller
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Set up the delegate
        fetchedResultsController.delegate = self
        
        // Perform the fetch
        do
        {
            try fetchedResultsController.performFetch()
        }
        catch
        {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    {
        switch type
        {
        case .insert:
            print("Insert Operation")
            break
        case .delete:
            print("Delete Operation")
            performUIUpdatesOnMain
                {
                    self.isEditMode = self.itemsToDelete.count > 0
                    self.updateControls(editing: self.isEditMode)
                    self.collectionView.reloadData()
            }
            break
        case .update:
            print("Update Operation")
            performUIUpdatesOnMain
                {
                    self.collectionView.reloadData()
            }
            break
        case .move:
            print("Move Operation")
            break
        }
    }
    
    func addMapAnnotation(pin: Pin)
    {
        // Create the annotation
        let annotation = MKPointAnnotation()
        // Set the coordinates
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        // Add it to the map
        mapView.addAnnotation(annotation)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        let reuseId = "TouristLocationPin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil
        {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.pinTintColor = .red
        }
        else
        {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    
    func showError(message: String)
    {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }
    
}

extension PhotoAlbumViewController
{
    func addSaveNotificationObserver()
    {
        removeSaveNotificationObserver()
        saveObserverToken = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: dataController?.viewContext, queue: nil, using: handleSaveNotification(notification:))
    }
    
    func removeSaveNotificationObserver()
    {
        if let token = saveObserverToken
        {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    fileprivate func updateCollectionView()
    {
        collectionView.reloadData()
    }
    
    func handleSaveNotification(notification:Notification)
    {
        performUIUpdatesOnMain
            {
                self.updateCollectionView()
        }
    }
}

