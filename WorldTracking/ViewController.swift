//
//  ViewController.swift
//  WorldTracking
//
//  Created by skybotica on 2/2/18.
//  Copyright © 2018 Skybotica. All rights reserved.
//

import UIKit
import ARKit
import AVFoundation
import CoreLocation
import Foundation

struct ModelNode {
    var name : String
    var distance : Float
    var node : SCNNode?
    var visibility : Bool
    var bitMask : Int
    var originalPos : SCNVector3?
    var movedPos : SCNVector3?
    var transitioning : Bool
    var backDistance : Float
    var toggled : Bool
}

struct PhotoNode {
    var photoName : String
    var audioName : String
    var node : SCNNode
    var voiceNode : SCNNode
    var isPlaying : Bool
}

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate, AVAudioPlayerDelegate, CLLocationManagerDelegate {
    var toggle = true
    var planeImage = 0
    
    @IBOutlet weak var modelMessage: UILabel!
    @IBOutlet weak var toggleButton: UIButton!
    @IBOutlet weak var snapButton: UIButton!
    @IBOutlet weak var optionButton: UIButton!
    // MARK: Properties
    // ############################## Properties ##############################
    // ### Mural config ###
    var index : Int = 0
    var maxDistance = 0.75
    var maxSeconds = 3
    var modelNodes = [
        ModelNode(name: "MLCDE", distance: 0, node: nil, visibility: true, bitMask : NodeTypes.MLCDE.rawValue, originalPos : nil, movedPos : nil, transitioning: false, backDistance: 0.02, toggled: false),
        ModelNode(name: "LCDE_1", distance: 0.9, node: nil, visibility: false, bitMask : NodeTypes.LCDE.rawValue, originalPos : nil, movedPos : nil, transitioning: false, backDistance: 0.02, toggled: false),
        ModelNode(name: "LCDE_2", distance: 0.3, node: nil, visibility: false, bitMask : NodeTypes.LCDE.rawValue, originalPos : nil, movedPos : nil, transitioning: false, backDistance: 0.03, toggled: false),
        ModelNode(name: "LCDE_3", distance: 0.6, node: nil, visibility: false, bitMask : NodeTypes.LCDE.rawValue, originalPos : nil, movedPos : nil, transitioning: false, backDistance: 0.02, toggled: false),
        ModelNode(name: "LCDE_4", distance: 0.3, node: nil, visibility: false, bitMask : NodeTypes.LCDE.rawValue, originalPos : nil, movedPos : nil, transitioning: false, backDistance: 0.02, toggled: false),
        ModelNode(name: "LCDE_5", distance: 0.6, node: nil, visibility: false, bitMask : NodeTypes.LCDE.rawValue, originalPos : nil, movedPos : nil, transitioning: false, backDistance: 0.02, toggled: false),
        ModelNode(name: "LCDE_6", distance: 0.3, node: nil, visibility: false, bitMask : NodeTypes.LCDE.rawValue, originalPos : nil, movedPos : nil, transitioning: false, backDistance: 0.02, toggled: false),
        ModelNode(name: "LCDE_7", distance: 0.9, node: nil, visibility: false, bitMask : NodeTypes.LCDE.rawValue, originalPos : nil, movedPos : nil, transitioning: false, backDistance: 0.02, toggled: false)
    ]
    var LoadAllNodes : Bool = true
    var muralScale : Float = 0.1
    var muralPosition : SCNVector3? = nil
    var muralOrientation : SCNVector4? = nil
    var muralRotation : SCNVector4? = nil
    var muralAnchor : SCNNode? = nil
    var workTable : SCNNode? = nil
    var VirtualLegacyStarted : Bool = false
    var MuralIsShown : Bool = false
    var isAnyModelShown : Bool = false
    var auditorioLocation = SCNVector3()
    var verticalPlanesStarted : Bool = false
    var atomHasFollowed : Bool = false
    // ### Atom config ###
    var atom : SCNNode? = nil
    var atomExploding : SCNNode? = nil
    var atomResetPositions : [SCNVector3]? = nil
    var atomResetPositionsL : [SCNVector3] = [
        SCNVector3(0.1,-0.1, -0.5),
        SCNVector3(-0.1,-0.2, -0.5),
        SCNVector3(-0.1,0.15, -0.5),
        SCNVector3(-0.1,0.15, -0.5),
        SCNVector3(0.0,0.0,0.0)
    ]
    var atomResetPositionsR : [SCNVector3] = [
        SCNVector3(-0.1,-0.1, -0.5),
        SCNVector3(0.1,-0.2, -0.5),
        SCNVector3(0.1,0.15, -0.5),
        SCNVector3(0.1,0.15, -0.5),
        SCNVector3(0.0,0.0,0.0)
    ]
    var atomResetNodeName : String = "AtomoMural"
    var atomResetNode : SCNNode? = nil
    var distanceMagnitude = Float(0.3)
    var referenceNode : SCNNode? = nil
    var explotionDuration = 3
    var forceFollow = false
    // ### Photos config ###
    var photoNames = ["Foto1Gris512x380", "Foto2Gris512x380", "Foto3Gris512x380", "Foto4Gris512x380", "Foto5Gris512x380", "Foto6Gris512x380", "Foto7Gris512x380", "Foto8Gris512x380", "Foto9Gris512x380", "Foto10Gris512x380", "Foto11Gris512x380", "Foto12Gris512x380", "Foto13Gris512x380", "Foto14Gris512x380", "Foto15Gris512x380", "Foto16Gris512x380", "Foto17Gris512x380"]
    var photoAudios = ["mp3", "VLF1","VLF2","VLF3","VLF4","VLF5","VLF6","VLF7", "VLF8","VLF9","VLF10","VLF11","VLF12","VLF13","VLF14","VLF15","VLF16", "VLF17"]
    var backPhoto = "espaldaFotosGris512x380"
    var voicePhotoOn = "AudioOn512x380"
    var voicePhotoOff = "AudioOff512x380"
    var photoReel : SCNNode? = nil
    var photoReelNodes : [PhotoNode] = []
    var photoReelPositionOffset : SCNVector3 = SCNVector3(-2.5, 0, -1)
    var atomPositionOffset : SCNVector3 = SCNVector3(0.6, 0.3, 0.3)
    var prevIndexOfPhotoChanged : Int = -1
    var actualDirectionOfPhotoDragged : Int = 0
    var photosLimit : Int = 6
    var photosOffsetPositive : Int = 3
    var photosOffsetNegative : Int = 3
    var radiansPerPhoto : Float = 1.0471975512 // 2pi/6
    var radiansStep : Float = 0.0174533 // 1 degree to radian
    var radiansError : Float = 0.0174533 // step
    var photoReelRotationAction : SCNAction? = nil
    var prevXdiffPan : CGFloat = 0
    var nextPhotoReelAngle : Float = 1.0471975512
    var prevPhotoReelAngle : Float = -1.0471975512
    var threadRunning : Bool = false
    // ### Tapped info ###
    var prevPan = CGPoint()
    // ### Scene configuration ###
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    let locationManager = CLLocationManager()
    var userLocation = CLLocation()
    // ### Flags ###
    var isAtomMoving : Bool = false
    var isAtomTapped : Bool = false
    var isPlaneHitted : Bool = false
    var isBezierTimerActive : Bool = true
    var isCheckerTimerActive : Bool = true
    var isPlaneDetectionActive : Bool = false
    // ### Follow config ###
    var bezierPoints = [SCNVector3(),SCNVector3(),SCNVector3(),SCNVector3(),SCNVector3()]
    let bezierDuration = 2.0
    let bezierInterval = 0.1
    let bezierSegments = 3.0 / 0.1
    var bezierInc = 1.0 / (3.0 / 0.1)
    var tActual = 1.0
    var bezierDelay = 1.0
    var checkerTimer : Timer? = nil
    var bezierTimer : Timer? = nil
    // ### Collision config ###
    var PlaneTarget : SCNNode?
    var planeNodes : [SCNNode] = []
    // ### Audio ###
    var apVoice = AVAudioPlayer()
    let voiceName : [String] = ["wav","0","1","2","3","4","5","6","7"]
    var apMusic = AVAudioPlayer()
    let musicName : [String] = ["Music","mp3"]
    // ### GUI Controller ###
    var guiController : GUIController = GUIController.sharedInstance
    // ### ScreenShot ###
    var screenshotImage :UIImage?
    // ### Instructions ###
    var horizontalPlaneInstructionText = "Encuentra un lugar despejado en el piso para poner el modelo"
    var atomInstructionText = "Toca el avatar"
    var verticalPlaneInstructionText = "Ahora encuentra una pared bien iluminada para poner el mural"
    var explotionInstructionText = "Puedes tocar cada elemento del mural para conocer su historia, o ver el carrete de fotos a la derecha"
    var scalingInstructionText = "Puedes crecer el modelo para verlo con mejor detalle"
    // ### Animations ###
    var nextAnimationNode = 0
    var animationTimer : Timer? = nil
    var animationInvertal : TimeInterval = 45
    let animationDistance : Float = 0.25
    let animationOffset : Float = 0.25
    
    // MARK: Load information
    // ############################## Load information ##############################
    override func viewDidLoad() {
        super.viewDidLoad()
        // Start location services
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        // Load model nodes
        LoadNodes()
        // Assign scene view delegate as self for handling plane detection
        sceneView.delegate = self
        
        // Assign tap gesture handler
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        // Asign pinch gesture gandler
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        self.sceneView.addGestureRecognizer(pinchGestureRecognizer)
        // Assign pan gesture handler
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        self.sceneView.addGestureRecognizer(panGestureRecognizer)
        // Set referenceNode of pointOfView of the scene
        referenceNode = self.sceneView.pointOfView
        // Loads Audio
        loadAudio()
        // Plays background music
        apMusic.play()
        apMusic.numberOfLoops = -1
        apVoice.delegate = self
        // Buttons
        snapButton.isHidden = toggle
        optionButton.isHidden = toggle
        self.snapButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        self.optionButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        // GUIController
        guiController.mainViewController = self
        
        // Initial instruction
        self.view.makeToast(horizontalPlaneInstructionText, duration: guiController.infiniteTime, position: .bottom, style: guiController.toastStyleInstruction)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Scene configuration
        self.sceneView.debugOptions = []
        if #available(iOS 11.3, *) {
            self.configuration.planeDetection = [.horizontal]
            isPlaneDetectionActive = true
        } else {
            // Fallback on earlier versions
            self.configuration.planeDetection = .horizontal
            isPlaneDetectionActive = true
        }
        //self.configuration.worldAlignment = .gravityAndHeading JATJ
        self.sceneView.session.run(configuration )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Pause the view's session
        self.sceneView.session.pause()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("View Controller appear")
        if(apVoice.isPlaying){
            apVoice.pause()
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Button actions
    //############### OPTION BUTTONS################
    @IBAction func menuToggle(_ sender: Any) {
        if toggle{
            snapButton.isHidden = false
            optionButton.isHidden = false
            UIView.animate(withDuration: 0.6,animations: {self.snapButton.transform = CGAffineTransform.identity; self.optionButton.transform = CGAffineTransform.identity})
            toggleButton.setBackgroundImage(UIImage(named: "closeIcon.png"), for: UIControlState.normal)
            toggle = false
        }
        else {
            UIView.animate(withDuration: 0.6,animations: {self.snapButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1); self.optionButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)},
               completion: { _ in
                self.snapButton.isHidden = true
                self.optionButton.isHidden = true
                })
            toggleButton.setBackgroundImage(UIImage(named: "optionIcon.png"), for: UIControlState.normal)
            toggle = true
        }
    }
    
    @IBAction func snapShot(_ sender: Any) {
        takeScreenshot()
    }
    
    /**
     Take a screenshot with animation and save it to the photo library
     - parameters:
        - shouldSave : Bool if the image need to be saved on the photo library
    */
    open func takeScreenshot(_ shouldSave: Bool = true) -> UIImage? {
        screenshotImage = sceneView.snapshot()
        UIGraphicsEndImageContext()
        if let image = screenshotImage, shouldSave {
            let aView = UIView(frame: self.view.frame)
            aView.backgroundColor = UIColor.white
            self.view.addSubview(aView)
            
            UIView.animate(withDuration: 1.3, delay: 0, options: [.curveEaseInOut], animations: { () -> Void in
                aView.alpha = 0.0
            }, completion: { (done) -> Void in
                aView.removeFromSuperview()
                
                
                self.view.makeToast("La captura se ha guardado en el carrete de fotos", duration: 3.0, position: .center, style: self.guiController.toastStyleNotification)
            })
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
        return screenshotImage
    }
    
    // MARK: Gesture Handlers
    // ############################## Gestures Handlers ##############################
    /**
     Fades the main model if some part is on foreground
    */
    func fadeOutBackground(){
        print("Checking background")
        for (_, modelNode) in modelNodes.enumerated(){
            if(modelNode.name == modelNodes[0].name){continue}
            if(modelNode.visibility){
                isAnyModelShown = true
                modelNodes[0].node!.childNode(withName: "Model", recursively: true)!.geometry?.firstMaterial?.diffuse.intensity = 0.4
                print("Is in background")
                return
            }
        }
        print("Is in foreground")
        isAnyModelShown = false
        modelNodes[0].node!.childNode(withName: "Model", recursively: true)!.geometry?.firstMaterial?.diffuse.intensity = 1
    }
    
    /**
     Delegate func handle tap gesture
     */
    @objc func handleTap(sender : UITapGestureRecognizer){
        let sceneViewTapped = sender.view as! SCNView
        let tapCoords = sender.location(in: sceneViewTapped)
        // Tapping horizontal planes to start Virtual Legacy
        // Check target
        let nodeHitTest = sceneViewTapped.hitTest(tapCoords)
        if (nodeHitTest.isEmpty == false){
            let results = nodeHitTest.first
            let name = results?.node
            if (name?.hasAncestor("Atomo"))!{
                if(!atomHasFollowed){
                    isAtomTapped = true
                    if(isBezierTimerActive){
                        atomResetPositions![4] = atom!.position
                        bezierPoints[4] = atom!.position
                        tActual = 1.0
                        forceFollow = true
                        bezierTimer = Timer.scheduledTimer(timeInterval: bezierInterval, target: self, selector: #selector(ViewController.atomFollow), userInfo: nil, repeats: true)
                        
                        print("STARTIN BEZIER TIMER 306")
                        self.view.hideAllToasts()
                        //  Change toast instruction
                        self.view.makeToast(scalingInstructionText, duration: guiController.infiniteTime, position: .bottom, style: guiController.toastStyleInstruction)
                        atomHasFollowed = true
                    }
                    else{
                        if(bezierTimer != nil){
                            bezierTimer?.invalidate()
                            bezierTimer = nil
                        }
                    }
                }
            }
        }
        if(!VirtualLegacyStarted){
            let bitMask = NodeTypes.target.rawValue
            let hitTest = sceneViewTapped.hitTest(tapCoords, options : [SCNHitTestOption.categoryBitMask : bitMask])
            if(!hitTest.isEmpty){
                for hit in hitTest{
                    for planeNode in planeNodes{
                        if (hit.node.hasAncestor(planeNode)){
                            self.configuration.planeDetection = []
                            self.sceneView.session.run(configuration)
                            isPlaneDetectionActive = false
                            print("###### Start virtual legacy ######")
                            VirtualLegacyStarted = true
                            StartVirtualLegacy(position: planeNode.convertPosition(planeNode.position, to: nil))
                            // Remove horizontal planes loaded
                            clearPlanes()
                            // Cleans planes with 5 seconds delay
                            Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(ViewController.clearPlanes), userInfo: nil, repeats: false)
                            return
                        }
                    }
                }
            }
            return
        }
        
        // Tapping vertical planes to start Virtual Legacy
        if(!MuralIsShown){
            // Check target
            let bitMask = NodeTypes.target.rawValue
            let hitTest = sceneViewTapped.hitTest(tapCoords, options : [SCNHitTestOption.categoryBitMask : bitMask])
            if(!hitTest.isEmpty){
                for hit in hitTest{
                    for planeNode in planeNodes{
                        if (hit.node.hasAncestor(planeNode)){
                            AtomExplotion(planeNode: planeNode)
                            return
                        }
                    }
                }
            }
            return
        }
        
        // Tapping model objects
        var bitMask = NodeTypes.LCDE.rawValue
        var hitTest = sceneViewTapped.hitTest(tapCoords, options : [SCNHitTestOption.categoryBitMask : bitMask])
        if(hitTest.isEmpty){
        }else{
            print("Touch something")
            // Check if the hit is a model part
            for hit in hitTest {
                for (index, modelNode) in modelNodes.enumerated(){
                    if(hit.node.hasAncestor(modelNode.node!)){
                        if(modelNode.transitioning){
                            break
                        }
                        modelNodes[index].transitioning = true
                        modelNodes[index].toggled = true
                        // TODO: check what is the next animation node
                        var anyNotToggled = false
                        for (i, modelNode) in modelNodes.enumerated(){
                            if(modelNode.name == "MLCDE"){continue}
                            if(!modelNode.toggled){
                                nextAnimationNode = i
                                anyNotToggled = true
                                break;
                            }
                        }
                        if(!anyNotToggled){
                            nextAnimationNode = -1
                        }
                        // Toggle the model back and forward
                        if apVoice.isPlaying{
                            apVoice.setVolume(0, fadeDuration: 0.4)
                            sleep(UInt32(0.4))
                            apVoice.stop()
                            print("stopped")
                        }
                        if(!modelNode.visibility){
                            modelNode.node!.runAction(SCNAction.move(by: modelNode.movedPos!, duration: TimeInterval(Float(maxSeconds) * modelNode.distance)), completionHandler: {
                                self.modelNodes[index].transitioning = false
                                self.modelNodes[index].visibility = true
                                self.fadeOutBackground();
                            })
                            do{
                                apVoice = try AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: voiceName[index + 1], ofType: voiceName[0])!))
                                setOffPhotoReel()
                            }
                            catch{
                                print(error)
                            }
                            apVoice.prepareToPlay()
                            apVoice.volume = guiController.configuration.voiceVolume
                            apVoice.play()
                        }else{
                            modelNode.node!.runAction(SCNAction.move(by: modelNode.movedPos!*Float(-1), duration: TimeInterval(Float(maxSeconds) * modelNode.distance)), completionHandler: {
                                self.modelNodes[index].transitioning = false
                                self.modelNodes[index].visibility = false
                                self.fadeOutBackground();
                            })
                        }
                        return
                    }
                }
            }
        }
        
        // Tapping photo voices objects
        bitMask = NodeTypes.photoVoice.rawValue
        hitTest = sceneViewTapped.hitTest(tapCoords, options : [SCNHitTestOption.categoryBitMask : bitMask])
        if(hitTest.isEmpty){
        }else{
            // Check if the hit is a photonode
            for hit in hitTest {
                for (index, photoNode) in photoReelNodes.enumerated(){
                    if(hit.node.hasAncestor(photoNode.voiceNode)){
                        print("Touched photo")
                        if(photoNode.isPlaying){
                            setOffPhotoReel()
                            if apVoice.isPlaying{
                                apVoice.setVolume(0, fadeDuration: 0.4)
                                sleep(UInt32(0.4))
                                apVoice.stop()
                                print("stopped")
                            }
                        }else{
                            if apVoice.isPlaying{
                                apVoice.setVolume(0, fadeDuration: 0.4)
                                sleep(UInt32(0.4))
                                apVoice.stop()
                                print("stopped")
                            }
                            do{
                                apVoice = try AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: photoNode.audioName, ofType: photoAudios[0])!))
                                setOffPhotoReel()
                                setOnPhotoReel(i: index)
                            }
                            catch{
                                print(error)
                            }
                            apVoice.prepareToPlay()
                            apVoice.volume = guiController.configuration.voiceVolume
                            apVoice.play()
                        }
                        return
                    }
                }
            }
        }

    }
    
    /**
     Delegate func handle pan gesture
     */
    @objc func handlePan(sender: UIPanGestureRecognizer) {
        let sceneViewTapped = sender.view as! SCNView
        let tapCoords = sender.location(in: sceneViewTapped)
        let bitMask = NodeTypes.atom.rawValue | NodeTypes.photoReelSphere.rawValue
        let hitTest = sceneViewTapped.hitTest(tapCoords, options: [SCNHitTestOption.categoryBitMask : bitMask])
        if(hitTest.isEmpty){
            // No touch any node
            prevPan.x = 0;
            prevPan.y = 0;
            return;
        }else{
            // Touched a scene node
            handlePannedObject(sender: sender, hitTest: hitTest, iteration: 0, tapCoords: tapCoords, sceneViewTapped: sceneViewTapped)

            isAtomMoving = false
        }
    }

    func startVerticalPlanes(){
        print("vertical planes started")
        self.view.hideAllToasts()
        // Explotion instruction
        self.view.makeToast(verticalPlaneInstructionText, duration: guiController.infiniteTime, position: .bottom, style: guiController.toastStyleInstruction)
        //#####################START VERTICAL PLANE DETECTION##########################
        self.configuration.planeDetection = .vertical
        self.sceneView.session.run(configuration)
        isPlaneDetectionActive = true
    }
    
    /**
      Executed when panning a node in the scene
    */
    @objc func handlePannedObject(sender: UIPanGestureRecognizer, hitTest : [SCNHitTestResult], iteration : Int, tapCoords : CGPoint, sceneViewTapped : SCNView){
        if(iteration >= hitTest.count){
            return
        }
        // Validates if the hit element in the iteration
        let result: SCNHitTestResult = hitTest[iteration] 
        
        // Panned object is a photo in the photoreel
        if(photoReel != nil) {
            if(result.node.hasAncestor(photoReel!)){
                photoReel!.removeAction(forKey: "SwipeReel")
                if(sender.state == UIGestureRecognizerState.ended){
                    //print("######### GESTURE ENDED #############")
                    //print(prevXdiffPan)
                    //photoReel!.runAction(SCNAction.rotateBy(x: 0, y: CGFloat(radiansPerPhoto/2.0)*CGFloat(actualDirectionOfPhotoDragged), z: 0, duration: TimeInterval(0.25)), forKey: "SwipeReel")
                    //checkTurnPhotoReel(radians: photoReel!.eulerAngles.y)
                    return
                }
                
                prevXdiffPan = tapCoords.x - prevPan.x
                // Dragging photoreel
                var degrees = Float(0.0)
                if(prevXdiffPan > 0){
                    degrees = 1
                }else{
                    degrees = -1
                }
                actualDirectionOfPhotoDragged = Int(degrees)
                photoReel!.eulerAngles = photoReel!.eulerAngles + SCNVector3(0,1,0) * degrees * radiansStep
                checkTurnPhotoReel(radians: photoReel!.eulerAngles.y)
                prevPan.x = tapCoords.x;
                prevPan.y = tapCoords.y;
            }
        }
        
        // Panned object is an atom
        if(atom != nil) {
            if(result.node.hasAncestor(atom!)){
                isAtomMoving = true
                let position = sceneView.unprojectPoint(SCNVector3(tapCoords.x,tapCoords.y,0))
                
                let direction = position.direction(referenceNode!.position)
                
                distanceMagnitude = atom!.position.distanceTo(referenceNode!.position)
                
                // Drag atom
                atom!.position = SCNVector3(referenceNode!.position.x + direction.normalized.x*distanceMagnitude, referenceNode!.position.y + direction.normalized.y*distanceMagnitude,referenceNode!.position.z + direction.normalized.z*distanceMagnitude)
                // Hit object is a plane
                if(!planeNodes.isEmpty && !isPlaneHitted) {
                    let bitMask = NodeTypes.target.rawValue
                    let planeResults = sceneViewTapped.hitTest(tapCoords, options: [SCNHitTestOption.categoryBitMask : bitMask])
                    
                    for planeResult in planeResults{
                        for planeNode in planeNodes{
                            if (planeResult.node.hasAncestor(planeNode)){
                                AtomExplotion(planeNode: planeNode)
                                break
                            }
                        }
                        if(isPlaneHitted){
                            break
                        }
                    }
                }
            }
        }
        
        if(!isAtomMoving){
            // Call again but one iteration over
            handlePannedObject(sender: sender, hitTest: hitTest, iteration: iteration+1, tapCoords: tapCoords, sceneViewTapped: sceneViewTapped)
        }
    }
    
    /**
     Executed when pinching the screen
     */
    @objc func handlePinch(sender: UIPinchGestureRecognizer, position: SCNVector3){
        let viewNode = self.sceneView.scene.rootNode.childNode(withName: "Table", recursively: false)
        let auditorio = self.sceneView.scene.rootNode.childNode(withName: "Edificio", recursively: true)
        let plane = sceneView.scene.rootNode.childNode(withName: "plane", recursively: true)
        centerPivot(for: auditorio!)
        let newPosition = SCNVector3(((auditorioLocation.x)),(auditorioLocation.y),((auditorioLocation.z) - 0.5))
        auditorio?.position = newPosition
        //centerYPivot(for: plane!)
        let planeyPosition = plane?.position.y
        
        auditorio?.position = SCNVector3Make((auditorio?.position.x)!, planeyPosition!, (auditorio?.position.z)!)
        let isInScene = self.sceneView.isNode((viewNode)!, insideFrustumOf: sceneView.pointOfView!)
        if(isInScene){
            if(!verticalPlanesStarted){
                startVerticalPlanes()
                /* JATJ: AtomFollow
                if(!isAtomTapped){
                    if(bezierTimer != nil){
                        // Cancel bezier timer
                        bezierTimer!.invalidate()
                        bezierTimer = nil
                    }
                    Timer.scheduledTimer(timeInterval: 0, target: self, selector: #selector(ViewController.atomStartFollow), userInfo: nil, repeats: false)
                    atomHasFollowed = true
                    isAtomTapped = true
                }
                */
            }
 
            verticalPlanesStarted = true
            var pinchAction = SCNAction.scale(by: sender.scale, duration: 0)
            let maxScale = Float(2.0)
            let minScale = Float(0.24)
            let scale = auditorio?.scale.x
            if(scale! > maxScale ){
                pinchAction = SCNAction.scale(to: CGFloat(maxScale), duration: 0)
                //print("max scale limit")
            }
            else if (scale! < minScale){
                pinchAction = SCNAction.scale(to: CGFloat(minScale), duration: 0)
                //print("min scale limit")
            }
            auditorio?.runAction(pinchAction)
            sender.scale = 1.0
        }
        else{
            //print("not in scene, not scaling")
        }
    }
    
    func centerPivot(for node: SCNNode){
        let min = node.boundingBox.min
        let max = node.boundingBox.max
        node.pivot = SCNMatrix4MakeTranslation(
            (min.x) + ((max.x) - (min.x)) / 2,
            (min.y),
            (min.z) + ((max.z) - (min.z)) / 2
        )
    }
    
    /**
     AtomExplotion, is executed when the vertical target is tapped
     - parameters:
        - planeNode : SCNNode is the plane where the modal is loaded
    */
    func AtomExplotion(planeNode : SCNNode){
        print("###### Atom explotion ######")
        
        isPlaneHitted = true
        muralPosition = planeNode.convertPosition(planeNode.position, to: nil)
        muralOrientation = planeNode.worldOrientation
        muralRotation = planeNode.rotation
        muralAnchor = planeNode.parent
        
        let relativeAtomPosition = planeNode.position + atomPositionOffset
        atomPositionOffset = planeNode.convertPosition(relativeAtomPosition, to: nil)
        
        // Empty vertical planes
        for planeNodeI in planeNodes{
            planeNodeI.removeFromParentNode()
        }
        
        // Add exploding atom
        sceneView.scene.rootNode.addChildNode(atomExploding!)
        atomExploding!.position = muralPosition!
        // Hide normal atom
        atom?.isHidden = true
        // Timer for exploded atom
        Timer.scheduledTimer(timeInterval: TimeInterval(0.5 + Double(explotionDuration)), target: self, selector: #selector(ViewController.AtomExploded), userInfo: nil, repeats: false)
        self.AddModelNode(nil)
        // Show photo reel
        self.generatePhotoReel(photos: self.photoNames, photoWidth: 0.6, photoHeight: 0.4, padding: 0.1)

        // Plays voice
        apVoice.play()
        
        self.view.hideAllToasts()
        // Explotion instruction
        self.view.makeToast(explotionInstructionText, duration: guiController.infiniteTime, position: .bottom, style: guiController.toastStyleInstruction)
        Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(ViewController.positionAtom), userInfo: nil, repeats: false)
    }
    @objc func positionAtom() {
        atom!.runAction(SCNAction.move(to: atomPositionOffset, duration: 0.1))
    }
    /**
     When atom is exploded
     */
    @objc func AtomExploded(){
        print("Exploded")
        atomExploding!.isHidden = true
        atomExploding!.removeFromParentNode()
        atom!.isHidden = false
        if(bezierTimer != nil){
            // Cancel bezier timer
            bezierTimer!.invalidate()
            bezierTimer = nil
           // print("INVALIDATING BEZIER TIMER")
        }
        else{
           // print("Bezier timer not nil: " + String(describing: bezierTimer))
        }
        if(checkerTimer != nil){
            // Cancel bezier timer
            checkerTimer!.invalidate()
            checkerTimer = nil
            //print("INVALIDATING ATOM CHECK TIMER")
        }
        else{
            //print("checkerTimer timer not nil: " + String(describing: checkerTimer))
        }
    }
    
    /**
     clear vertical or horizontal planes
     */
    @objc func clearPlanes(){
        print("Cleaning planes again")
        //remove all planes from scene
        for planeNode in planeNodes{
            planeNode.removeFromParentNode()
            //print("plane removed")
        }
    }
    
    // MARK: Audio Handlers
    // ############################## Audio Handlers ##############################
    /**
     Delegate function, fihnish playing audio
     */
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("Finished playing voice")
        setOffPhotoReel()
    }
    
    /**
     Change volume of the audio players to the configuration ones
     */
    func SetVolumes(){
        self.apVoice.volume = guiController.configuration.voiceVolume
        self.apMusic.volume = guiController.configuration.musicVolume
    }
    
    // MARK: Manage model nodes
    // ############################## Manage model nodes ##############################
    
    /**
     Get node from scn file with the parameter name
     - parameters:
         - folderName: Name of the folder containing the scn files
         - fileName: Name of the scn file
         - nodeName: Name of the node inside the scn file
         - recursively: To search for the node recursively or not
         - ext: Extension of the file
     - returns:
        SCNNode of the loaded node
     */
    func LoadModel(folderName: String, fileName: String, nodeName: String, recursively: Bool, ext : String = ".scn") -> SCNNode?{
        let scenePath = folderName + "/" + fileName + ext
        let scene = SCNScene(named:scenePath)
        return scene?.rootNode.childNode(withName: nodeName, recursively: recursively)
    }

    /**
     Load all nodes from mural
     */
    func LoadNodes(){
        // Prepare and load mural models for scene
        for (index, modelNode) in modelNodes.enumerated(){
            let node = LoadModel(folderName: "art.scnassets", fileName: modelNode.name, nodeName: modelNode.name, recursively: false);
            // If not found
            if node == nil{
                return
            }
            
            // Set mask
            SetCategoryMask(node: node!, mask: modelNode.bitMask)
            
            self.sceneView.prepare(node!) { () -> Bool in
                return true
            }
            modelNodes[index].node = node
        }
        loadWorkTable()
        loadAtom()
    }
    
    /**
     Sets category bitmask for a node and all of its childs
     - parameters:
        - node : SCNNode for setting the bitmask
        - mask : Int bitmask value
     - returns:
     */
    func SetCategoryMask(node : SCNNode, mask : Int){
        node.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: node, options: nil))
        node.physicsBody?.categoryBitMask = mask
        node.categoryBitMask = mask
        for child in node.childNodes {
            SetCategoryMask(node: child, mask: mask)
        }
    }
    
    /**
     Loads all nodes from same file
     - parameters:
     - returns:
     */
    func LoadNodesSameFile(){
        let scenePath = "art.scnassets/MLCDE.scn"
        let scene = SCNScene(named:scenePath)
        
        // Prepare and load models for scene
        for (index, modelNode) in modelNodes.enumerated(){
            let node = scene?.rootNode.childNode(withName: modelNode.name, recursively: false)
            // If not found
            if node == nil{
                return
            }
            
            // Set mask
            SetCategoryMask(node: node!, mask: modelNode.bitMask)
            
            self.sceneView.prepare(node!) { () -> Bool in
                return true
            }
            
            modelNodes[index].node = node
        }
        loadWorkTable()
        loadAtom()
    }
    
    /**
     Ads model to scene
     - parameters:
         - sender : sender
         - i : node index
     - returns:
     */
    func AddModelNode(sender : Any?, i : Int){
        print("Loading all nodes: ",i)
        
        // Add model to scene JATJ: mural anchor
        muralAnchor?.addChildNode(modelNodes[i].node!)
        modelNodes[i].node!.position = SCNVector3(0,0,0)
        modelNodes[i].node!.eulerAngles = SCNVector3(-Double.pi/2,0,Double.pi)
        
        modelNodes[i].node!.scale = SCNVector3(muralScale,muralScale,muralScale)
        
        // Scale animation
        let originalScale = modelNodes[i].node!.scale
        modelNodes[i].node!.scale = SCNVector3(0,0,0)
        modelNodes[i].node!.runAction(SCNAction.scale(to: CGFloat(originalScale.x), duration: TimeInterval(explotionDuration)))
        
        let frontVec = (modelNodes[i].node!.orientation * SCNVector3(0,0,-1)).normalized
        
        let muralBackPosition = modelNodes[i].node!.position + (frontVec * Float(-modelNodes[i].backDistance))
        let muralForwardPosition = modelNodes[i].node!.position + (frontVec * Float(maxDistance))
        
        // If node is not the main model
        if(modelNodes[i].bitMask == NodeTypes.LCDE.rawValue){
            // Move back image
            modelNodes[i].node!.position = muralBackPosition
            
            modelNodes[i].originalPos = modelNodes[i].node!.position
            
            modelNodes[i].movedPos = (muralForwardPosition - muralBackPosition) * modelNodes[i].distance
            
            modelNodes[i].visibility = false
        }
    }
    
    /**
     Adds next model node to the scene with an animation
    */
    func AddModelNode(_ sender: Any?) {
        if(muralPosition == nil || MuralIsShown == true){
            return
        }
        if(LoadAllNodes && index < modelNodes.count){
            // Load model nodes
            for (i, _) in modelNodes.enumerated(){
                AddModelNode(sender: sender, i: i)
            }
            index = modelNodes.count
        }
        
        MuralIsShown = true
        /*
        atomResetNode = sceneView.scene.rootNode.childNode(withName: atomResetNodeName, recursively: true)
        let position = atomResetNode!.worldPosition + (atomResetNode!.position * muralScale)
        let posReflected = SCNVector3(-position.x,position.y,-position.z)
        atom?.runAction(SCNAction.move(to: posReflected, duration: TimeInterval(maxSeconds)))
        */
        // Stop following
        if(bezierTimer != nil){
            // Cancel bezier timer
            bezierTimer!.invalidate()
            bezierTimer = nil
            print("CANCELLING BEZIER TIMER")
            isBezierTimerActive = false
        }
        else{
            print("BEZIER TIMER NIL: " + String(describing: bezierTimer))
        }
        if(checkerTimer != nil){
            // Cancel atom check timer
            checkerTimer!.invalidate()
            checkerTimer = nil
            print("CANCELLING ATOM CHECKING TIMER")
            isCheckerTimerActive = false
        }
        else{
            print("CHECKER TIMER NIL: " + String(describing: checkerTimer))
        }
    }
    
    /**
     Loads table atom and start vertical plane recognition
     */
    func StartVirtualLegacy(position : SCNVector3){
        addWorkTable(position: position)
        addAtom()
        
        self.view.hideAllToasts()
        // Vertical plane instruction
        self.view.makeToast(atomInstructionText, duration: guiController.infiniteTime, position: .bottom, style: guiController.toastStyleInstruction)
        
        // Start animation timer
        StartAnimationTimer()
    }
    
    /**
     Reset model
     */
    func ResetExplotion(){
        if(!MuralIsShown){
            return
        }
        print("###### Resetting model ######")
        isPlaneHitted = false
        // Remove photo reel
        photoReel?.removeFromParentNode()
        photoReel = nil
        prevIndexOfPhotoChanged = -1
        actualDirectionOfPhotoDragged = 0
        for (i, _) in photoReelNodes.enumerated(){
            photoReelNodes[i].node.removeFromParentNode()
        }
        photoReelNodes = []
        // Remove Models
        for (i, _) in modelNodes.enumerated(){
            modelNodes[i].node?.removeFromParentNode()
        }
        atom?.isHidden = false
        MuralIsShown = false
        muralPosition = nil
        index = 0
        if(apVoice.isPlaying){
            apVoice.stop()
        }
        // Load voice
        do{
            apVoice = try AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: voiceName[1], ofType: voiceName[0])!))
            apVoice.prepareToPlay()
            apVoice.volume = guiController.configuration.voiceVolume
        }catch{
            print(error)
        }
        // Remove targets
        for planeNode in planeNodes{
            planeNode.removeFromParentNode()
        }
    }
    
    /**
     Reset All virtual legacy
     */
    func ResetVirtualLegacy(){
        if(!VirtualLegacyStarted){
            return
        }
        ResetExplotion()
        // Remove atom
        if(atom != nil){
            atom?.removeFromParentNode()
        }
        // Remove work table
        if(workTable != nil){
            workTable?.removeFromParentNode()
        }
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        // Remove targets
        for planeNode in planeNodes{
            planeNode.removeFromParentNode()
        }
        VirtualLegacyStarted = false
    }
    
    /**
     Load the workTable with map and building to the scene
     */
    func loadWorkTable(){
        let tableNode = LoadModel(folderName: "art.scnassets/Table", fileName: "Table", nodeName: "Table", recursively: false)!;
        self.sceneView.prepare(tableNode) { () -> Bool in
            return true
        }
        workTable = tableNode
    }
    
    /**
       Add the workTable with map and building to the scene
    */
    func addWorkTable(position : SCNVector3){
        if(workTable != nil){
            workTable!.position = position
            sceneView.scene.rootNode.addChildNode(workTable!)
            let edificio = self.sceneView.scene.rootNode.childNode(withName: "Edificio", recursively: true)
            auditorioLocation = SCNVector3((edificio?.position.x)!, (edificio?.position.y)!, (edificio?.position.z)!)
        }
    }
    
    // MARK: Animations
    // ############################## Animations ##############################
    /**
     Animates a node for the user to notice that it is interactable
     - parameters:
         - modelNode : ModelNode for animate
         - index : Int index in the modelnodes array
         - duration : TimeInterval duration of animation
     - returns:
     */
    func animateNode(modelNode : ModelNode, index : Int, distance : Float, duration : TimeInterval){
        if (modelNode.movedPos != nil){
            let vec = modelNode.movedPos! - modelNode.node!.position
            let movedPos = (vec.normalized*Float(distance))
            
            modelNodes[index].transitioning = true
            modelNode.node!.runAction(SCNAction.move(by: movedPos, duration: duration), completionHandler: {
                modelNode.node!.runAction(SCNAction.move(by: movedPos*Float(-1), duration: duration), completionHandler: {
                    self.modelNodes[index].transitioning = false
                })
            })
        }
        else{
        }
    }
    
    /**
     Do the animation of all the elements or the next one in the chronology
    */
    @objc func DoChronologyAnimation(){
        if(nextAnimationNode == -1){ return }
        if(nextAnimationNode == 0){
            // Animates all elements
            for (i, modelNode) in modelNodes.enumerated(){
                if(modelNode.name == "MLCDE"){continue}
                if(modelNode.toggled){continue}
                animateNode(modelNode: modelNodes[i], index: i, distance: animationDistance, duration: TimeInterval(animationOffset+Float(i)*animationOffset))
            }
            // Prepare next timer
            animationTimer = nil
            Timer.scheduledTimer(timeInterval: TimeInterval(animationOffset*Float(modelNodes.count)), target: self, selector: #selector(ViewController.StartAnimationTimer), userInfo: nil, repeats: false)
        }else{
            // Animates just the next one in the chronology
            animateNode(modelNode: modelNodes[nextAnimationNode], index: nextAnimationNode, distance: animationDistance, duration: TimeInterval(animationOffset))
            // Prepare next timer
            animationTimer = nil
            Timer.scheduledTimer(timeInterval: TimeInterval(animationOffset*2.0), target: self, selector: #selector(ViewController.StartAnimationTimer), userInfo: nil, repeats: false)
        }
    }
    
    /**
     Starts the animation timer that triggers the next animation
     */
    @objc func StartAnimationTimer(){
        animationTimer = Timer.scheduledTimer(timeInterval: animationInvertal, target: self, selector: #selector(ViewController.DoChronologyAnimation), userInfo: nil, repeats: false)
    }
    
    // MARK: Audio
    // ############################## Audio ##############################
    /**
     Load audio for background music
    */
    func loadAudio(){
        // Load music
        do{
            apMusic = try AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: musicName[0], ofType: musicName[1])!))
            apMusic.prepareToPlay()
            apMusic.volume = guiController.configuration.musicVolume
        }catch{
            print(error)
        }
        // Load voice
        do{
            apVoice = try AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: voiceName[1], ofType: voiceName[0])!))
            apVoice.prepareToPlay()
            apVoice.volume = guiController.configuration.voiceVolume
        }catch{
            print(error)
        }
    }
    
    // MARK: Plane detection
    // ############################## Plane detection ##############################
    
    /**
     Creates plane on the position of a ARPlaneAnchor
     - parameters:
         - planeAnchor: ARPlaneAnchor to be loaded the panel
     - returns:
        SCNNode of the loaded panel
     */
    func createPlane(planeAnchor : ARPlaneAnchor) -> SCNNode{
        planeImage = planeImage + 1
        if planeImage > 4 {
            planeImage = 1
        }
        let planeHolder = "plane" + String(describing: planeImage) + ".png"
        let planeNode = SCNNode(geometry: SCNPlane(width: CGFloat(0.6), height: CGFloat(0.6)   ))
        planeNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: planeHolder)
        planeNode.geometry?.firstMaterial?.isDoubleSided = false
        planeNode.position = SCNVector3(planeAnchor.center.x,planeAnchor.center.y,planeAnchor.center.z)
        planeNode.eulerAngles = SCNVector3(-90.degreesToRadians, 0, 0)
        
        SetCategoryMask(node: planeNode, mask: NodeTypes.target.rawValue)
        planeNode.physicsBody?.contactTestBitMask = NodeTypes.bullet.rawValue
        return planeNode
    }
    
    /**
     Triggered when recognized a new plane
     */
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if(isPlaneHitted){
            return
        }
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        //print("New planeanchor added")
        let newPlane = createPlane(planeAnchor: planeAnchor)
        if isPlaneDetectionActive{
            planeNodes.append(newPlane)
            node.addChildNode(newPlane)
        }
    }
    
    /**
     Triggered when updated an added plane
     */
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if(isPlaneHitted){
            return
        }
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
        let newPlane = createPlane(planeAnchor: planeAnchor)
        //print("New planeanchor re-added")
        //print("plane orientation: " + String(describing: newPlane.orientation))
        //print("plane euler angles: " + String(describing: newPlane.eulerAngles))
        if isPlaneDetectionActive{
            planeNodes.append(newPlane)
            node.addChildNode(newPlane)
            print("New planeanchor re-added")
        }
    }
    
    /**
     Triggered when removed an added plane
     */
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if(isPlaneHitted){
            return
        }
        guard anchor is ARPlaneAnchor else {return}
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
    }
    
    // MARK: Photo reel
    // ############################## Photos reel ##############################
    
    /**
     Generates a photo reel,
     - parameters:
         - photos: Array<String> contains the name of the images to load
         - center: SCNVector3 contains the x,y,z position for where the photo reel is going to be loaded
         - photoWidth: Float defines the width of a simple photo in meters
         - photoHeight: Float defines the height of a simple photo in meters
         - padding: Float defines the padding of a simple photo in meters
     - returns:
     */
    func generatePhotoReel(photos: Array<String>, photoWidth : Float, photoHeight : Float, padding : Float){
        if(photoReel != nil){
            return
        }
        // JATJ: muralAnchor
        let photoReelParent = SCNNode()
        photoReel = SCNNode()
        muralAnchor?.addChildNode(photoReelParent)
        
        // Calculation of radians
        let referenceVector = SCNVector3(0,1,0)
        let upVector = photoReelParent.orientation * referenceVector
        let absoluteUpVector = photoReelParent.convertVector(upVector, from: nil)
        
        // Calculate z radians
        let absoluteUpVectorXY = SCNVector3(absoluteUpVector.x,absoluteUpVector.y,0)
        let angleZ = acos(referenceVector.dotProduct(absoluteUpVectorXY) / (referenceVector.magnitude * absoluteUpVectorXY.magnitude))
        // Calculate x radians
        let absoluteUpVectorZY = SCNVector3(absoluteUpVector.z,absoluteUpVector.y,0)
        let angleX = acos(referenceVector.dotProduct(absoluteUpVectorZY) / (referenceVector.magnitude * absoluteUpVectorZY.magnitude))
        
        photoReelParent.eulerAngles = photoReel!.eulerAngles + SCNVector3(-angleX, 0, -angleZ)
        
        photoReelParent.addChildNode(photoReel!)
        photoReel!.eulerAngles = SCNVector3(0, Double.pi, 0)
        photoReel!.position = photoReel!.orientation * photoReelPositionOffset
        
        
        let radius = (photoWidth + padding)
        let radianInc = (360/photosLimit).degreesToRadians
        
        for (index, _) in photos.enumerated(){
            if(index >= photosLimit){break}
            var i = index
            if(index > photosLimit/2){
                // Move to last photos
                i = photos.count - (photosLimit - index)
            }
            let photo = photos[i]
            // Photo Node
            let photoNode = SCNNode(geometry: SCNPlane(width: CGFloat(photoWidth), height: CGFloat(photoHeight)))
            photoNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: photo)
            // Calculate position
            let x = cos(radianInc*CGFloat(index)) * CGFloat(radius)
            let z = sin(radianInc*CGFloat(index)) * CGFloat(radius)
            photoNode.position = SCNVector3(x,0,z)
            // Calculate rotation
            photoNode.eulerAngles = SCNVector3(0, (90.degreesToRadians - radianInc*CGFloat(index)), 0)
            SetCategoryMask(node: photoNode, mask: NodeTypes.photo.rawValue)
            
            // Background Node
            let backNode = SCNNode(geometry: SCNPlane(width: CGFloat(photoWidth), height: CGFloat(photoHeight)))
            backNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: backPhoto)
            // Calculate position
            backNode.position = SCNVector3(x,0,z)
            // Calculate rotation
            backNode.eulerAngles = SCNVector3(0, (270.degreesToRadians - radianInc*CGFloat(index)), 0)
            SetCategoryMask(node: backNode, mask: NodeTypes.photo.rawValue)
            
            // Voice Node
            let voiceNode = SCNNode(geometry: SCNPlane(width: CGFloat(photoWidth), height: CGFloat(photoHeight)))
            voiceNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: voicePhotoOff)
            // Calculate position
            voiceNode.position = SCNVector3(x,0,z)
            // Calculate rotation
            voiceNode.eulerAngles = SCNVector3(0, (90.degreesToRadians - radianInc*CGFloat(index)), 0)
            SetCategoryMask(node: voiceNode, mask: NodeTypes.photoVoice.rawValue)
            voiceNode.position = voiceNode.position - (voiceNode.worldFront * 0.01)
            
            // Add nodes to reel
            photoReelNodes.append(PhotoNode(photoName: photo, audioName: photoAudios[i+1], node: photoNode, voiceNode: voiceNode, isPlaying : false ))
            photoReel!.addChildNode(photoNode)
            photoReel!.addChildNode(voiceNode)
            photoReel!.addChildNode(backNode)
        }
        // Invisible sphere
        let cylinder = SCNNode(geometry:SCNCylinder(radius: 0.6+0.90, height: 0.4))
        cylinder.geometry?.firstMaterial?.diffuse.contents = UIColor.init(red:CGFloat(0.0),green:CGFloat(0.0),blue:CGFloat(0.0),alpha:CGFloat(0.0)).cgColor
        cylinder.geometry?.firstMaterial?.colorBufferWriteMask = SCNColorMask.alpha
        photoReel?.addChildNode(cylinder)
        SetCategoryMask(node: cylinder, mask: NodeTypes.photoReelSphere.rawValue)
        cylinder.position = SCNVector3(0,0,0)
    }
    
    /**
     Sets the material of a node with an image
     - parameters:
         - node: SCNNode for changing the material
         - name : String name of the UIImage
     - returns:
     */
    func changePhoto(node : SCNNode, name : String){
        node.geometry?.firstMaterial?.diffuse.contents = UIImage(named: name)
    }
    
    /**
     JATJ: Photoreel BUGS
     Sets the material of a node with an image
     - parameters:
     - node: SCNNode for changing the material
     - name : String name of the UIImage
     - returns:
     */
    func checkTurnPhotoReel(radians : Float){
        let resetRadian : Float = .pi
        let diff = abs(abs(radians) - resetRadian)
        if(diff < 0){return}
        let error = radiansPerPhoto * (1 - ((abs(radians) / radiansPerPhoto) - Float(Int(abs(radians) / radiansPerPhoto))))
        if(error > radiansError){ return }
        // Indexes for change photo
        var n : Int?
        var photoIndex : Int?
        var voiceIndex : Int?
        var indexPhotoReel : Int?
        // Get indexes
        if(self.actualDirectionOfPhotoDragged > 0 ){
            n = (Int(diff/radiansPerPhoto) + photosOffsetPositive)
            indexPhotoReel = (((n! - photosOffsetPositive)%photosLimit) + photosOffsetPositive) % photosLimit
            photoIndex = n!%photoNames.count
            voiceIndex = (photoIndex! + 1) % photoAudios.count
            print("PHOTO CHANGE +", radians, diff, error, n!, indexPhotoReel!, photoIndex!, voiceIndex!)
        }else{
            let diff = abs(radians - .pi)
            n = (Int(diff/radiansPerPhoto) + photosOffsetPositive)
            indexPhotoReel = (((n! - photosOffsetPositive)%photosLimit) + photosOffsetPositive) % photosLimit
            indexPhotoReel = (indexPhotoReel! != 0) ? photosLimit - indexPhotoReel! : 0
            photoIndex = (n!%photoNames.count != 0) ? photoNames.count - n!%photoNames.count : 0
            voiceIndex = (photoIndex! + 1) % photoAudios.count
            print("PHOTO CHANGE -", radians, diff, error, n!, indexPhotoReel!, photoIndex!, voiceIndex!)
        }
        changePhoto(node : photoReelNodes[indexPhotoReel!].node, name : photoNames[photoIndex!])
        photoReelNodes[indexPhotoReel!].audioName = photoAudios[voiceIndex!]
    }
    /**
     Changes audio icon to off in the photo reel
    */
    func setOffPhotoReel(){
        for (index, _) in photoReelNodes.enumerated(){
            photoReelNodes[index].voiceNode.geometry!.firstMaterial?.diffuse.contents = UIImage(named: voicePhotoOff)
            photoReelNodes[index].isPlaying = false
        }
    }
    /**
     Set on the audio icon on the photo node at index i
     - parameters:
        - i : Int index of the photo node in the photo nodes array
    */
    func setOnPhotoReel(i: Int){
        photoReelNodes[i].voiceNode.geometry!.firstMaterial?.diffuse.contents = UIImage(named: voicePhotoOn)
        photoReelNodes[i].isPlaying = true
    }
    
    // MARK: Atom
    // ############################## Atom ##############################
    /**
     Load the atom
     */
    func loadAtom(){
        let atomNode = LoadModel(folderName: "art.scnassets/atom", fileName: "atom", nodeName: "Atomo", recursively: false, ext: ".dae")!;
        atomNode.geometry?.firstMaterial?.isDoubleSided = true
        atomNode.position = SCNVector3(-1,-1,-1)
        SetCategoryMask(node: atomNode, mask: NodeTypes.atom.rawValue)
        self.sceneView.prepare(atomNode) { () -> Bool in
            return true
        }
        atom = atomNode
        loadAtomExplotion();
    }
    /**
     Load the atom exploding
     */
    func loadAtomExplotion(){
        let atomNode = LoadModel(folderName: "art.scnassets/atom", fileName: "AtomExplotion", nodeName: "AtomExplotion", recursively: false, ext: ".dae")!;
        atomNode.geometry?.firstMaterial?.isDoubleSided = true
        atomExploding = atomNode
    }
    
    /**
     Add the atom to the scene
     */
    func addAtom(){
        var atomInitialPosition = SCNVector3((workTable?.position.x)!, (workTable?.position.y)!,(workTable?.position.z)!)
        let atomOffset = SCNVector3(0.23, -0.8, 0)
        atomInitialPosition = (workTable?.position)! - atomOffset
        atom?.position = atomInitialPosition
        sceneView.scene.rootNode.addChildNode(atom!)
        atomResetPositions = atomResetPositionsR // Default
        /* JATJ: AtomFollow
        if(isCheckerTimerActive){
            checkerTimer = Timer.scheduledTimer(timeInterval: bezierInterval, target: self, selector: #selector(ViewController.atomCheck), userInfo: nil, repeats: true)
            print("STARTIN CHECKER TIMER 1346")
        }
        else{
            if(checkerTimer != nil){
                checkerTimer?.invalidate()
                checkerTimer = nil
            }
        }
         */
    }
    
    /**
     Makes atom check if need to follow the camera
     */
    @objc func atomCheck() {
        // Check if the atom is visible
        let isInScene = self.sceneView.isNode(atom!, insideFrustumOf: self.sceneView.pointOfView!)
        if (!isInScene && checkerTimer != nil){
            // Check if the atom is forced to follow at its position
            if(!forceFollow){
                // Check side of the atom
                let side = atom!.convertPosition(SCNVector3(0,0,0), to: referenceNode!).x
                if(side >= 0){
                    // Atom is on the right side
                    atomResetPositions = atomResetPositionsR
                }else{
                    // Atom is on the left side
                    atomResetPositions = atomResetPositionsL
                }
            }
            // move only if it has been tapped, otherwise keep in building position
            if (isAtomTapped){
                // Cancel checker timer
                checkerTimer!.invalidate()
                checkerTimer = nil
                // Delay the start of following
                tActual = 1.0
                Timer.scheduledTimer(timeInterval: 0, target: self, selector: #selector(ViewController.atomStartFollow), userInfo: nil, repeats: false)
            }
        }
    }
    
    /**
     Makes atom start follow the camera if atom is not in scene
     */
    @objc func atomStartFollow() {
        // Check again if the atom is in frustrum
        let isInScene = self.sceneView.isNode(atom!, insideFrustumOf: self.sceneView.pointOfView!)
        if (!isInScene && checkerTimer == nil){
            // Start of following
            atomResetPositions![4] = atom!.position
            bezierPoints[4] = atom!.position
            
            tActual = 1.0
            if(isBezierTimerActive && bezierTimer == nil){
                bezierTimer = Timer.scheduledTimer(timeInterval: bezierInterval, target: self, selector: #selector(ViewController.atomFollow), userInfo: nil, repeats: true)
                print("STARTIN BEZIER TIMER 1418")
            }
            else{
                if(bezierTimer != nil){
                    bezierTimer?.invalidate()
                    bezierTimer = nil
                }
            }
        }else{
            if isCheckerTimerActive {
                checkerTimer = Timer.scheduledTimer(timeInterval: bezierInterval, target: self, selector: #selector(ViewController.atomCheck), userInfo: nil, repeats: true)
                print("STARTING CHECKER TIMER")
            }
            else{
                if(checkerTimer != nil){
                    checkerTimer?.invalidate()
                    checkerTimer = nil
                    print("NOT STARTING CHECKER TIMER")
                }
            }
        }
    }
    
    /**
     Makes atom follow the camera
     */
    @objc func atomFollow() {
        // change bezier control points, and bezier inc
        bezierPoints[0] = referenceNode!.convertPosition(atomResetPositions![0], to: nil)
        bezierPoints[1] = referenceNode!.convertPosition(atomResetPositions![1], to: nil)
        bezierPoints[2] = referenceNode!.convertPosition(atomResetPositions![2], to: nil)
        bezierPoints[3] = referenceNode!.convertPosition(atomResetPositions![3], to: nil)
        
        // Move atom to the next step interval in the bezier curve
        atom!.runAction(SCNAction.move(to: bezierCurveAt(t: Float(tActual), controlPoints: bezierPoints), duration: bezierInterval))
        tActual = tActual - bezierInc
        if(tActual <= 0.0){
            // Atom reached its destination
            // Set to not force the follow
            forceFollow = false
            tActual = 1.0
            // Cancel bezier timer
            if (bezierTimer != nil){
                bezierTimer!.invalidate()
                bezierTimer = nil
            }
            // Restart checker timer
            if isCheckerTimerActive{
                checkerTimer = Timer.scheduledTimer(timeInterval: bezierInterval, target: self, selector: #selector(ViewController.atomCheck), userInfo: nil, repeats: true)
                print("STARTIN CHECKER TIMER 1426")
            }
            else{
                if(checkerTimer != nil){
                    checkerTimer?.invalidate()
                    checkerTimer = nil
                }
            }
        }
    }
    
    // MARK: Bezier
    // ############################## Bezier ##############################
    /**
     Calculate bezier coordinate for a whole curve at a given interval
     - parameters:
     - t : interval in the curve (0.0 - 1.0)
     - controlPoints : array with the control points of the bezier curve
     - returns:
     SCNVector3 with the point in the current interval (t) of the bezier curve
     */
    func bezierCurveAt(t: Float, controlPoints: [SCNVector3]) -> SCNVector3{
        var bezierPosition = SCNVector3(0,0,0)
        var i = 0
        for controlPoint in controlPoints {
            bezierPosition = bezierPosition.add(bezierPoint(t: t, N: controlPoints.count, K: i, v: controlPoint))
            i += 1
        }
        return bezierPosition
    }
    
    /**
     Calculate bezier coordinate for a point
     - parameters:
        - t : interval in the curve (0.0 - 1.0)
        - N : number of control points in bezier
        - K : index of the point (0 - N)
        - v : point coordinates
     - returns:
        SCNVector3 with the position affected by the given control point in the current interval
     */
    func bezierPoint(t: Float, N: Int, K: Int, v: SCNVector3) -> SCNVector3{
        return  v.multiply(binomialFactor(n : N, k : K) *  pow((1 - t), Float(N-K)) * pow(t,Float(K)))
    }
    
    // MARK: Helpers
    // ############################## Helpers ##############################
    /**
     Calculate the factorial of a number
     - parameters:
     - n : Number for factorial
     - returns:
     Int factorial of given n
     */
    func factorial(_ n: Int) -> Int {
        if n == 0 {
            return 1
        }
        else {
            return n * factorial(n - 1)
        }
    }
    /**
     Calculate the binomial factor
     - parameters:
     - n : Number for factorial
     - k : Number less than n
     - returns:
     Int binomial factor
     */
    func binomialFactor(n : Int, k : Int) -> Float{
        return Float((factorial(n))/(factorial(k) * factorial(n-k)))
    }
}

// MARK: Enums
// ############################## Enums ##############################
// Physics bit masks
enum NodeTypes: Int {
    case any =                  0b0000000000000001
    case atom =                 0b0000000000000010
    case photo =                0b0000000000000100
    case target =               0b0000000000001000
    case bullet =               0b0000000000010000
    case MLCDE =                0b0000000000100000
    case LCDE =                 0b0000000001000000
    case photoVoice =           0b0000000010000000
    case photoReelSphere =      0b0000000100000000
}

// MARK: Extensions
// ############################## Extensions ##############################
// Integers degrees to radians
extension Int {
    var degreesToRadians: CGFloat { return CGFloat(Int(self)) * .pi / 180 }
}
// Float degrees to radians
extension Float {
    var degreesToRadians: CGFloat { return CGFloat(Float(self)) * .pi / 180 }
    var radiansToDegrees: CGFloat { return CGFloat(Float(self)) * 180 / .pi }
}
// Check if node has for ancestor
extension SCNNode {
    func hasAncestor(_ node: SCNNode) -> Bool {
        if self === node {
            return true // this is the node you're looking for
        }
        if self.parent == nil {
            return false // target node can't be a parent/ancestor if we have no parent
        }
        if self.parent === node {
            return true // target node is this node's direct parent
        }
        // otherwise recurse to check parent's parent and so on
        return self.parent!.hasAncestor(node)
    }
    func hasAncestor(_ name: String) -> Bool {
        if self.name == name {
            return true // this is the node you're looking for
        }
        if self.parent == nil {
            return false // target node can't be a parent/ancestor if we have no parent
        }
        // otherwise recurse to check parent's parent and so on
        return self.parent!.hasAncestor(name)
    }
    func AncestorOfType(_ node: SCNNode) -> SCNNode? {
        if self === node {
            return self // this is the node you're looking for
        }
        if self.parent == nil {
            return nil // target node can't be a parent/ancestor if we have no parent
        }
        if self.parent === node {
            return self // target node is this node's direct parent
        }
        // otherwise recurse to check parent's parent and so on
        return self.parent!.AncestorOfType(node)
    }
}
// Return 3d point diference (direction vector)
extension SCNVector3 {
    func direction(_ origin: SCNVector3) -> SCNVector3 {
        return SCNVector3(self.x - origin.x,self.y - origin.y,self.z - origin.z)
    }
    func distanceTo(_ origin: SCNVector3) -> Float {
        return sqrt(pow(self.x - origin.x,2) + pow(self.y - origin.y,2) + pow(self.z - origin.z,2))
    }
    func multiply(_ v : Float) -> SCNVector3 {
        return SCNVector3(self.x*v, self.y*v, self.z*v)
    }
    func add(_ v : Float) -> SCNVector3 {
        return SCNVector3(self.x+v, self.y+v, self.z+v)
    }
    func substract(_ v : Float) -> SCNVector3 {
        return SCNVector3(self.x-v, self.y-v, self.z-v)
    }
    func multiply(_ v : SCNVector3) -> SCNVector3 {
        return SCNVector3(self.x*v.x, self.y*v.y, self.z*v.z)
    }
    func add(_ v : SCNVector3) -> SCNVector3 {
        return SCNVector3(self.x+v.x, self.y+v.y, self.z+v.z)
    }
    func substract(_ v : SCNVector3) -> SCNVector3 {
        return SCNVector3(self.x-v.x, self.y-v.y, self.z-v.z)
    }
    func dotProduct(_ v : SCNVector3) -> Float {
        return Float(self.x*v.x + self.y*v.y + self.z-v.z)
    }
    var magnitude : Float {
        return sqrt(pow(self.x, 2) + pow(self.y, 2) + pow(self.z, 2))
    }
    var normalized : SCNVector3 {
        return SCNVector3(self.x/self.magnitude, self.y/self.magnitude, self.z/self.magnitude)
    }
}
func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

func +(left: SCNVector3, right: Float) -> SCNVector3 {
    return SCNVector3Make(left.x + right, left.y + right, left.z + right)
}

func -(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}

func *(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x * right.x, left.y * right.y, left.z * right.z)
}

func *(left: SCNVector3, right: Float) -> SCNVector3 {
    return SCNVector3Make(left.x * right, left.y * right, left.z * right)
}

func *(quat : SCNQuaternion, vec : SCNVector3) -> SCNVector3{
    let num = quat.x * 2.0
    let num2 = quat.y * 2.0
    let num3 = quat.z * 2.0
    let num4 = quat.x * num
    let num5 = quat.y * num2
    let num6 = quat.z * num3
    let num7 = quat.x * num2
    let num8 = quat.x * num3
    let num9 = quat.y * num3
    let num10 = quat.w * num
    let num11 = quat.w * num2
    let num12 = quat.w * num3
    var result = SCNVector3()
    result.x = (1.0 - (num5 + num6)) * vec.x + (num7 - num12) * vec.y + (num8 + num11) * vec.z;
    result.y = (num7 + num12) * vec.x + (1.0 - (num4 + num6)) * vec.y + (num9 - num10) * vec.z;
    result.z = (num8 - num11) * vec.x + (num9 + num10) * vec.y + (1.0 - (num4 + num5)) * vec.z;
    return result
}


