//
//  SettingsViewController.swift
//  WorldTracking
//
//  Created by Skybtotica AR on 3/26/18.
//  Copyright © 2018 Skybotica. All rights reserved.
//

import UIKit

// ### GUI Controller ###
var guiControllerSettings : GUIController = GUIController.sharedInstance

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var voiceSlider: UISlider!
    @IBOutlet weak var musicSlider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        musicSlider.value = guiControllerSettings.configuration.musicVolume
        voiceSlider.value = guiControllerSettings.configuration.voiceVolume
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func optionsBack(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func optionsResetPlane(_ sender: Any) {
        guiControllerSettings.mainViewController!.ResetExplotion()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func optionsResetVirtualLegacy(_ sender: Any) {
        guiControllerSettings.mainViewController!.ResetVirtualLegacy()
        dismiss(animated: true, completion: nil)
    }
    
    
    //###############VOLUME BUTTONS################
    
    @IBAction func voiceVolume(_ sender: Any) {
        //performSegue(withIdentifier: "volume", sender: self)
        guiControllerSettings.configuration.voiceVolume = voiceSlider.value
        guiControllerSettings.mainViewController!.SetVolumes()
    }
    @IBAction func musicVolume(_ sender: Any) {
        //performSegue(withIdentifier: "volume", sender: self)
        guiControllerSettings.configuration.musicVolume = musicSlider.value
        guiControllerSettings.mainViewController!.SetVolumes()
    }

}
