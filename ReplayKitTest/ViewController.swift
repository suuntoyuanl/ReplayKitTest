//
//  ViewController.swift
//  ReplayKitTest
//
//  Created by 袁量 on 2024/8/9.
//

import UIKit
import AMapFoundationKit

class ViewController: UIViewController {
    
    /// 地图相关信息
    var mapView: MAMapView!
    ///轨迹坐标点
    var s_coords : [CLLocationCoordinate2D] = []
    ///车头方向跟随转动
    var car1: CustomMovingAnnotation!
    ///走过轨迹的overlay
    var passedTraceLine: MAPolyline!
    
    var passedTraceCoordIndex: Int = 0
    var distanceArray = [Double]()
    var sumDistance: Double = 0.0
    
    weak var car1View: MAAnnotationView?
    private var timer: Timer!
    
    let recorder = ScreenRecorder()
    override func viewDidLoad() {
        super.viewDidLoad()
        initData()
        initMapView()
        let btn = UIButton(frame: CGRect(x: 10, y: 100, width: 80, height: 40))
        view.addSubview(btn)
        btn.setTitle("调试", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.addTarget(self, action: #selector(debug), for: .touchUpInside)
        // Do any additional setup after loading the view.
    }
    
    @objc private func debug() {
        print("")
        mov()
    }
    @IBAction func random(_ sender: Any) {
    }
    
    @IBAction func start(_ sender: Any) {
//        let outputPath = "\(NSTemporaryDirectory())output.mov"
        recorder.startRecording(withFileName: "12313测试.mp4")
    }
    @IBAction func end(_ sender: Any) {
        recorder.stopRecording()
    }
    
}

extension ViewController {
    private func initMapView() {
        mapView = MAMapView(frame: view.bounds)
        mapView.delegate = self
        mapView.mapType = .satellite
        mapView.isShowsLabels = false
        mapView.isRotateCameraEnabled = true
        
        // 默认设置13.7 则可以设置为和佳速度差不多的样子
        mapView.zoomLevel = 13.7
        view.addSubview(mapView)
        
    }
    
    private func initData() {
        s_coords = [CLLocationCoordinate2D(latitude: 39.97617053371078, longitude: 116.3499049793749),
                    CLLocationCoordinate2D(latitude: 39.97619854213431, longitude: 116.34978804908442),
                    CLLocationCoordinate2D(latitude: 39.97623045687959, longitude: 116.349674596623),
                    CLLocationCoordinate2D(latitude: 39.97626931100656, longitude: 116.34955525200917),
                    CLLocationCoordinate2D(latitude: 39.976285626595036, longitude: 116.34943728748914),
                    CLLocationCoordinate2D(latitude: 39.97628129172198, longitude: 116.34930864705592),
        
                    CLLocationCoordinate2D(latitude: 39.976260803938594, longitude: 116.34918981582413),
                    CLLocationCoordinate2D(latitude: 39.97623535890678, longitude: 116.34906721558868),
                    CLLocationCoordinate2D(latitude: 39.976214717128855, longitude: 116.34895185151584),
                    CLLocationCoordinate2D(latitude: 39.976280148755315, longitude: 116.34886935936889),
                    CLLocationCoordinate2D(latitude: 39.97628182112874, longitude: 116.34873954611332),
                    
                    CLLocationCoordinate2D(latitude: 39.97626038855863, longitude: 116.34860763527448),
                    CLLocationCoordinate2D(latitude: 39.976306080391836, longitude: 116.3484658907622),
                    CLLocationCoordinate2D(latitude: 39.976358252119745, longitude: 116.34834585430347),
                    CLLocationCoordinate2D(latitude: 39.97645709321835, longitude: 116.34831166130878),
                    CLLocationCoordinate2D(latitude: 39.97655231226543, longitude: 116.34827643560175),
                    
                    CLLocationCoordinate2D(latitude: 39.976658372925556, longitude: 116.34824186261169),
                    CLLocationCoordinate2D(latitude: 39.9767570732376, longitude: 116.34825080406188),
                    CLLocationCoordinate2D(latitude: 39.976869087779995, longitude: 116.34825631960626),
                    CLLocationCoordinate2D(latitude: 39.97698451764595, longitude: 116.34822111635201),
                    CLLocationCoordinate2D(latitude: 39.977079745909876, longitude: 116.34822901510276),
                    
                    CLLocationCoordinate2D(latitude: 39.97718701787645, longitude: 116.34822234337618),
                    CLLocationCoordinate2D(latitude: 39.97730766147824, longitude: 116.34821627457707),
                    CLLocationCoordinate2D(latitude: 39.977417746816776, longitude: 116.34820593515043),
                    CLLocationCoordinate2D(latitude: 39.97753930933358, longitude: 116.34821013897107),
                    CLLocationCoordinate2D(latitude: 39.977652209132174, longitude: 116.34821304891533),
                    
                    CLLocationCoordinate2D(latitude: 39.977764016531076, longitude: 116.34820923399242),
                    CLLocationCoordinate2D(latitude: 39.97786190186833, longitude: 116.3482045955917),
                    CLLocationCoordinate2D(latitude: 39.977958856930286, longitude: 116.34822159449203),
                    CLLocationCoordinate2D(latitude: 39.97807288885813, longitude: 116.3482256370537),
                    CLLocationCoordinate2D(latitude: 39.978170063673524, longitude: 116.3482098441266),
                    
                    CLLocationCoordinate2D(latitude: 39.978266951404066, longitude: 116.34819564465377),
                    CLLocationCoordinate2D(latitude: 39.978380693859116, longitude: 116.34820541974412),
                    CLLocationCoordinate2D(latitude: 39.97848741209275, longitude: 116.34819672351216),
                    CLLocationCoordinate2D(latitude: 39.978593409607825, longitude: 116.34816588867105),
                    CLLocationCoordinate2D(latitude: 39.97870216883567, longitude: 116.34818489339459),
                    
                    CLLocationCoordinate2D(latitude: 39.978797222300166, longitude: 116.34818473446943),
                    CLLocationCoordinate2D(latitude: 39.978893492422685, longitude: 116.34817728972234),
                    CLLocationCoordinate2D(latitude: 39.978997133775266, longitude: 116.34816491505472),
                    CLLocationCoordinate2D(latitude: 39.97911413849568, longitude: 116.34815408537773),
                    CLLocationCoordinate2D(latitude: 39.97920553614499, longitude: 116.34812908154862),
                    
                    CLLocationCoordinate2D(latitude: 39.979308267469264, longitude: 116.34809495907906),
                    CLLocationCoordinate2D(latitude: 39.97939658036473, longitude: 116.34805113358091),
                    CLLocationCoordinate2D(latitude: 39.979491697188685, longitude: 116.3480310509613),
                    CLLocationCoordinate2D(latitude: 39.979588529006875, longitude: 116.3480082124968),
                    CLLocationCoordinate2D(latitude: 39.979685789111635, longitude: 116.34799530586834),
                    
                    CLLocationCoordinate2D(latitude: 39.979801430587926, longitude: 116.34798818413954),
                    CLLocationCoordinate2D(latitude: 39.97990758587515, longitude: 116.3479996420353),
                    CLLocationCoordinate2D(latitude: 39.980000796262615, longitude: 116.34798697544538),
                    CLLocationCoordinate2D(latitude: 39.980116318796085, longitude: 116.3479912988137),
                    CLLocationCoordinate2D(latitude: 39.98021407403913, longitude: 116.34799204219203),
                    
                    CLLocationCoordinate2D(latitude: 39.980325006125696, longitude: 116.34798535084123),
                    CLLocationCoordinate2D(latitude: 39.98042511477518, longitude: 116.34797702460183),
                    CLLocationCoordinate2D(latitude: 39.98054129336908, longitude: 116.34796288754136),
                    CLLocationCoordinate2D(latitude: 39.980656820423505, longitude: 116.34797509821901),
                    CLLocationCoordinate2D(latitude: 39.98074576792626, longitude: 116.34793922017285),
                    
                    CLLocationCoordinate2D(latitude: 39.98085620772756, longitude: 116.34792586413015),
                    CLLocationCoordinate2D(latitude: 39.98098214824056, longitude: 116.3478962642899),
                    CLLocationCoordinate2D(latitude: 39.98108306010269, longitude: 116.34782449883967),
                    CLLocationCoordinate2D(latitude: 39.98115277119176, longitude: 116.34774758827285),
                    CLLocationCoordinate2D(latitude: 39.98115430642997, longitude: 116.34761476652932),
                    
                    CLLocationCoordinate2D(latitude: 39.98114590845294, longitude: 116.34749135408349),
                    CLLocationCoordinate2D(latitude: 39.98114337322547, longitude: 116.34734772765582),
                    CLLocationCoordinate2D(latitude: 39.98115066909245, longitude: 116.34722082902628),
                    CLLocationCoordinate2D(latitude: 39.98114532232906, longitude: 116.34708205250223),
                    CLLocationCoordinate2D(latitude: 39.98112245161927, longitude: 116.346963237696),
                    
                    CLLocationCoordinate2D(latitude: 39.981136637759604, longitude: 116.34681500222743),
                    CLLocationCoordinate2D(latitude: 39.981146248090866, longitude: 116.34669622104072),
                    CLLocationCoordinate2D(latitude: 39.98112495260716, longitude: 116.34658043260109),
                    CLLocationCoordinate2D(latitude: 39.9811107163792, longitude: 116.34643721418927),
                    CLLocationCoordinate2D(latitude: 39.981085081075676, longitude: 116.34631638374302),
                    
                    CLLocationCoordinate2D(latitude: 39.98108046779486, longitude: 116.34614782996252),
                    CLLocationCoordinate2D(latitude: 39.981049089345206, longitude: 116.3460256053666),
                    CLLocationCoordinate2D(latitude: 39.98104839362087, longitude: 116.34588814050122),
                    CLLocationCoordinate2D(latitude: 39.9810544889668, longitude: 116.34575119741586),
                    CLLocationCoordinate2D(latitude: 39.981040940565734, longitude: 116.34562885420186),
                    
                    CLLocationCoordinate2D(latitude: 39.98105271658809, longitude: 116.34549232235582),
                    CLLocationCoordinate2D(latitude: 39.981052294975264, longitude: 116.34537348820508),
                    CLLocationCoordinate2D(latitude: 39.980956549928244, longitude: 116.3453513775533),
                    
        ]
        
        var sum: Double = 0
        var arr = [Double]() /* capacity: count */
        let count: Int = s_coords.count
        for i in 0..<count - 1 {
            let begin = CLLocation(latitude: s_coords[i].latitude, longitude: s_coords[i].longitude)
            let end = CLLocation(latitude: s_coords[i + 1].latitude, longitude: s_coords[i + 1].longitude)
            let distance: CLLocationDistance = end.distance(from: begin)
            arr.append(Double(distance))
            sum += distance
        }
        
        self.distanceArray = arr
        self.sumDistance = sum
    }
    
    private func initRoute() {
        let count: Int = s_coords.count
//        self.fullTraceLine = MAPolyline(coordinates: &s_coords, count: UInt(count))
//        self.mapView.add(self.fullTraceLine)
        var routeAnno = [Any]()
        for i in 0..<count {
            if (i == 0 || i == count - 1) {
                let a = MAPointAnnotation()
                a.coordinate = s_coords[i]
                a.title = "route"
                routeAnno.append(a)
            }
        }
        self.mapView.addAnnotations(routeAnno)
        self.mapView.showAnnotations(routeAnno, animated: false)
        self.mapView.setZoomLevel(14, animated: true)
        
//        self.mapView.setCenter(s_coords[0], animated: true)
        
//        self.car1 = MAAnimatedAnnotation()
//        self.car1.title = "Car1"
//        self.mapView.addAnnotation(self.car1)
        
        weak var weakSelf = self
        self.car1 = CustomMovingAnnotation()
        self.car1.stepCallback = {() -> Void in
            weakSelf?.updatePassedTrace()
        }
        self.car1.title = "Car2"
        self.mapView.addAnnotation(self.car1)
        self.car1.coordinate = s_coords[0]
//        self.car2.coordinate = s_coords[0]
    }
    
    func updatePassedTrace() {
        if self.car1.isAnimationFinished() {
            return
        }
        if (self.passedTraceLine != nil) {
            self.mapView.remove(self.passedTraceLine)
        }
        let needCount: Int = self.passedTraceCoordIndex + 2
        
        let buffer = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: needCount)
        for i in 0..<self.passedTraceCoordIndex + 1 {
            buffer[i] = s_coords[i]
        }
        buffer[needCount - 1] = self.car1.coordinate
        
        self.passedTraceLine = MAPolyline.init(coordinates: buffer, count:UInt(needCount))
        self.mapView.add(self.passedTraceLine)
       
//        buffer.deallocate(capacity: needCount)
        buffer.deallocate()
    }
    
    @objc func mov() {
        let speed_car1: Double = 120.0 / 3.6
        //80 km/h
        let count: Int = s_coords.count
//        self.car1.coordinate = s_coords[0]
//        let duration = self.sumDistance / speed_car1;
//        self.car1.addMoveAnimation(withKeyCoordinates: &s_coords, count: UInt(count), withDuration: CGFloat(duration), withName: nil, completeCallback: {(_ isFinished: Bool) -> Void in
//        })
        
        //小车2走过的轨迹置灰色, 采用添加多个动画方法
        let speed_car2: Double = 700.0 / 3.6
        //60 km/h
        weak var weakSelf = self
        self.car1.coordinate = s_coords[0]
        self.passedTraceCoordIndex = 0
        for i in 1..<count {
            let num = self.distanceArray[i - 1]
            let tempDuration = num / speed_car2
            self.car1.addMoveAnimation(withKeyCoordinates: &(s_coords[i]), count: 1, withDuration: CGFloat(tempDuration), withName: nil, completeCallback: {(_ isFinished: Bool) -> Void in
                weakSelf?.passedTraceCoordIndex = i
            })
        }
        
//        startCapture()
        
//        let outputPath = "\(NSTemporaryDirectory())output.mov"
//        let outputFileUrl = URL(fileURLWithPath: outputPath)
//        self.recorder = ViewRecorder(viewToRecord: self.mapView)
//        self.recorder.startRecording(to: "\(NSTemporaryDirectory())output.mov", size: self.mapView.bounds.size) { error in
//            if let error = error {
//                print("Error starting recording: \(error)")
//            } else {
//                print("Recording started")
//            }
//        }
    }
}

extension ViewController: MAMapViewDelegate {
    func mapInitComplete(_ mapView: MAMapView!) {
        initRoute()
    }
    
