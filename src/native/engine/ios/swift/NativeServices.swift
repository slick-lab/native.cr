// src/native/engine/ios/swift/NativeServices.swift
//
// native.cr iOS runtime — services: HTTP, websockets, file storage,
// user defaults, notifications, payments, biometrics, location, sensors,
// image picker.
//
// Part of the LibIOS C ABI implementation (see ios_bindings.cr).

import Foundation
import UIKit
import WebKit
import UserNotifications
import LocalAuthentication
import CoreLocation
import CoreMotion
import StoreKit

// ── HTTP (synchronous via semaphore — Crystal calls from the main contract) ──

struct NativeHTTPRequest {
    var url: String
    var method: String
    var headers: [String: String]
    var body: String
    var timeout: Double
}

func buildRequest(_ r: NativeHTTPRequest) -> URLRequest? {
    guard let url = URL(string: r.url) else { return nil }
    var req = URLRequest(url: url, timeoutInterval: r.timeout)
    req.httpMethod = r.method
    r.headers.forEach { req.setValue($1, forHTTPHeaderField: $0) }
    if !r.body.isEmpty { req.httpBody = r.body.data(using: .utf8) }
    return req
}

@_cdecl("http_request")
public func http_request(_ url: UnsafePointer<UInt8>?, _ method: UnsafePointer<UInt8>?,
                         _ headersJson: UnsafePointer<UInt8>?, _ body: UnsafePointer<UInt8>?,
                         _ timeout: Double) -> UnsafeMutablePointer<UInt8>? {
    var headers: [String: String] = [:]
    if let data = swiftStr(headersJson).data(using: .utf8),
       let obj = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
        headers = obj
    }
    let urlStr = swiftStr(url)
    guard let u = URL(string: urlStr) else { return nil }
    var request = URLRequest(url: u, timeoutInterval: timeout)
    request.httpMethod = swiftStr(method)
    headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
    let bodyStr = swiftStr(body)
    if !bodyStr.isEmpty { request.httpBody = bodyStr.data(using: .utf8) }

    let sem = DispatchSemaphore(value: 0)
    var payload: Data?
    var statusCode = 0
    var failed = false
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let http = response as? HTTPURLResponse { statusCode = http.statusCode }
        payload = data
        failed = (error != nil)
        sem.signal()
    }.resume()
    _ = sem.wait(timeout: .now() + timeout + 2)

    guard !failed, let data = payload else { return nil }
    // Envelope consumed by Network::HTTPClient#parse_response_json.
    let dict: [String: Any] = [
        "status": statusCode,
        "body": String(data: data, encoding: .utf8) ?? "",
        "success": (200..<300).contains(statusCode)
    ]
    guard let out = try? JSONSerialization.data(withJSONObject: dict),
          let str = String(data: out, encoding: .utf8) else { return nil }
    return retStr(str)
}

@_cdecl("http_request_stream")
public func http_request_stream(_ url: UnsafePointer<UInt8>?, _ method: UnsafePointer<UInt8>?,
                                _ headersJson: UnsafePointer<UInt8>?, _ body: UnsafePointer<UInt8>?,
                                _ timeout: Double) {
    // Fire-and-forget streaming: the framework's iOS stream path ignores the
    // response for now (the Android bridge delivers via callback objects —
    // that lands with the widget callback bridge).
    var headers: [String: String] = [:]
    if let data = swiftStr(headersJson).data(using: .utf8),
       let obj = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
        headers = obj
    }
    let req = NativeHTTPRequest(url: swiftStr(url), method: swiftStr(method),
                               headers: headers, body: swiftStr(body), timeout: timeout)
    guard let request = buildRequest(req) else { return }
    URLSession.shared.dataTask(with: request).resume()
}

// ── WebSockets ───────────────────────────────────────────────────────────────

final class NativeWebSocket: NSObject, URLSessionWebSocketDelegate {
    var task: URLSessionWebSocketTask?
    var onText: ((String) -> Void)?
    var onBinary: ((Data) -> Void)?

