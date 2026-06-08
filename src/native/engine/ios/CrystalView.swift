// src/native/engine/ios/CrystalView.swift

import UIKit
import MetalKit

class CrystalView: MTKView {
    var displayLink: CADisplayLink?
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device ?? MTLCreateSystemDefaultDevice())
        setupDisplayLink()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(renderFrame))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func renderFrame() {
        crystal_render_frame()
    }
}
