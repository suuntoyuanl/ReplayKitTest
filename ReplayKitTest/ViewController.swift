//
//  ViewController.swift
//  ReplayKitTest
//
//  Created by 袁量 on 2024/8/9.
//

import UIKit
import AMapFoundationKit

class ViewController: UIViewController {
    var mapView: MAMapView!
    let recorder = ScreenRecorder()
    override func viewDidLoad() {
        super.viewDidLoad()
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
        
        mapView.mapType = .satellite
        mapView.isRotateCameraEnabled = true
        
        // 默认设置13.7 则可以设置为和佳速度差不多的样子
        mapView.zoomLevel = 13.7
        view.addSubview(mapView)
        
    }
}

