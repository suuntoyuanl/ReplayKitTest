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
    
    var btn: UIButton!
    var isPlay = false
    
    let music = "http://music.163.com/song/media/outer/url?id=1817576399.mp3"
    
    let recorder = ScreenRecorder()
    override func viewDidLoad() {
        super.viewDidLoad()
        initData()
        initMapView()
        btn = UIButton(frame: CGRect(x: 10, y: 100, width: 80, height: 40))
        view.addSubview(btn)
        btn.backgroundColor = .white
        btn.setTitle("调试", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.addTarget(self, action: #selector(debug), for: .touchUpInside)
        
//        playAudio()
        recorder.statusUpdate = { status in
            print("状态变化: \(status)")
            if status == "录制已开始。" {
                self.startMove()
            }
        }
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        print(documentsURL.absoluteString)
        // Do any additional setup after loading the view.
    }
    
    private func playAudio() {
        // http://music.163.com/song/media/outer/url?id=1817576399.mp3
        AudioPlayer.shared.loadOnlineAudioFile(urlString: music) { success in
            if success {
                AudioPlayer.shared.play()
            } else {
                print("faild to load online audio file")
            }
        }
    }
    
    private func startMove() {
        mapView.setZoomLevel(15.3, animated: true)
        mov()
        playAudio()
        isPlay = !isPlay
    }
    
    @objc private func debug() {
        if !isPlay {
            recorder.startRecording(withFileName: "\(Date().timeIntervalSince1970).mp4")
        } else {
            isPlay = !isPlay
            AudioPlayer.shared.stop()
            recorder.stopRecording { videoURL in
                if let videoURL = videoURL {
                    self.recorder.mergeOnlineAudio(videoURL: videoURL, audioURLString: self.music) { finalURL in
                        if let finalURL = finalURL {
                            print("视频合成成功: \(finalURL)")
                            self.recorder.saveVideoToPhotoLibrary(videoURL: finalURL) { success, error in
                                if success {
                                        print("视频成功保存到相册。")
                                    } else if let error = error {
                                        print("保存视频到相册失败: \(error.localizedDescription)")
                                    }
                            }
                        } else {
                            print("视频合成失败")
                        }
                    }
                }
            }
        }
        print("")
        
    }
    @IBAction func random(_ sender: Any) {
    }
    
    @IBAction func start(_ sender: Any) {
//        let outputPath = "\(NSTemporaryDirectory())output.mov"
        recorder.startRecording(withFileName: "12313测试.mp4")
    }
    @IBAction func end(_ sender: Any) {
//        recorder.stopRecording()
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
        s_coords = gpxPoint
        
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
            polylineView?.lineWidth = 9.0
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
