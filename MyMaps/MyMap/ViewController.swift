//
//  ViewController.swift
//  MyMap
//
//  Created by Manjunath Shivakumara on 21/12/17.
//  Copyright © 2017 Manjunath Shivakumara. All rights reserved.
//

import UIKit
import GoogleMaps

class ViewController: UIViewController,CLLocationManagerDelegate {
    var locationManager  = CLLocationManager()
    @IBOutlet var locationTitle : UILabel!
    var locTimer : Timer! = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if locTimer == nil
        {
            locTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { (timer) in
                self .checkForPermissionAndPush()
            })
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.isNavigationBarHidden = true
        
        self .setupLocationManager()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: .UIApplicationDidBecomeActive,
                                               object: nil)
    }
    
    func checkForPermissionAndPush()
    {
        if CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse{
            if locTimer != nil
            {
                locTimer.invalidate()
                locTimer = nil
            }
            
            let mapsVC : MapsViewController = storyboard?.instantiateViewController(withIdentifier: "MapsViewController") as! MapsViewController
            self.navigationController?.pushViewController(mapsVC, animated: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidBecomeActive, object: nil)
    }
    
    @objc func applicationDidBecomeActive()
    {
        self .checkForPermissionAndPush()
    }

    private func setupLocationManager() {

        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        if (CLLocationManager.locationServicesEnabled())
        {
            locationTitle.text = "Getting your location"
            if CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse{

                locationManager.startUpdatingLocation()

            }else{
                locationManager.requestWhenInUseAuthorization()
            }
        }
        else
        {
            locationTitle.text = "Location Services Disabled"
        }
    }

}