    func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
        if (annotation.isEqual(self.car1)) {
            let pointReuseIndetifier: String = "pointReuseIndetifier2"
            var annotationView: MAAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: pointReuseIndetifier)
            if annotationView == nil {
                annotationView = MAAnnotationView(annotation: annotation, reuseIdentifier: pointReuseIndetifier)
                annotationView?.canShowCallout = true
//                let imge = UIImage(named: "userPosition")
                let imge = UIImage(named: "trackingPoints")
                annotationView?.image = imge
                self.car1View = annotationView
            }
            return annotationView!
        } else if (annotation is MAPointAnnotation) {
            let pointReuseIndetifier: String = "pointReuseIndetifier3"
            var annotationView: MAAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: pointReuseIndetifier)
            if annotationView == nil {
                annotationView = MAAnnotationView(annotation: annotation, reuseIdentifier: pointReuseIndetifier)
                annotationView?.canShowCallout = true
            }
            if (annotation.title == "route") {
                annotationView?.isEnabled = false
                annotationView?.image = UIImage(named: "trackingPoints")
            }
            
//            self.car1View?.superview?.bringSubview(toFront: self.car1View!)
            self.car1View?.superview?.bringSubviewToFront(self.car1View!)
            return annotationView
        }
        return nil
    }
    
    func mapView(_ mapView: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
//        if (overlay as! MAPolyline == self.fullTraceLine) {
//            let polylineView = MAPolylineRenderer(polyline: overlay as! MAPolyline!)
//            polylineView?.lineWidth = 6.0
//            polylineView?.strokeColor = UIColor(red: CGFloat(0), green: CGFloat(0.47), blue: CGFloat(1.0), alpha: CGFloat(0.9))
//            return polylineView
//        } else
        if (overlay as! MAPolyline == self.passedTraceLine) {
            let polylineView = MAPolylineRenderer(polyline: overlay as? MAPolyline)
            polylineView?.lineWidth = 14.0
            polylineView?.strokeColor = UIColor.blue
            return polylineView
        }
        
        return nil
    }
}




typealias CustomMovingAnnotationCallback = () -> Void

class CustomMovingAnnotation: MAAnimatedAnnotation {
    var stepCallback : CustomMovingAnnotationCallback = {}
    
    override func step(_ timeDelta: CGFloat) {
        super.step(timeDelta)
        self.stepCallback()
    }
    
    override func rotateDegree() -> CLLocationDirection {
        return 0
    }
}