    func connect(_ url: String) {
        guard let u = URL(string: url) else { return }
        task = URLSession.shared.webSocketTask(with: u)
        task?.resume()
        receiveLoop()
    }

    private func receiveLoop() {
        task?.receive { [weak self] result in
            switch result {
            case .success(let msg):
                switch msg {
                case .string(let s): self?.onText?(s)
                case .data(let d): self?.onBinary?(d)
                @unknown default: break
                }
                self?.receiveLoop()
            case .failure: break
            }
        }
    }
}

let sharedWebSocket = NativeWebSocket()

@_cdecl("websocket_connect")
public func websocket_connect(_ url: UnsafePointer<UInt8>?) { sharedWebSocket.connect(swiftStr(url)) }

@_cdecl("websocket_send_text")
public func websocket_send_text(_ text: UnsafePointer<UInt8>?) {
    sharedWebSocket.task?.send(.string(swiftStr(text))) { _ in }
}

@_cdecl("websocket_send_binary")
public func websocket_send_binary(_ data: UnsafePointer<UInt8>?, _ size: Int32) {
    guard let data = data, size > 0 else { return }
    sharedWebSocket.task?.send(.data(Data(bytes: data, count: Int(size)))) { _ in }
}

@_cdecl("websocket_close")
public func websocket_close() { sharedWebSocket.task?.cancel(with: .normalClosure, reason: nil) }

// ── File storage (0 = documents, 1 = cache, 2 = temp per StorageType) ───────

