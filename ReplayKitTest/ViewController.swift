//
//  ViewController.swift
//  ReplayKitTest
//
//  Created by 袁量 on 2024/8/9.
//

import UIKit

class ViewController: UIViewController {
    let recorder = ScreenRecorder()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
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

