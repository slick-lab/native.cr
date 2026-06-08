// src/native/engine/ios/ViewController.swift

import UIKit
import MetalKit

class ViewController: UIViewController {
    var crystalView: CrystalView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        crystalView = CrystalView(frame: view.bounds)
        crystalView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(crystalView!)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: view)
        crystal_touch_began(Float(point.x), Float(point.y))
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: view)
        crystal_touch_moved(Float(point.x), Float(point.y))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: view)
        crystal_touch_ended(Float(point.x), Float(point.y))
    }
}
