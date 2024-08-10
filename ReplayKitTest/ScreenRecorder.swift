import Foundation
import ReplayKit
import AVFoundation
 
class ScreenRecorder {
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private let screenRecorder = RPScreenRecorder.shared()
    private var isRecording = false
    private var sessionStarted = false
    
    var statusUpdate: ((String) -> Void)?
    var savePathUpdate: ((URL) -> Void)?
    
    // 设置视频文件写入器
    private func setupWriter(fileName: String) -> Bool {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(fileName)
        do {
            assetWriter = try AVAssetWriter(outputURL: fileURL, fileType: .mp4)
            let outputSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: UIScreen.main.bounds.width,
                AVVideoHeightKey: UIScreen.main.bounds.height
            ]
            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
            if assetWriter!.canAdd(videoInput!) {
                assetWriter!.add(videoInput!)
            }
        } catch {
            // rebase test
            statusUpdate?("设置视频写入器失败: \(error)")
            return false
        }
        return true
    }
    
    // 开始录制
    func startRecording(withFileName fileName: String) {
        guard !isRecording else {
            statusUpdate?("录制已经在进行中。")
            return
        }
        guard RPScreenRecorder.shared().isAvailable else {
            statusUpdate?("屏幕录制不可用。")
            return
        }
        if !setupWriter(fileName: fileName) {
            return
        }
        
        assetWriter?.startWriting()
        screenRecorder.startCapture { [weak self] (sampleBuffer, bufferType, error) in
            guard let self = self else { return }
            if let error = error {
                
                self.statusUpdate?("捕捉过程中发生错误: \(error)")
                
                return
            }
            if bufferType == .video {
                DispatchQueue.main.async {
                    self.handleSampleBuffer(sampleBuffer)
                }
            }
        } completionHandler: { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                print("开始捕捉失败: \(error)")
                self.statusUpdate?("开始捕捉失败: \(error)")
                
            } else {
                
                self.isRecording = true
                print("录制已开始")
                self.statusUpdate?("录制已开始。")
                
            }
        }
    }
    
    // 处理视频样本
    private func handleSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard CMSampleBufferGetPresentationTimeStamp(sampleBuffer).isValid,
              let videoInput = videoInput, videoInput.isReadyForMoreMediaData else {
            return
        }
        
        if !sessionStarted {
            assetWriter?.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
            sessionStarted = true
        }
        
        videoInput.append(sampleBuffer)
    }
    
    // 停止录制
    func stopRecording() {
        guard isRecording else {
            statusUpdate?("当前没有进行中的录制。")
            return
        }
        
        screenRecorder.stopCapture { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                
                self.statusUpdate?("停止捕捉失败: \(error)")
                
                return
            }
            
            self.videoInput?.markAsFinished()
            self.assetWriter?.finishWriting {
                
                if self.assetWriter?.status == .completed {
                    self.statusUpdate?("录制已停止。")
                    if let url = self.assetWriter?.outputURL {
                        print("保存成功\(url)")
                        self.savePathUpdate?(url)
                    } else {
                        self.statusUpdate?("无法获取录制文件的URL。")
                    }
                } else {
                    print("录屏文件保存失败: \(self.assetWriter?.error?.localizedDescription ?? "未知错误")")
                }
                
                
                
                self.cleanup()
            }
        }
    }
    
    // 清理资源
    private func cleanup() {
        isRecording = false
        sessionStarted = false
        assetWriter = nil
        videoInput = nil
    }
    
 
}