func storageDir(_ type: Int32) -> URL {
    let base: URL
    switch type {
    case 1: base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    case 2: base = URL(fileURLWithPath: NSTemporaryDirectory())
    default: base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    return base
}

@_cdecl("file_write")
public func file_write(_ name: UnsafePointer<UInt8>?, _ data: UnsafePointer<UInt8>?,
                       _ size: Int32, _ type: Int32) -> Bool {
    guard let name = name, let data = data, size >= 0 else { return false }
    let url = storageDir(type).appendingPathComponent(String(cString: UnsafeRawPointer(name).assumingMemoryBound(to: CChar.self)))
    return FileManager.default.createFile(atPath: url.path, contents: Data(bytes: data, count: Int(size)))
}

@_cdecl("file_read")
public func file_read(_ name: UnsafePointer<UInt8>?, _ sizePtr: UnsafeMutablePointer<Int32>?,
                      _ type: Int32) -> UnsafeMutablePointer<UInt8>? {
    guard let name = name else { return nil }
    let url = storageDir(type).appendingPathComponent(String(cString: UnsafeRawPointer(name).assumingMemoryBound(to: CChar.self)))
    guard let data = try? Data(contentsOf: url) else {
        sizePtr?.pointee = 0
        return nil
    }
    let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
    data.copyBytes(to: buf, count: data.count)
    sizePtr?.pointee = Int32(data.count)
    return buf
}

@_cdecl("file_exists")
public func file_exists(_ name: UnsafePointer<UInt8>?, _ type: Int32) -> Bool {
    guard let name = name else { return false }
    let url = storageDir(type).appendingPathComponent(String(cString: UnsafeRawPointer(name).assumingMemoryBound(to: CChar.self)))
    return FileManager.default.fileExists(atPath: url.path)
}

@_cdecl("file_delete")
public func file_delete(_ name: UnsafePointer<UInt8>?, _ type: Int32) -> Bool {
    guard let name = name else { return false }
    let url = storageDir(type).appendingPathComponent(String(cString: UnsafeRawPointer(name).assumingMemoryBound(to: CChar.self)))
    do { try FileManager.default.removeItem(at: url); return true } catch { return false }
}

@_cdecl("file_list")
public func file_list(_ directory: UnsafePointer<UInt8>?, _ type: Int32) -> UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>? {
    let dir = storageDir(type).appendingPathComponent(swiftStr(directory))
    let names = (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
    let arr = UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>.allocate(capacity: names.count + 1)
    for (i, n) in names.enumerated() { arr[i] = retStr(n) }
    arr[names.count] = nil // NULL-terminated; Crystal stops on the first null
    return arr
}

// ── User defaults (SharedPreferences equivalent) ─────────────────────────────

@_cdecl("user_defaults_get")
public func user_defaults_get(_ key: UnsafePointer<UInt8>?) -> UnsafeMutablePointer<UInt8>? {
    let v = UserDefaults.standard.string(forKey: swiftStr(key))
    return retStr(v ?? "")
}

@_cdecl("user_defaults_set")
public func user_defaults_set(_ key: UnsafePointer<UInt8>?, _ value: UnsafePointer<UInt8>?) {
    UserDefaults.standard.set(swiftStr(value), forKey: swiftStr(key))
}

@_cdecl("user_defaults_delete")
public func user_defaults_delete(_ key: UnsafePointer<UInt8>?) {
    UserDefaults.standard.removeObject(forKey: swiftStr(key))
}

@_cdecl("user_defaults_contains")
public func user_defaults_contains(_ key: UnsafePointer<UInt8>?) -> Bool {
    UserDefaults.standard.object(forKey: swiftStr(key)) != nil
}

@_cdecl("user_defaults_clear")
public func user_defaults_clear() {
    if let domain = Bundle.main.bundleIdentifier {
        UserDefaults.standard.removePersistentDomain(forName: domain)
    }
}

@_cdecl("user_defaults_all_keys")
public func user_defaults_all_keys() -> UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>? {
    let keys = Array(UserDefaults.standard.dictionaryRepresentation().keys)
    let arr = UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>.allocate(capacity: keys.count + 1)
    for (i, k) in keys.enumerated() { arr[i] = retStr(k) }
    arr[keys.count] = nil
    return arr
}

// ── Notifications ────────────────────────────────────────────────────────────

@_cdecl("notification_init")
public func notification_init() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
}

@_cdecl("notification_permission_granted")
public func notification_permission_granted() -> Bool { permissionGrantedFlag }

@_cdecl("request_notification_permission")
public func request_notification_permission() -> Bool {
    var granted = false
    let sem = DispatchSemaphore(value: 0)
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { ok, _ in
        granted = ok
        permissionGrantedFlag = ok
        sem.signal()
    }
    _ = sem.wait(timeout: .now() + 5)
    return granted
}

var permissionGrantedFlag = false

@_cdecl("show_notification")
public func show_notification(_ id: Int32, _ title: UnsafePointer<UInt8>?, _ body: UnsafePointer<UInt8>?,
                              _ badge: Int32, _ sound: UnsafePointer<UInt8>?, _ payload: UnsafePointer<UInt8>?) -> Bool {
    let content = UNMutableNotificationContent()
    content.title = swiftStr(title)
    content.body = swiftStr(body)
    if badge > 0 { content.badge = NSNumber(value: Int(badge)) }
    content.userInfo = ["payload": swiftStr(payload)]
    if !swiftStr(sound).isEmpty { content.sound = .default }
    let req = UNNotificationRequest(identifier: "nativecr_\(id)", content: content, trigger: nil)
    var ok = true
    let sem = DispatchSemaphore(value: 0)
    UNUserNotificationCenter.current().add(req) { err in ok = (err == nil); sem.signal() }
    _ = sem.wait(timeout: .now() + 2)
    return ok
}

@_cdecl("schedule_notification")
public func schedule_notification(_ id: Int32, _ title: UnsafePointer<UInt8>?, _ body: UnsafePointer<UInt8>?,
                                  _ triggerTime: Double, _ repeats: Bool, _ payload: UnsafePointer<UInt8>?) -> Bool {
    let content = UNMutableNotificationContent()
    content.title = swiftStr(title)
    content.body = swiftStr(body)
    content.userInfo = ["payload": swiftStr(payload)]
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, triggerTime - Date().timeIntervalSince1970), repeats: repeats)
    let req = UNNotificationRequest(identifier: "nativecr_\(id)", content: content, trigger: trigger)
    var ok = true
    let sem = DispatchSemaphore(value: 0)
    UNUserNotificationCenter.current().add(req) { err in ok = (err == nil); sem.signal() }
    _ = sem.wait(timeout: .now() + 2)
    return ok
}

