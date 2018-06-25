//
//  ViewController.swift
//  project4
//
//  Created by mohsina rahman on 5/31/18.
//  Copyright © 2018 mohsina rahman. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate
{
    var dataController:DataController!
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    var isEditMode = false
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var longPress: UILongPressGestureRecognizer!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var toolbar: UIToolbar!
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        mapView.delegate = self
        
        setupFetchedResultsController()
        
        for item in fetchedResultsController.fetchedObjects!
        {
            addMapAnnotation(pin: item)
        }
        
        isEditMode = false
        updateControls(editing: isEditMode)
    }

    
    @IBAction func longpressed(_ sender:UILongPressGestureRecognizer)
    {
        if(!isEditMode)
        {
            if(sender.state == .ended)
            {
                // Detect where the user pressed
                let touchPoint = sender.location(in: mapView)
                // Convert the touched location to a lat/long location
                let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
                // Add the pin
                addPin(latitude: newCoordinates.latitude, longitude: newCoordinates.longitude)
                // Update the UI
                updateControls(editing: isEditMode)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        let reuseId = "TouristLocationPin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil
        {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.animatesDrop = true
            pinView?.canShowCallout = false
            pinView?.pinTintColor = .red
        }
        else
        {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)
    {
        mapView.deselectAnnotation(view.annotation!, animated: true)
        if(isEditMode)
        {
            deletePin(for: view.annotation!)
            updateControls(editing: isEditMode)
        }
        else
        {
            let controller = self.storyboard?.instantiateViewController(withIdentifier: "collectionViewController") as! PhotoAlbumViewController
            
           controller.dataController = dataController
           controller.pin = getPin(for: view.annotation!)
            
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    @IBAction func editPressed(_ sender: Any)
    {
        isEditMode = !isEditMode
        updateControls(editing: isEditMode)
    }
    
    func updateControls(editing: Bool)
    {
        if(editing)
        {
            toolbar.isHidden = false
            editButton.title = "Done"
        }
        else
        {
            toolbar.isHidden = true
            editButton.title = "Edit"
        }
        editButton.isEnabled = isEditMode || ((!isEditMode) && mapView.annotations.count > 0)
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
    
    func deleteMapAnnotation(pin: Pin)
    {
        for annotation in mapView.annotations
        {
            if(annotation.coordinate.latitude == pin.latitude && annotation.coordinate.longitude == pin.longitude)
            {
                // Remove the annotation from the map
                mapView.removeAnnotation(annotation)
                break
            }
        }
    }
    
    
}

extension MapViewController: NSFetchedResultsControllerDelegate
{
    fileprivate func setupFetchedResultsController()
    {
        // Create the fetch request
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        
        // Set up the fetch request with sorting
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        
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
            let pin = anObject as! Pin
            addMapAnnotation(pin: pin)
            break
        case .delete:
            print("Delete Operation")
            let pin = anObject as! Pin
            deleteMapAnnotation(pin: pin)
            break
        case .update:
            print("Update Operation")
            break
        case .move:
            print("Move Operation")
            break
        }
    }
    
    func addPin(latitude: CLLocationDegrees, longitude: CLLocationDegrees)
    {
        // Create the pin
        let pin = Pin(context: dataController.viewContext)
        // Set properties
        pin.latitude = latitude
        pin.longitude = longitude
        // Save
        try? dataController.viewContext.save()
    }
    
    func deletePin(for annotation: MKAnnotation)
    {
        // Find the associated pin that matches the latitude and longitude
        let pinToDelete: Pin? = getPin(for: annotation)
        
        // Delete the pin if found
        if(pinToDelete != nil)
        {
            dataController.viewContext.delete(pinToDelete!)
            try? dataController.viewContext.save()
        }
    }
    
    func getPin(for annotation: MKAnnotation)->Pin?
    {
        var pin: Pin?
        
        for item in fetchedResultsController.fetchedObjects!
        {
            if(item.latitude == annotation.coordinate.latitude && item.longitude == annotation.coordinate.longitude)
            {
                pin = item
                
                break
            }
        }
        
        return pin
    }
}
