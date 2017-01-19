//
//  ViewController.swift
//  Plan42
//
//  Created by Lucas BELVALETTE on 10/14/16.
//  Copyright © 2016 Lucas BELVALETTE. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var startTextField: UITextField!
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var segmentedBar: UISegmentedControl!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var stepsButton: UIButton!

    let locationManager = CLLocationManager()
    var start: MKAnnotation?
    var destination: MKAnnotation?
    var transportType: MKDirectionsTransportType?
    var steps: [MKRouteStep] = []
    
    @IBAction func searchDestination(_ sender: UIButton) {
        if let dest = destinationTextField.text, dest != "" {
            print("Get destination location")
            getLocation(fromString: dest, isDestination: true, zoom: true)
            segmentedBar.isHidden = false
            resetItinerary()
        }
    }
    
    @IBAction func handleDestinationTextField(_ sender: UITextField) {
        if !segmentedBar.isHidden {
            segmentedBar.isHidden = true
        }
        if !distanceLabel.isHidden {
            distanceLabel.isHidden = true
        }
        if !timeLabel.isHidden {
            timeLabel.isHidden = true
        }
        if !stepsButton.isHidden {
            stepsButton.isHidden = true
        }
    }
    
    @IBAction func locateMe(_ sender: UIButton) {
        print("locateMe")
        if let coordinates = locationManager.location?.coordinate {
            zoomToRegion(coordinates)
        }
    }

    @IBAction func drawItinerary(_ sender: UISegmentedControl) {
        switch (sender.selectedSegmentIndex) {
        case 0:
            calculateSegmentDirections(.walking)
        case 1:
            calculateSegmentDirections(.automobile)
        default:
            break
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        mapView.delegate = self
        segmentedBar.isHidden = true
        toggleInfos()
        initLocationManager()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? StepsTableViewController, segue.identifier == "stepsSegue" {
            print("stepsSegue")
            vc.steps = steps
        }
    }
    
    func toggleInfos() {
        distanceLabel.isHidden = !distanceLabel.isHidden
        timeLabel.isHidden = !timeLabel.isHidden
        stepsButton.isHidden = !stepsButton.isHidden
    }
    
    func resetItinerary() {
        self.mapView.removeOverlays(self.mapView.overlays)
        segmentedBar.selectedSegmentIndex = UISegmentedControlNoSegment
        if let a = self.start {
            self.mapView.removeAnnotation(a)
        }
        if let a = self.destination {
            self.mapView.removeAnnotation(a)
        }
    }
    
    func constructPoint(_ title: String, coordinates: CLLocationCoordinate2D) -> MKPointAnnotation {
        let point = MKPointAnnotation()
        
        point.coordinate = coordinates
        point.title = title
        
        return point
    }
    
    func getLocation(fromString str: String, isDestination: Bool, zoom: Bool) {
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(str) {
            (placemarks, error) in
            if let placemark = placemarks?.first {
                let coordinates = placemark.location!.coordinate
                let point = self.constructPoint(str, coordinates: coordinates)
                
                if isDestination {
                    if let a = self.destination {
                        self.mapView.removeAnnotation(a)
                    }
                    self.destination = point
                } else {
                    if let a = self.start {
                        self.mapView.removeAnnotation(a)
                    }
                    self.start = point
                    self.getRoutes(point.coordinate)
                }
                self.mapView.addAnnotation(point)
                if zoom {
                    self.zoomToRegion(coordinates)
                }
            }
        }
    }

    func calculateSegmentDirections(_ transportType: MKDirectionsTransportType) {
        print("calculateSegmentDirections")
        self.transportType = transportType

        if let start = startTextField.text, start != "" {
            print("Get source location")
            getLocation(fromString: start, isDestination: false, zoom: false)
        } else {
            if let srcCoordinates = locationManager.location?.coordinate {
                print("getRoutes from current position")
                getRoutes(srcCoordinates)
            }
        }
    }
    
    func getRoutes(_ srcCoordinates: CLLocationCoordinate2D) {
        if let dest = destination, let tt = transportType {
            let request = MKDirectionsRequest()
            let s = MKMapItem(placemark: MKPlacemark(coordinate: srcCoordinates, addressDictionary: nil))
            let d = MKMapItem(placemark: MKPlacemark(coordinate: dest.coordinate, addressDictionary: nil))
            
            print("Get routes")
            request.source = s
            request.destination = d
            request.transportType = tt
            
            let directions = MKDirections(request: request)
            directions.calculate {
                (response: MKDirectionsResponse?, error: Error?) in
                if let routeResponse = response?.routes {
                    print(routeResponse)
                    self.mapView.removeOverlays(self.mapView.overlays)
                    self.showRoutes(routeResponse)
                } else if let err = error {
                    print(err)
                }
            } 
        }
    }
    
    func showRoutes(_ routes: [MKRoute]) {
        if !routes.isEmpty {
            let route = routes[0]
    
            print("Show routes")
            steps = route.steps
            distanceLabel.isHidden = false
            distanceLabel.text = String(route.distance / 1000) + " km"
            timeLabel.isHidden = false
            stepsButton.isHidden = false
            timeLabel.text = stringFromTimeInterval(route.expectedTravelTime) as String
            plotPolyline(route)
        }
    }
    
    func plotPolyline(_ route: MKRoute) {
        mapView.add(route.polyline)
        mapView.setVisibleMapRect(route.polyline.boundingMapRect,
                                  edgePadding: UIEdgeInsetsMake(25.0, 25.0, 25.0, 25.0),
                                  animated: false)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)

        if (overlay is MKPolyline) {
            polylineRenderer.strokeColor = UIColor.blue.withAlphaComponent(0.75)
            polylineRenderer.lineWidth = 3
        }

        return polylineRenderer
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.count > 0 {
            zoomToRegion(locations[0].coordinate)
        }
    }
    
    func zoomToRegion(_ coordinates: CLLocationCoordinate2D) {
        let region = MKCoordinateRegionMakeWithDistance(coordinates, 1000.0, 1000.0)

        mapView.setRegion(region, animated: true)
    }
    
    func initLocationManager() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 10
        locationManager.startUpdatingLocation()
        if let coordinates = locationManager.location?.coordinate {
            zoomToRegion(coordinates)
        }
    }

    func stringFromTimeInterval(_ interval: TimeInterval) -> NSString {
        let ti = NSInteger(interval)
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        
        return NSString(format: "%0.2dh%0.2d", hours, minutes)
    }
}

