//
//  GUIController.swift
//  WorldTracking
//
//  Created by skybotica on 4/6/18.
//  Copyright © 2018 Skybotica. All rights reserved.
//

import Foundation
import UIKit

struct VirtualLegacyConfiguration{
    var voiceVolume : Float
    var musicVolume : Float
}

class GUIController {
    var configuration : VirtualLegacyConfiguration
    var mainViewController : ViewController?
    // ### ToastStyle ###
    var toastStyleInstruction = ToastStyle()
    var toastStyleNotification = ToastStyle()
    var infiniteTime : TimeInterval = 1000000
    
    static let sharedInstance =  GUIController()
    
    init(){
        configuration = VirtualLegacyConfiguration(
            voiceVolume: 1.0, musicVolume: 0.7
        )
        mainViewController = nil
        
        // Setup toast style instruction
        toastStyleInstruction.messageColor = UIColor.white
        toastStyleInstruction.messageAlignment = .center
        let color = UIColor.init(patternImage: UIImage(named: "paperBackground")!).withAlphaComponent(0.7)
        toastStyleInstruction.backgroundColor = color
        toastStyleInstruction.horizontalPadding = 20.0
        toastStyleInstruction.verticalPadding = 20.0
        toastStyleInstruction.messageFont = UIFont.systemFont(ofSize: 25.0, weight: UIFont.Weight.thin)
        // Setup toast style normal
        toastStyleNotification.messageColor = UIColor.white
        toastStyleNotification.messageAlignment = .center
        toastStyleNotification.backgroundColor = color
        toastStyleNotification.horizontalPadding = 10.0
        toastStyleNotification.verticalPadding = 10.0
        toastStyleNotification.messageFont = UIFont.systemFont(ofSize: 18.0, weight: UIFont.Weight.thin)
    }
}
