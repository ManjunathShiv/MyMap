//
//  MapsViewController.swift
//  MyMap
//
//  Created by Manjunath Shivakumara on 21/12/17.
//  Copyright © 2017 Manjunath Shivakumara. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import Alamofire
import SwiftyJSON

class MapsViewController: UIViewController {
    var locationManager  = CLLocationManager()
    @IBOutlet var mapDisplayView : GMSMapView!
    @IBOutlet var addressView : UIView!
    @IBOutlet var sourceTF : UITextField!
    @IBOutlet var destinationTF : UITextField!
    @IBOutlet var startBtn : UIButton!
    var selectedTextField : UITextField!
    let M_PI  = 3.14159265358979323846264338327950288
    var journeyStarted : Bool!
    var startMarker : GMSMarker!
    var endMarker : GMSMarker!
    
    var startCoordinates:CLLocationCoordinate2D!
    var endCoordinates:CLLocationCoordinate2D!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        locationManager.delegate = self
        journeyStarted = false
        
        self.navigationController?.isNavigationBarHidden = false
        self.navigationItem.hidesBackButton = true
        self.navigationController?.navigationBar.topItem?.title = "Voyage"
        
        print("location\(String(describing: locationManager.location?.coordinate.latitude))")
        let locCoOdrinates : CLLocationCoordinate2D = (locationManager.location?.coordinate)!
        
        locationManager.startUpdatingLocation()
        locationManager.distanceFilter = 100.0
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        let camera = GMSCameraPosition.camera(withLatitude: locCoOdrinates.latitude, longitude: locCoOdrinates.longitude, zoom: 14.0)
        
        mapDisplayView.camera = camera
        mapDisplayView.settings.compassButton = true
        mapDisplayView.settings.myLocationButton = true
        
        // Creates a marker in the center of the map.
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: locCoOdrinates.latitude, longitude: locCoOdrinates.longitude)
        marker.map = mapDisplayView
        
        sourceTF.text = "Your Current Location"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!){
        
        print(manager.location!)
        
    }
    
    private func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        if status == CLAuthorizationStatus.authorizedWhenInUse || status == CLAuthorizationStatus.authorizedAlways {
            
            manager.startUpdatingLocation()
            
        }
    }
    
    func convertToCoOrdinatesFromAddress(address : String, source : String)
    {
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(address, completionHandler: {(placemarks, error) -> Void in
            if((error) != nil){
                print("Error", error ?? "")
            }
            if let placemark = placemarks?.first {
                let coordinates:CLLocationCoordinate2D = placemark.location!.coordinate
                print("Lat: \(coordinates.latitude) -- Long: \(coordinates.longitude)")
                if source == "start"
                {
                    self.startCoordinates = coordinates
                    let position = CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude)
                    self.startMarker = GMSMarker(position: position)
                    let camera = GMSCameraPosition.camera(withLatitude: coordinates.latitude, longitude: coordinates.longitude, zoom: 10.0)
                    self.mapDisplayView.camera = camera
                    self.mapDisplayView.animate(toZoom: 14.0)
                    self.startMarker.title = address
                    self.startMarker.map = self.mapDisplayView
                    self.startMarker.isDraggable = true
                }
                else
                {
                    self.endCoordinates = coordinates
                    let position = CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude)
                    self.endMarker = GMSMarker(position: position)
                    let camera = GMSCameraPosition.camera(withLatitude: coordinates.latitude, longitude: coordinates.longitude, zoom: 10.0)
                    self.mapDisplayView.camera = camera
                    self.mapDisplayView.animate(toZoom: 14.0)
                    self.endMarker.title = address
                    self.endMarker.map = self.mapDisplayView
                    self.endMarker.isDraggable = true
                    
                }
            }
            
            if self.startCoordinates != nil && self.endCoordinates != nil
            {
                self .drawPath()
            }
        })
        
    }
    
    @IBAction func startJourney()
    {
        if self.startCoordinates != nil && self.endCoordinates != nil
        {
            journeyStarted = true
            self.drawPath()
        }
        else
        {
            self .showAlert(title: "Error", description: "Please enter the start point and end point")
        }
    }
    
    func angle(fromCoordinate first: CLLocationCoordinate2D, toCoordinate second: CLLocationCoordinate2D) -> Float {
        let deltaLongitude = Float((second.longitude - first.longitude))
        let deltaLatitude = Float((second.latitude - first.latitude))
        let angle: Float = (.pi * 0.5) - atan(deltaLatitude / deltaLongitude)
        if deltaLongitude > 0 {
            return angle
        }
        else if deltaLongitude < 0 {
            return angle + .pi
        }
        else if deltaLatitude < 0 {
            return .pi
        }
        
        return 0.0
    }
    
    func showAlert(title : String , description : String) {
        let alertController = UIAlertController(title: title, message: description, preferredStyle: .alert)
        
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func drawPath()
    {
        self.mapDisplayView .clear()
        startMarker = GMSMarker(position: startCoordinates)
        startMarker.map = self.mapDisplayView
        startMarker.position = self.startCoordinates
        if journeyStarted
        {
            if startMarker.icon == nil
            {
                startMarker.icon = UIImage.init(named: "30_Car_top")
            }
        }
        
        endMarker = GMSMarker(position: endCoordinates)
        endMarker.map = self.mapDisplayView
        endMarker.position = self.endCoordinates
        
        let origin = "\(startCoordinates.latitude),\(startCoordinates.longitude)"
        let destination = "\(endCoordinates.latitude),\(endCoordinates.longitude)"
        
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=driving&key=AIzaSyDc_1QxMHj7Bxi93YiUv1B3E8E-YE8zfCE"
        
        
        Alamofire.request(url).responseJSON { response in
            
            print(response.request as Any)  // original URL request
            print(response.response as Any) // HTTP URL response
            print(response.data as Any)     // server data
            print(response.result as Any)   // result of response serialization
            
            if let json = try? JSON(data: response.data!){
                let routes = json["routes"].arrayValue
                
                // print route using Polyline
                for route in routes
                {
                    let routeOverviewPolyline = route["overview_polyline"].dictionary
                    let points = routeOverviewPolyline?["points"]?.stringValue
                    let path = GMSPath.init(fromEncodedPath: points!)
                    let polyline = GMSPolyline.init(path: path)
                    polyline.strokeWidth = 6
                    polyline.strokeColor = UIColor.blue
                    polyline.map = self.mapDisplayView
                    
                }
            }
            else
            {
                print("Error")
            }
            
        }
    }
}

