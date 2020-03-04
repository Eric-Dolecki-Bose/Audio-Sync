//
//  AVAudioEnginePlayback.swift
//  Audio Sync
//
//  Created by Eric Dolecki on 3/3/20.
//  Copyright © 2020 Eric Dolecki. All rights reserved.
//

import Foundation
import AVFoundation

class AVAudioEnginePlayback: NSObject {
    
    private var     audioEngine         = AVAudioEngine()
    private var     audioEnvironment    = AVAudioEnvironmentNode()
    private var     mixer               = AVAudioMixerNode()
    
    private var     playerA             = AVAudioPlayerNode()
    private var     playerB             = AVAudioPlayerNode()
    private var     playerC             = AVAudioPlayerNode()
    private var     playerD             = AVAudioPlayerNode()
    
    // For spatial audio with Frames, etc.
    
    private var     yawOffset: Double?
    
    // We can loop through all the nodes.
    
    var allTracks = [AVAudioPlayerNode]()
    var activeIndex: Int = -1
    var fadeoutTimer: Timer!
    
    override init() {
        super.init()
        setupAudioEngine()
    }
    
    func setupAudioEngine()
    {
        let avSession = AVAudioSession.sharedInstance()
        do {
            try avSession.setCategory(AVAudioSession.Category.playback)
        } catch let error as NSError {
            print(error.localizedDescription)
            return
        }
        do {
            try avSession.setActive(true)
        } catch let error as NSError {
            print(error.localizedDescription)
            return
        }
        
        // Configure the audio environment, initialize the listener to start at 0, facing front.
        
        audioEnvironment.listenerPosition  = AVAudioMake3DPoint(0, 0, 0)
        audioEnvironment.listenerAngularOrientation = AVAudioMake3DAngularOrientation(0.0, 0.0, 0.0)
        audioEngine.attach(audioEnvironment)
        
        // Configure the audio engine
        
        let hardwareSampleRate = audioEngine.outputNode.outputFormat(forBus: 0).sampleRate
        guard let audioFormat = AVAudioFormat(standardFormatWithSampleRate: hardwareSampleRate, channels: 2) else { return }
        audioEngine.connect(audioEnvironment, to: audioEngine.outputNode, format: audioFormat)
        
        audioEngine.attach(playerA)
        audioEngine.attach(playerB)
        audioEngine.attach(playerC)
        audioEngine.attach(playerD)
        
        do {
            try audioEngine.start()
        } catch {
            print(error.localizedDescription)
        }
        
        setupPlayer(player: playerA, audioFile: "A-no", ext: "aif")
        setupPlayer(player: playerB, audioFile: "B-no", ext: "aif")
        setupPlayer(player: playerC, audioFile: "C-no", ext: "aif")
        setupPlayer(player: playerD, audioFile: "D-no", ext: "aif")
        
        allTracks.append(playerA)
        allTracks.append(playerB)
        allTracks.append(playerC)
        allTracks.append(playerD)
        
        //startPlaying()
    }
    