@_cdecl("cancel_notification")
public func cancel_notification(_ id: Int32) {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["nativecr_\(id)"])
    UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["nativecr_\(id)"])
}

@_cdecl("cancel_all_notifications")
public func cancel_all_notifications() {
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
}

@_cdecl("set_badge_number")
public func set_badge_number(_ count: Int32) {
    DispatchQueue.main.async { UIApplication.shared.applicationIconBadgeNumber = Int(count) }
}

// ── Payments (StoreKit) ──────────────────────────────────────────────────────

@_cdecl("payment_init")
public func payment_init(_ merchantId: UnsafePointer<UInt8>?) { /* StoreKit needs no init on modern iOS */ }

@_cdecl("payment_purchase")
public func payment_purchase(_ productId: UnsafePointer<UInt8>?) {
    let id = swiftStr(productId)
    SKPaymentQueue.default().add(SKPayment(productIdentifier: id))
}

@_cdecl("payment_is_purchased")
public func payment_is_purchased(_ productId: UnsafePointer<UInt8>?) -> Bool {
    purchasedIds.contains(swiftStr(productId))
}

@_cdecl("payment_is_subscription_active")
public func payment_is_subscription_active(_ productId: UnsafePointer<UInt8>?) -> Bool {
    subscriptionIds.contains(swiftStr(productId))
}

var purchasedIds: Set<String> = []
var subscriptionIds: Set<String> = []

@_cdecl("payment_fetch_products")
public func payment_fetch_products(_ idsJson: UnsafePointer<UInt8>?) -> UnsafeMutablePointer<UInt8>? {
    let ids = swiftStr(idsJson)
        .trimmingCharacters(in: CharacterSet(charactersIn: "[]\""))
        .split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
    let sem = DispatchSemaphore(value: 0)
    var resultJSON = "{}"
    let delegate = ProductsFetchDelegate { products in
        let arr: [[String: Any]] = products.map {
            ["id": $0.productIdentifier, "title": $0.localizedTitle,
             "price": $0.price.doubleValue, "currency": $0.priceLocale.currencyCode ?? ""]
        }
        if let out = try? JSONSerialization.data(withJSONObject: arr),
           let str = String(data: out, encoding: .utf8) { resultJSON = str }
        sem.signal()
    }
    activeProductsDelegate = delegate
    let request = SKProductsRequest(productIdentifiers: Set(ids))
    request.delegate = delegate
    activeProductsRequest = request
    request.start()
    _ = sem.wait(timeout: .now() + 8)
    return retStr(resultJSON)
}

var activeProductsDelegate: ProductsFetchDelegate?
var activeProductsRequest: SKProductsRequest?

final class ProductsFetchDelegate: NSObject, SKProductsRequestDelegate {
    private let done: ([SKProduct]) -> Void
    init(done: @escaping ([SKProduct]) -> Void) { self.done = done }
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        done(response.products)
    }
    func request(_ request: SKProductsRequest, didFailWithError error: Error) {
        done([])
    }
}

@_cdecl("payment_restore")
public func payment_restore() {
    SKPaymentQueue.default().restoreCompletedTransactions()
}

// ── Biometrics ───────────────────────────────────────────────────────────────

@_cdecl("is_biometric_enrolled")
public func is_biometric_enrolled() -> Bool {
    let ctx = LAContext()
    var err: NSError?
    return ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
}

/// 1 = fingerprint (Touch ID), 2 = face (Face ID), 0 = none.
@_cdecl("get_biometric_type")
public func get_biometric_type() -> Int32 {
    let ctx = LAContext()
    var err: NSError?
    guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else { return 0 }
    switch ctx.biometryType {
    case .touchID: return 1
    case .faceID: return 2
    default: return 0
    }
}

