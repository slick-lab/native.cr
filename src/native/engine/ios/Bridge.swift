// src/native/engine/ios/Bridge.swift

import Foundation

@_cdecl("crystal_init")
public func crystal_init() {
    // Crystal GC is initialized in the Crystal function
    // This is just a placeholder to satisfy the linker
}

@_cdecl("crystal_start")
public func crystal_start() {
    // Crystal app start is handled in Crystal function
}

@_cdecl("crystal_render_frame")
public func crystal_render_frame() {
    // Crystal render frame is handled in Crystal function
}

@_cdecl("crystal_touch_began")
public func crystal_touch_began(x: Float, y: Float) {
    // Crystal touch handler is in Crystal function
}

@_cdecl("crystal_touch_moved")
public func crystal_touch_moved(x: Float, y: Float) {
    // Crystal touch handler is in Crystal function
}

@_cdecl("crystal_touch_ended")
public func crystal_touch_ended(x: Float, y: Float) {
    // Crystal touch handler is in Crystal function
}
