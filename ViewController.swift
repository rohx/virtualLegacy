//
//  ViewController.swift
//  VirtualLegacy
//
//  Created by skybotica on 3/7/18.
//  Copyright © 2018 Skybotica. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {
    var index : Int = 0
    var modelNames = ["MLCDE","LCDE_1","LCDE_2","LCDE_3","LCDE_4","LCDE_5","LCDE_6","LCDE_7"]
    var modelNodes = [SCNNode()]
    let configuration = ARWorldTrackingConfiguration()
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.debugOptions = [ ARSCNDebugOptions.showWorldOrigin ]
        self.sceneView.session.run(configuration )
        // Load model nodes
        LoadNodes()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /**
     Get node from scn file with the parameter name
     - parameters:
     - folderName: Name of the folder containing the scn files
     - fileName: Name of the scn file
     - nodeName: Name of the node inside the scn file
     - recursively: To search for the node recursively or not
     - returns:
     SCNNode of the loaded node
     */
    func LoadModel(folderName: String, fileName: String, nodeName: String, recursively: Bool) -> SCNNode?{
        let scenePath = folderName + "/" + fileName + ".scn"
        let rectoriaScene = SCNScene(named:scenePath)
        return rectoriaScene?.rootNode.childNode(withName: nodeName, recursively: recursively)
    }
    
    func LoadNodes(){
        // Prepare and load models for scene
        for modelName in modelNames{
            let node = LoadModel(folderName: "art.scnassets", fileName: modelName, nodeName: modelName, recursively: false);
            // If not found
            if node == nil{
                return
            }
            modelNodes.append(node!)
        }
    }
    
    /**
     Adds next model node to the scene with an animation
     */
    @IBAction func addNode(_ sender: Any) {
        if(index < modelNodes.count){
            let offset : Double = Double(index)*0.1
            modelNodes[index].runAction(SCNAction.move(by: SCNVector3(0,0,Double(index)*0.05), duration: 0.4 + offset))
            self.sceneView.scene.rootNode.addChildNode(modelNodes[index])
            index += 1
        }
    }
}

