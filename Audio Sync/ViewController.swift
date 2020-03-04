//
//  ViewController.swift
//  Audio Sync
//
//  Created by Eric Dolecki on 3/3/20.
//  Copyright © 2020 Eric Dolecki. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{
    var av: AVAudioEnginePlayback!
    
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var one: UIButton!
    @IBOutlet weak var two: UIButton!
    @IBOutlet weak var three: UIButton!
    @IBOutlet weak var four: UIButton!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        av = AVAudioEnginePlayback()
        av.startPlaying()
        av.requestTrackStartPlaying(index: 2)
        
        // Starts at -1, present even after requesting audio.
        
        print("Active index: \(av.activeIndex)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            
            //After fading, it's set.
            
            print("Active index: \(self.av.activeIndex)")
        }
        
        let w = container.bounds.width / 5
        one.center = CGPoint(x: w, y: one.center.y)
        two.center = CGPoint(x: w * 2, y: two.center.y)
        three.center = CGPoint(x: w * 3, y: three.center.y)
        four.center = CGPoint(x: w * 4, y: four.center.y)
    }
    
    @IBAction func requestTrack(who: UIButton) {
        print(who.tag)
        av.requestTrackStartPlaying(index: who.tag)
    }
    
    @IBAction func stopAll() {
        av.killEmAll()
    }
}
