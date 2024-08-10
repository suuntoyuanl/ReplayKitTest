import Foundation
import ReplayKit
import AVFoundation
import Photos

import AVFoundation
import ReplayKit
import Photos

class ScreenRecorder {
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private let screenRecorder = RPScreenRecorder.shared()
    private var isRecording = false
    private var sessionStarted = false
    
    var statusUpdate: ((String) -> Void)?
    var savePathUpdate: ((URL) -> Void)?
    
    private func setupWriter(fileName: String) -> Bool {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(fileName)
        do {
            assetWriter = try AVAssetWriter(outputURL: fileURL, fileType: .mp4)
            
            // 设置 HEVC 编码器
            let outputSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.hevc,
                AVVideoWidthKey: UIScreen.main.nativeBounds.width,
                AVVideoHeightKey: UIScreen.main.nativeBounds.height
            ]
            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
            videoInput?.expectsMediaDataInRealTime = true
            
            if assetWriter!.canAdd(videoInput!) {
                assetWriter!.add(videoInput!)
            }
        } catch {
            statusUpdate?("设置视频写入器失败: \(error)")
            return false
        }
        return true
    }
    
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
    
    func stopRecording(completion: @escaping (URL?) -> Void) {
        guard isRecording else {
            statusUpdate?("当前没有进行中的录制。")
            completion(nil)
            return
        }
        
        screenRecorder.stopCapture { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                self.statusUpdate?("停止捕捉失败: \(error)")
                completion(nil)
                return
            }
            
            self.videoInput?.markAsFinished()
            self.assetWriter?.finishWriting {
                if self.assetWriter?.status == .completed {
                    self.statusUpdate?("录制已停止。")
                    if let url = self.assetWriter?.outputURL {
                        print("保存成功 \(url)")
                        self.savePathUpdate?(url)
                        completion(url)
                    } else {
                        self.statusUpdate?("无法获取录制文件的URL。")
                        completion(nil)
                    }
                } else {
                    print("录屏文件保存失败: \(self.assetWriter?.error?.localizedDescription ?? "未知错误")")
                    completion(nil)
                }
                self.cleanup()
            }
        }
    }
    
    private func cleanup() {
        isRecording = false
        sessionStarted = false
        assetWriter = nil
        videoInput = nil
    }
    
    // 合成音频和视频
    func mergeAudio(with videoURL: URL, audioURL: URL, audioVolume: Float, completion: @escaping (URL?) -> Void) {
        let composition = AVMutableComposition()
        let videoAsset = AVAsset(url: videoURL)
        let audioAsset = AVAsset(url: audioURL)
        
        // Video Track
        guard let videoAssetTrack = videoAsset.tracks(withMediaType: .video).first else {
            completion(nil)
            return
        }
        let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            try videoCompositionTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: videoAsset.duration), of: videoAssetTrack, at: .zero)
        } catch {
            completion(nil)
            return
        }
        
        // Audio Track
        guard let audioAssetTrack = audioAsset.tracks(withMediaType: .audio).first else {
            completion(nil)
            return
        }
        let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            try audioCompositionTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: videoAsset.duration), of: audioAssetTrack, at: .zero)
        } catch {
            completion(nil)
            return
        }
        
        // Set audio volume
        let audioMix = AVMutableAudioMix()
        let audioMixInputParams = AVMutableAudioMixInputParameters(track: audioCompositionTrack)
        audioMixInputParams.setVolume(audioVolume, at: .zero)
        audioMix.inputParameters = [audioMixInputParams]
        
        // Exporting the composition
        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.audioMix = audioMix  // Set the audio mix
        let exportURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(Date().timeIntervalSince1970).mp4")
        exportSession?.outputURL = exportURL
        exportSession?.outputFileType = .mp4
        
        exportSession?.exportAsynchronously {
            switch exportSession?.status {
            case .completed:
                completion(exportURL)
            case .failed:
                print("Export failed: \(exportSession?.error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            case .cancelled:
                print("Export cancelled")
                completion(nil)
            default:
                completion(nil)
            }
        }
    }
    
    // 合成本地音频
    func mergeLocalAudio(videoURL: URL, audioFileName: String, audioFileType: String, completion: @escaping (URL?) -> Void) {
        if let audioURL = Bundle.main.url(forResource: audioFileName, withExtension: audioFileType) {
            mergeAudio(with: videoURL, audioURL: audioURL, audioVolume: 0.1, completion: completion)
        } else {
            completion(nil)
        }
    }
    
    // 合成在线音频
    func mergeOnlineAudio(videoURL: URL, audioURLString: String, completion: @escaping (URL?) -> Void) {
        guard let audioURL = URL(string: audioURLString) else {
            completion(nil)
            return
        }
        mergeAudio(with: videoURL, audioURL: audioURL, audioVolume: 0.1, completion: completion)
    }
    
    func saveVideoToPhotoLibrary(videoURL: URL, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                DispatchQueue.main.async {
                    completion(false, NSError(domain: "PhotoLibraryErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "没有相册权限。"]))
                }
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .video, fileURL: videoURL, options: nil)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        completion(true, nil)
                    } else {
                        completion(false, error)
                    }
                }
            }
        }
    }
}