/// Result codes match the framework's parse_result: 0 success, 1 cancel, 2 error.
@_cdecl("authenticate_biometric")
public func authenticate_biometric(_ title: UnsafePointer<UInt8>?, _ subtitle: UnsafePointer<UInt8>?,
                                   _ description: UnsafePointer<UInt8>?, _ cancelTitle: UnsafePointer<UInt8>?,
                                   _ fallbackTitle: UnsafePointer<UInt8>?, _ allowFallback: Bool) -> Int32 {
    let ctx = LAContext()
    ctx.localizedCancelTitle = swiftStr(cancelTitle)
    if !swiftStr(fallbackTitle).isEmpty { ctx.localizedFallbackTitle = swiftStr(fallbackTitle) }
    var code: Int32 = 2
    let sem = DispatchSemaphore(value: 0)
    ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                       localizedReason: swiftStr(description)) { success, _ in
        code = success ? 0 : 1
        sem.signal()
    }
    _ = sem.wait(timeout: .now() + 60)
    return code
}

// ── Location ─────────────────────────────────────────────────────────────────

final class NativeLocation: NSObject, CLLocationManagerDelegate {
    static let shared = NativeLocation()
    let manager = CLLocationManager()
    var last: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func start(accuracy: Int32, minDistance: Float, minTime: Int64) {
        switch accuracy {
        case 0: manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        case 2: manager.desiredAccuracy = kCLLocationAccuracyBest
        case 3: manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        default: manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        }
        manager.distanceFilter = CLLocationDistance(minDistance)
        manager.startUpdatingLocation()
    }

    func stop() { manager.stopUpdatingLocation() }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        last = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { }

    func requestWhenInUse() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }
}

@_cdecl("location_start_updates")
public func location_start_updates(_ accuracy: Int32, _ minDistance: Float, _ minTime: Int64) {
    NativeLocation.shared.requestWhenInUse()
    NativeLocation.shared.start(accuracy: accuracy, minDistance: minDistance, minTime: minTime)
}

@_cdecl("location_stop_updates")
public func location_stop_updates() { NativeLocation.shared.stop() }

@_cdecl("location_get_last")
public func location_get_last() -> UnsafeMutablePointer<UInt8>? {
    guard let l = NativeLocation.shared.last else { return nil }
    let json = "{\"lat\":\(l.coordinate.latitude),\"lng\":\(l.coordinate.longitude),\"accuracy\":\(l.horizontalAccuracy),\"altitude\":\(l.altitude),\"speed\":\(max(0, l.speed)),\"ts\":\(l.timestamp.timeIntervalSince1970)}"
    return retStr(json)
}

// ── Sensors (CoreMotion) ─────────────────────────────────────────────────────

final class NativeSensorManager {
    let motion = CMMotionManager()
    var accelValues: [Double] = []
    var gyroValues: [Double] = []
    var magnetValues: [Double] = []
}

@_cdecl("sensor_manager_init")
public func sensor_manager_init() -> Int64 {
    let m = NativeSensorManager()
    return Int64(bitPattern: Int64(Int(bitPattern: Unmanaged.passRetained(m).toOpaque())))
}

@_cdecl("sensor_available")
public func sensor_available(_ type: Int32) -> Bool {
    let m = sharedSensorManager
    switch type {
    case 1: return m.motion.isAccelerometerAvailable
    case 2: return m.motion.isGyroAvailable
    case 3: return m.motion.isMagnetometerAvailable
    default: return false
    }
}

let sharedSensorManager = NativeSensorManager()

@_cdecl("sensor_start")
public func sensor_start(_ type: Int32, _ delayUs: Int32) {
    let m = sharedSensorManager.motion
    let interval = TimeInterval(max(0.001, Double(delayUs) / 1_000_000.0))
    if type == 1, m.isAccelerometerAvailable {
        m.accelerometerUpdateInterval = interval
        m.startAccelerometerUpdates(to: .main) { data, _ in
            guard let d = data else { return }
            sharedSensorManager.accelValues = [d.acceleration.x, d.acceleration.y, d.acceleration.z]
        }
    } else if type == 2, m.isGyroAvailable {
        m.gyroUpdateInterval = interval
        m.startGyroUpdates(to: .main) { data, _ in
            guard let d = data else { return }
            sharedSensorManager.gyroValues = [d.rotationRate.x, d.rotationRate.y, d.rotationRate.z]
        }
    } else if type == 3, m.isMagnetometerAvailable {
        m.magnetometerUpdateInterval = interval
        m.startMagnetometerUpdates(to: .main) { data, _ in
            guard let d = data else { return }
            sharedSensorManager.magnetValues = [d.magneticField.x, d.magneticField.y, d.magneticField.z]
        }
    }
}