    private func setupPlayer(player: AVAudioPlayerNode, audioFile: String, ext: String,
                             loop: Bool = true) {
        if let audioFileURL = Bundle.main.url(forResource: audioFile, withExtension: ext) {
            do {
                
                // Open the audio file
                let audioFile = try AVAudioFile(forReading: audioFileURL, commonFormat: AVAudioCommonFormat.pcmFormatFloat32, interleaved: false)
                
                // Loop the audio playback upon completion - reschedule the same file
                func loopCompletionHandler() {
                    player.scheduleFile(audioFile, at: nil, completionHandler: loopCompletionHandler)
                }
                
                audioEngine.connect(player, to: audioEnvironment, format: audioFile.processingFormat)
                
                // Schedule the file for playback, see 'scheduleBuffer' for sceduling indivdual AVAudioBuffer/AVAudioPCMBuffer
                
                player.scheduleFile(audioFile, at: nil, completionHandler: loop ? loopCompletionHandler : nil)
                player.volume = 0
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func startPlaying() {
        yawOffset = nil
        let startSampleTime = playerA.lastRenderTime?.sampleTime
        let startTime = AVAudioTime(sampleTime: startSampleTime!, atRate: Double(mixer.rate))
        playerA.play(at: startTime)
        playerB.play(at: startTime)
        playerC.play(at: startTime)
        playerD.play(at: startTime)
    }
    
    
    
    
    
    
    
    
    func requestTrackStartPlaying(index: Int) {
        if index < 0 || index > allTracks.count - 1 {
            print(#function, "out of range error.")
            return
        }
        self.fadeInAudioWithDuration(who: self.allTracks[index])
        for i in 0...self.allTracks.count - 1 {
            if i != index {
                self.fadeOutAudioWithDuration(index: index)
            }
        }
        // Allow operation above to complete.
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
            self.activeIndex = index
        })
    }
    
    // About 3 seconds total.
    func fadeInAudioWithDuration(who: AVAudioPlayerNode) {
        let timerInterval: Float = 0.03
        var vol = 0.0
        fadeoutTimer = Timer.scheduledTimer(withTimeInterval: Double(timerInterval), repeats: true, block: { timer in
            vol = vol + 0.0090
            who.volume = Float(vol)
            if vol >= 1.0 {
                timer.invalidate()
            }
        })
    }
    
    // Affect all BUT the indexed one. About 1 second.
    func fadeOutAudioWithDuration(index: Int) {
        let timerInterval: Float = 0.01
        var vol = 1.0
        fadeoutTimer = Timer.scheduledTimer(withTimeInterval: Double(timerInterval), repeats: true, block: { timer in
            vol = vol - 0.0090
            for i in 0...self.allTracks.count - 1 {
                if i != index {
                    if self.allTracks[i].volume != 0 {
                        self.allTracks[i].volume = Float(vol)
                    }
                }
            }
            if vol <= 0.0 {
                timer.invalidate()
            }
        })
    }

    func killEmAll() {
        print(#function)
        for i in 0...self.allTracks.count - 1 {
             self.fadeOutAudioWithDuration(index: i)
        }
        self.activeIndex = -1
    }
}

// ie. someValue.clapped(0...10)
extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

// ie. someValue.clapped(0...10)
extension Strideable where Stride: SignedInteger {
    func clamped(to limits: CountableClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}


extension AVAudioPlayerNode {
    func setVolume(_ v :Float, fadeDuration: Float) {
        self.volume = v
    }
}

extension AVAudioEnginePlayback: AudioPlaybackEngineProtocol
{
    func playChime() {
        //
    }
    
    func fadeEverythingBackUp() {
        //
    }
    
    func userIsStanding(bValue: Bool) {
        //
    }

    func fadeEverythingToZero() {
        activeIndex = -1
        for track in allTracks {
            track.volume = 0
        }
    }
    
    func actOnCurrentStepsPerMinute(spm: Double, targets: [CGFloat]) {
        if spm == 0 {
            fadeAllSongsDown()
            activeIndex = -1
            return
        }
        if spm < Double(targets[0]) {
            activeIndex = 0
        } else if spm < Double(targets[1]) {
            activeIndex = 1
        } else if spm < Double(targets[2]) {
            activeIndex = 2
        } else {
            activeIndex = 3
        }
        fadeSongUp(index: activeIndex)
    }
    
    func adjustTracksPlaybackRate(spm: Double, targetBPM: Double) {
        //
    }
    
    func currentTrack() -> String {
        if activeIndex == -1 {
            return "No Track"
        } else if activeIndex == 0 {
            return "Track A"
        } else if activeIndex == 1 {
            return "Track B"
        } else if activeIndex == 2 {
            return "Track C"
        } else if activeIndex == 3 {
            return "Track D"
        } else {
            return "No Track"
        }
    }
    
    func actOnCurrentStepsPerMinuteZero() {
        fadeAllSongsDown()
        activeIndex = -1
    }
    
    func playChime(distance: Double) {
        //
    }
    
    func getActiveIndex() -> Int {
        return activeIndex
    }
    
    func receivedGameRotation(yawIn: Double, pitchIn: Double, rollIn: Double) {
        //print("recevied game rotation data!")
        // rad -> deg
        func degrees(fromRadians radians: Double) -> Double {
          return radians * 180.0 / .pi
        }
        
        // If needed, use the current yaw as the offset so the sound direction is directly in front
        if yawOffset == nil {
          yawOffset = degrees(fromRadians: yawIn)
        }
        var yaw = Float(degrees(fromRadians: yawIn) - yawOffset!)
        
        // Wrap around whatever the offset could have done, to bring the angle back in range.
        while yaw < -180.0 {
          yaw += 360.0
        }
        
        while yaw > 180 {
          yaw -= 360
        }
        
        let pitch = Float(degrees(fromRadians: pitchIn))
        let roll = Float(degrees(fromRadians: rollIn))
        
        // Update the listerner position in space
        audioEnvironment.listenerAngularOrientation = AVAudioMake3DAngularOrientation(yaw, pitch, roll)
    }
    
    //Support methods
    func fadeAllSongsDown(time: Float = 1.5) {
        for track in allTracks {
            track.setVolume(0.0, fadeDuration: time)
        }
    }
    
    private func fadeSongUp(index: Int)
    {
        for i in 0..<allTracks.count {
            if i <= index {
                allTracks[i].setVolume(0.1, fadeDuration: 2.0)
            } else {
                allTracks[i].setVolume(0.0, fadeDuration: 1.5)
            }
        }
    }
}
