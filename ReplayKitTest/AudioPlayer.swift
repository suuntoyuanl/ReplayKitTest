//
//  AudioPlayer.swift
//  ReplayKitTest
//
//  Created by 袁量 on 2024/8/10.
//

import AVFoundation

class AudioPlayer {

    static let shared = AudioPlayer()  // 单例实例

    private var audioPlayer: AVAudioPlayer?
    private var audioDataTask: URLSessionDataTask?

    private init() {}  // 私有化初始化，确保单例模式

    // 加载本地音频文件
    func loadLocalAudioFile(fileName: String, fileType: String) -> Bool {
        if let path = Bundle.main.path(forResource: fileName, ofType: fileType) {
            let url = URL(fileURLWithPath: path)
            return loadAudioFromURL(url: url)
        }
        return false
    }

    // 加载在线音频文件
    func loadOnlineAudioFile(urlString: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }

        audioDataTask?.cancel()
        audioDataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, error == nil {
                self.audioPlayer = try? AVAudioPlayer(data: data)
                self.audioPlayer?.prepareToPlay()
                completion(self.audioPlayer != nil)
            } else {
                completion(false)
            }
        }
        audioDataTask?.resume()
    }

    // 播放音频
    func play() {
        audioPlayer?.play()
    }

    // 暂停音频
    func pause() {
        audioPlayer?.pause()
    }

    // 停止音频
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
    }

    // 设置音量
    func setVolume(_ volume: Float) {
        audioPlayer?.volume = volume
    }

    // 获取当前播放时间
    func currentTime() -> TimeInterval? {
        return audioPlayer?.currentTime
    }

    // 获取音频时长
    func duration() -> TimeInterval? {
        return audioPlayer?.duration
    }

    // 设置循环播放
    func setLooping(_ isLooping: Bool) {
        audioPlayer?.numberOfLoops = isLooping ? -1 : 0
    }

    // 从 URL 加载音频文件
    private func loadAudioFromURL(url: URL) -> Bool {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            return true
        } catch {
            print("Audio player error: \(error.localizedDescription)")
            return false
        }
    }
}
