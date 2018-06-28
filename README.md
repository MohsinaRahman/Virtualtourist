# Virtualtourist
Built an app that gives the users the ability to store and retrieve location data/pictures/site information from popular pages. The stored data can be retrieved even without internet connection. For example, Flickr was used to download and store images based on a dropped pin location 
# App functionalities
### MapViewController
a user can drop pins around the world. As soon as a pin is dropped photo data for the pin location is fetched from Flickr. The actual photo downloads occur in the CollectionViewController. User can also select the pic as well as delete the pin

![alt text](https://github.com/MohsinaRahman/Virtualtourist/blob/master/mapview_page.png "Mapview Page")


![alt text](https://github.com/MohsinaRahman/Virtualtourist/blob/master/pin_page.png "Pin Page")


![alt text](https://github.com/MohsinaRahman/Virtualtourist/blob/master/pindeleted_page.png "Pindeleted Page")

### CollectionViewController
User can download photos and edit an album for a location. Users can also see the new collection or delete photos from existing albums


![alt text](https://github.com/MohsinaRahman/Virtualtourist/blob/master/loaded_page.png "Loaded Page")


![alt text](https://github.com/MohsinaRahman/Virtualtourist/blob/master/deleted_page.png "Deleted Page")



# Tools
* MapKit
* UITableViewController
* UICollectionViewController
* JSON parsing
# Requirements
* Xcode 9
* Swift 4.0
* Flicker

# Build and run
For run the app, a user should go to the Clone or Download file. By clicking that, it will give the option for downloading a zip file. By clicking download zip file, it will automatically save on the desktop or in the download file. After that, open the Virtualtourist-master folder and click on the project4.xcodeproj to see the full project or project4 folder to see the project related files
