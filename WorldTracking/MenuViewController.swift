//
//  MenuViewController.swift
//  WorldTracking
//
//  Created by Skybtotica AR on 3/26/18.
//  Copyright © 2018 Skybotica. All rights reserved.
//

import UIKit

// ### GUI Controller ###
var guiControllerMenu : GUIController = GUIController.sharedInstance

class MenuViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        //conventosButton.isEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if(guiControllerMenu.mainViewController == nil){return}
        if(guiControllerMenu.mainViewController!.apMusic.isPlaying){
           guiControllerMenu.mainViewController!.apMusic.pause()
        }
        if(guiControllerMenu.mainViewController!.apVoice.isPlaying){
            guiControllerMenu.mainViewController!.apVoice.pause()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func viewForward(_ sender: Any) {
        var added = false
        if let viewControllers = self.navigationController?.viewControllers{
            for controller in viewControllers{
                if controller is ViewController{
                    print("Found view controller")
                    // viewControllers.remove(at: viewControllers.index(of: controller)!)
                    self.navigationController?.pushViewController(controller, animated: true)
                    added = true
                }
            }
        }
        if(!added){
            // Load spinner
            self.view.makeToastActivity(.center)
            
            print("adding manually")
            
            Timer.scheduledTimer(timeInterval: TimeInterval(0.1), target: self, selector: #selector(self.waitForLoad), userInfo: nil, repeats: false)
        }
    }
    
    @objc func waitForLoad(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "MuralesViewController") as! ViewController
        self.present(viewController, animated: true, completion: {
            self.view.hideToastActivity()
        })
        
    }
    
    @IBOutlet weak var conventosButton: UIButton!
    

}