extension MapsViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        print("Place name: \(place.name)")
        print("Place address: \(place.formattedAddress ?? "")")
        print("Place attributions: \(String(describing: place.attributions))")
        dismiss(animated: true, completion: nil)
        selectedTextField.text = place.formattedAddress
        
        if selectedTextField == sourceTF{
            self.convertToCoOrdinatesFromAddress(address: self.sourceTF.text!, source: "start")
        }
        else
        {
            self.convertToCoOrdinatesFromAddress(address: self.destinationTF.text!, source: "end")
        }
        
        
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
}

extension MapsViewController : CLLocationManagerDelegate
{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
        let location : CLLocation = locations.last!
        print("location\(location)")
        
        if self.startCoordinates == nil
        {
            let geocoder = CLGeocoder()
            geocoder .reverseGeocodeLocation(location) { (placemarks, nil) in
                print("Placemarks\(String(describing: placemarks))")
                let placemark : CLPlacemark = (placemarks?.first)!
                let address : String = (placemark.name! + " " + placemark.postalCode! + " " + placemark.locality! + " " + placemark.administrativeArea! + " " + placemark.country!)
                self.sourceTF.text = address
                self.startCoordinates = location.coordinate
                let position = CLLocationCoordinate2D(latitude: self.startCoordinates.latitude, longitude: self.startCoordinates.longitude)
                let marker = GMSMarker(position: position)
                marker.title = address
                marker.map = self.mapDisplayView
                
            }
        }
        else
        {
            if journeyStarted
            {
                let getAngle = self .angle(fromCoordinate: self.startCoordinates, toCoordinate: location.coordinate)
                startMarker.position = location.coordinate
                startMarker.rotation = CLLocationDegrees(getAngle * Float(180.0 / M_PI))
            }
        }
        
    }
}

extension MapsViewController:UITextFieldDelegate
{
    func textFieldDidBeginEditing(_ textField: UITextField) {
        selectedTextField = textField
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
}

