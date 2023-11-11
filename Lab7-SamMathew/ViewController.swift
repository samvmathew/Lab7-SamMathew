//
//  ViewController.swift
//  Lab7-SamMathew
//
//  Created by Sam Mathew on 2023-11-08.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController,CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var currentSpeed: UILabel! // Current Speed Label
    
    @IBOutlet weak var maxSpeed: UILabel!   // Max Speed Label
    
    @IBOutlet weak var avgSpeed: UILabel!   // Average Speed Label
    
    @IBOutlet weak var distanceLabel: UILabel! // Distance Label
    
    @IBOutlet weak var maxAcceleration: UILabel!    // Max Acceleration Label
    
    @IBOutlet weak var startTrip: UIButton! // Start Trip Button Outlet
    
    @IBOutlet weak var stopTrip: UIButton!  // Stop Trip Button Outlet
    
    @IBOutlet weak var overSpeedBar: UIButton!  // Over Speed Bar
    
    @IBOutlet weak var mapView: MKMapView!  // Map View
    
    @IBOutlet weak var tripStartBar: UIButton!  // Bar indicating trip started or not
    
    var startingTime: Date? // Current instance time
    var tripOn = false // to check if trip started or not or ended
    var cuSpeed: CLLocationSpeed = 0.0 // initial speed
    var mxSpeed: CLLocationSpeed = 0.0
    var totalDistance: CLLocationDistance = 0.0
    var mxAcceleration: Double = 0.0
    let regionInMeters: Double = 500
    
    var locationManager = CLLocationManager ()
    var locations: [CLLocation] = []
    var distanceBeforeExceeding = 0.0
    var calculatedDistance = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        initialValues()
        locationManager.delegate = self
        mapView.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        mapView.showsUserLocation = true
        zoomUser()
    }
    
    func initialValues(){ // setting initial values to attributes
        currentSpeed.text = "0 km/h"
        maxSpeed.text = "0 km/h"
        avgSpeed.text = "0 km/h"
        distanceLabel.text = "0 km"
        maxAcceleration.text = "0 m/s^2"
        stopTrip.isEnabled = false
        tripStartBar.backgroundColor = UIColor.lightGray // Colour when not in movement
        overSpeedBar.backgroundColor = UIColor.clear // Colour when not overspeeding
        locations.removeAll()
        tripOn = false
        cuSpeed = 0.0
        mxSpeed = 0.0
        totalDistance = 0.0
        mxAcceleration = 0.0
        distanceBeforeExceeding = 0.0
        calculatedDistance = false
    }
    
    @IBAction func startTripButton(_ sender: Any) { // button starts the trip
        startingTime = Date()
        initialValues()
        locationManager.startUpdatingLocation()
        tripStartBar.backgroundColor = UIColor.green
        stopTrip.isEnabled = true
        zoomUser()
        tripOn = true
    }
    
    @IBAction func stopTripButton(_ sender: Any) { // button stops the trip
        tripOn = false
        locationManager.stopUpdatingLocation()
        tripStartBar.backgroundColor = UIColor.gray
        stopTrip.isEnabled = false
        currentSpeed.text = "0 km/h"
        overSpeedBar.backgroundColor = UIColor.clear
        print("Max speed == \(mxSpeed)")
        let avg = avgSpeed.text!
        print("Average speed == \(avg)")
        let dist = distanceLabel.text!
        print("Distance Travelled = \(dist)")
        if !calculatedDistance {
            print("Distance Travelled Before Exceeding Speed Limit == \(dist)")
        }else{
            print("Distance Travelled Before Exceeding Speed Limit == \(distanceBeforeExceeding)")
        }
    }
    
    func zoomUser() {
        if let location = locationManager.location?.coordinate {
        let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        mapView.setRegion(region, animated: true)
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if(tripOn){
            guard let location = locations.last else { return }
            let centre = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion.init(center: centre, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
            updateTripInfo(newLocation: location)
            updateContent()
        }
    }
    
    func updateContent() { // Update the trip details
        currentSpeed.text = String(format: "%.2f km/h", cuSpeed)
        maxSpeed.text = String(format: "%.2f km/h", mxSpeed)

        if locations.count > 1 {
            let speedsArray = locations.map { $0.speed * 3.6 } // Convert speeds to km/h
            let averageSpeed = speedsArray.reduce(0, +) / Double(speedsArray.count)
            avgSpeed
                .text = String(format: "%.2f km/h", averageSpeed)
        } else {
            avgSpeed.text = "0 km/h"
        }

        distanceLabel.text = String(format: "%.2f km", totalDistance / 1000)
        maxAcceleration.text = String(format: "%.2f m/s^2", mxAcceleration)

        if cuSpeed > 115 { // check if overspeeding or not
            if !calculatedDistance{
                distanceBeforeExceeding = totalDistance/1000
                calculatedDistance = true
            }
            overSpeedBar.backgroundColor = UIColor.red
        } else {
            overSpeedBar.backgroundColor = UIColor.clear
        }
        print("Current speed == \(cuSpeed)")
    }
    
    
    func updateTripInfo(newLocation: CLLocation) {
        if let startTime = startingTime {
            let currentTime = Date()
            let timeInterval = currentTime.timeIntervalSince(startTime)
            let speed = newLocation.speed * 3.6 // m/s to km/h
            cuSpeed = speed

            if speed > mxSpeed {
                mxSpeed = speed
            }
            locations.append(newLocation)

            if locations.count > 1 { // Calculate distance based on the array of locations
                totalDistance += newLocation.distance(from: locations[locations.count - 2])
            }
                
            let previousSpeed = locations.count > 1 ? locations[locations.count - 2].speed * 3.6 : 0.0
            let acceleration = abs((speed - previousSpeed) / timeInterval)
            if acceleration > mxAcceleration {
                mxAcceleration = acceleration
            }
        }
    }
}

