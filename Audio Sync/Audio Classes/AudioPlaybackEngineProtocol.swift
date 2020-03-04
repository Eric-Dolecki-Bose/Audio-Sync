//
//  AudioPlaybackEngineProtocol.swift
//  Cadence
//
//  Created by Christine  Hostage on 1/13/20.
//  Copyright © 2020 Eric Dolecki. All rights reserved.
//

import Foundation
import AVFoundation

protocol AudioPlaybackEngineProtocol: NSObject {
 
    func playChime()
    
    func fadeEverythingBackUp()
    
    func fadeEverythingToZero()
    
    func actOnCurrentStepsPerMinute(spm: Double, targets:[CGFloat])
    
    func adjustTracksPlaybackRate(spm: Double, targetBPM: Double)
    
    func currentTrack() -> String
    
    func actOnCurrentStepsPerMinuteZero()
    
    func playChime(distance: Double)
    
    func getActiveIndex() -> Int
    
    func userIsStanding(bValue: Bool)
    
    func receivedGameRotation(yawIn: Double, pitchIn: Double, rollIn: Double)
}