@_cdecl("sensor_stop")
public func sensor_stop(_ type: Int32) {
    let m = sharedSensorManager.motion
    switch type {
    case 1: m.stopAccelerometerUpdates()
    case 2: m.stopGyroUpdates()
    case 3: m.stopMagnetometerUpdates()
    default: break
    }
}

// ── Clipboard (direct) ───────────────────────────────────────────────────────

@_cdecl("clipboard_set_text")
public func clipboard_set_text(_ text: UnsafePointer<UInt8>?) {
    UIPasteboard.general.string = swiftStr(text)
}

@_cdecl("clipboard_get_text")
public func clipboard_get_text() -> UnsafeMutablePointer<UInt8>? {
    retStr(UIPasteboard.general.string ?? "")
}

@_cdecl("clipboard_has_text")
public func clipboard_has_text() -> Bool {
    UIPasteboard.general.hasStrings
}

// ── Connectivity ─────────────────────────────────────────────────────────────

import Network

final class ConnectivityMonitor {
    static let shared = ConnectivityMonitor()
    let monitor = NWPathMonitor()
    var currentJSON = "{\"connected\":false,\"wifi\":false,\"cellular\":false,\"type\":\"none\"}"

    private init() {
        monitor.pathUpdateHandler = { path in
            let type = path.usesInterfaceType(.wifi) ? "wifi" : (path.usesInterfaceType(.cellular) ? "cellular" : (path.usesInterfaceType(.wiredEthernet) ? "ethernet" : "none"))
            self.currentJSON = "{\"connected\":\(path.status == .satisfied),\"wifi\":\(path.usesInterfaceType(.wifi)),\"cellular\":\(path.usesInterfaceType(.cellular)),\"type\":\"\(type)\"}"
        }
        monitor.start(queue: DispatchQueue.global(qos: .utility))
    }
}

@_cdecl("connectivity_get_info")
public func connectivity_get_info() -> UnsafeMutablePointer<UInt8>? {
    _ = ConnectivityMonitor.shared
    return retStr(ConnectivityMonitor.shared.currentJSON)
}

@_cdecl("connectivity_start_monitoring")
public func connectivity_start_monitoring() { _ = ConnectivityMonitor.shared }

@_cdecl("connectivity_stop_monitoring")
public func connectivity_stop_monitoring() { ConnectivityMonitor.shared.monitor.cancel() }

// ── Image picker ─────────────────────────────────────────────────────────────

final class ImagePickerDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    static var lastImagePath: String?

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let img = info[.originalImage] as? UIImage,
           let data = img.jpegData(compressionQuality: 0.9) {
            let path = NSTemporaryDirectory() + "nativecr_last_pick.jpg"
            try? data.write(to: URL(fileURLWithPath: path))
            ImagePickerDelegate.lastImagePath = path
        }
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

let imagePickerDelegate = ImagePickerDelegate()

@_cdecl("image_picker_pick")
public func image_picker_pick(_ source: Int32, _ quality: Int32,
                              _ maxWidth: Int32, _ maxHeight: Int32) {
    onMain {
        let picker = UIImagePickerController()
        picker.delegate = imagePickerDelegate
        picker.sourceType = source == 1 ? .camera : .photoLibrary
        topViewController()?.present(picker, animated: true)
    }
}

@_cdecl("image_picker_take_photo")
public func image_picker_take_photo(_ quality: Int32, _ maxWidth: Int32, _ maxHeight: Int32) {
    image_picker_pick(1, quality, maxWidth, maxHeight)
}
