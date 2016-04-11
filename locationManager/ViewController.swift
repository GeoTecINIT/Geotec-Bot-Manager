
//

//  ViewController.swift

//  locationManager

//

//  Created by Sanjay Noronha on 2015/10/17.

//  Copyright © 2015 funza Academy. All rights reserved.

//

import Foundation
import UIKit
import MapKit


class ViewController: UIViewController,CLLocationManagerDelegate, MKMapViewDelegate{
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var activaGeo: UIButton!
    
    var circle:MKCircle!
    let myLocMgr = CLLocationManager()
    var allBots = NSMutableArray()
    var GeofencingStatus:Int! = 0
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        myLocMgr.desiredAccuracy = kCLLocationAccuracyBest
        myLocMgr.requestAlwaysAuthorization()
        myLocMgr.delegate = self
        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
        activaGeo.enabled = false
        getBots()
        myLocMgr.startUpdatingLocation()
        }

   

    @IBAction func activarGeofence(sender: AnyObject) {
        
        // loop para cada bot
        for bot in allBots{
            //definición de variables
            let botCoord = bot["coord"] as! String
            let botName = bot["name"] as! String
            let botCoordS = botCoord.componentsSeparatedByString(", ")
            
            // si existen las dos coordenadas, continúa...
            if botCoordS.count == 2 {
                let a:Double? = Double(botCoordS[0])     // firstText is UITextField
                let b:Double? = Double(botCoordS[1])   // secondText is UITextField
                // Genera el círculo
                let firstRegionCoord = CLLocationCoordinate2D(latitude: a!, longitude: b!)
                let currRegion = CLCircularRegion(center: firstRegionCoord, radius: 50, identifier: botName)
                circle = MKCircle(centerCoordinate: firstRegionCoord, radius: 50)
                
                //define si ya está activa la región o no
                if(myLocMgr.monitoredRegions.contains(currRegion)){
                    //Eliminar el punto y desactivar la región
                    if GeofencingStatus == 1{ stopGeofencing(currRegion) }
                }else{
                    //Agregar el punto y activar la región
                    if GeofencingStatus == 0{
                        self.mapView.addOverlay(circle)
                        startGeofencing(currRegion)
                    }
                }
            }else{
                print("El bot ", botName, " no se ha cargado porque no posee coordenadas")
            }
            
        }
        // Una vez que agrega los puntos chequea el estado del geofencing
        if GeofencingStatus == 1{
            // elimina los overlays y cambia el estado
            mapView.removeOverlays(mapView.overlays)
            GeofencingStatus = 0
            //modificar el texto del boton
            activaGeo.setTitle("Activar Geofencing", forState: UIControlState.Normal)
        }else if GeofencingStatus == 0{
            // cambia el estado
            GeofencingStatus = 1
            //modificar el texto del boton
            activaGeo.setTitle("Desactivar Geofencing", forState: UIControlState.Normal)
        }
        
    }
    
    func startGeofencing(region: CLCircularRegion){
        //Iniciar el geofencing con determinado punto
        myLocMgr.startMonitoringForRegion(region)
    }
    func stopGeofencing(region: CLCircularRegion){
        //Detener el geofencing con determinado punto
        myLocMgr.stopMonitoringForRegion(region)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // get most recent coordinate
        
        let myCoor = locations[locations.count - 1]
        
       // print("LOCATION 0")
       // print(locations[0])
       // print("LOCATION REC")
       // print(locations[locations.count - 1])
        
        
        
        // get lat and longit
        let myLat = myCoor.coordinate.latitude
        let myLong = myCoor.coordinate.longitude
        let myCoor2D = CLLocationCoordinate2D(latitude: myLat, longitude: myLong)
        
        
        
        // set span
        
        let myLatDelta = 0.02
        let myLongDelta = 0.02
        let mySpan = MKCoordinateSpan(latitudeDelta: myLatDelta, longitudeDelta: myLongDelta)
        let myRegion = MKCoordinateRegion(center: myCoor2D, span: mySpan)
        
        // center map at this region
        
        mapView.setRegion(myRegion, animated: true)
        
       
        
    }
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        // Renderiza el punto
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.fillColor = UIColor.blueColor().colorWithAlphaComponent(0.1)
        circleRenderer.strokeColor = UIColor.blueColor()
        circleRenderer.lineWidth = 1
        return circleRenderer
    }
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        NSLog("Entering region")
        //Alerta cuando entra al área
        let alertController = UIAlertController(title: "Geofencing", message:
            "Entering region", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default,handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)

    }
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        NSLog("Exit region")
        //Alerta cuando sale del
        let alertController = UIAlertController(title: "Geofencing", message:
            "Exit region", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default,handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)

    }
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
         NSLog("\(error)")
    }
    
    func getBots(){
        let requestURL: NSURL = NSURL(string: "https://bots.holabot.es/status.php")!
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(URL: requestURL)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(urlRequest) {
            (data, response, error) -> Void in
            
            let httpResponse = response as! NSHTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode == 200) {
                
                do{
                    
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options:.AllowFragments)
                    
                    if let bots = json["bots"]! as? [[String: AnyObject]] {
                        
                        print("I have the bots")
                        // Loop por los bots, envía las variables al Array principal
                        for bot in bots {
                            if let botname = bot["name"] as? String {
                                if let botid = bot["id"] as? String {
                                    if let botcoord = bot["coordinates"] as? String {
                                        print(botid, botname, botcoord)
                                        self.allBots.addObject(["id": botid, "name": botname, "coord": botcoord])
                                    }
                                }
                                
                            }
                        }
                        //una vez enviadas las variables cambia el estado del botón
                        self.activaGeo.enabled = true
                        self.activaGeo.setTitle("Activar Geofencing", forState: UIControlState.Normal)
                       
                    }
                    
                }catch {
                    print("Error with Json: \(error)")
                }
                
            }

        }
        task.resume()
        
    }
    


}

