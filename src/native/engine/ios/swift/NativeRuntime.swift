// src/native/engine/ios/swift/NativeRuntime.swift
//
// native.cr iOS runtime — UI core.
//
// Implements the LibIOS C ABI (see src/native/engine/ios/ios_bindings.cr)
// for the view/widget/alert/animator surface. Compiled into the app target
// by the generated Xcode project; the Crystal static library calls these
// symbols directly.
//
// Handle model: handles are retained object pointers (Unmanaged.passRetained),
// passed to Crystal as int64 and resolved back with Unmanaged.fromOpaque.
// Widgets are intentionally immortal in v1 — they live as long as the app
// (Crystal currently never releases handles).
//
// Threading: Crystal calls arrive on the main thread (the bridge contract).
// UI entry points additionally funnel through onMain() so a stray background
// call can never corrupt UIKit state.

import UIKit
import WebKit
import AudioToolbox

// ── Helpers ──────────────────────────────────────────────────────────────────

@discardableResult
func onMain<T>(_ body: () -> T) -> T {
    if Thread.isMainThread { return body() }
    return DispatchQueue.main.sync { body() }
}

/// Copy a C string parameter into a Swift String.
func swiftStr(_ p: UnsafePointer<UInt8>?) -> String {
    guard let p = p else { return "" }
    return String(cString: UnsafeRawPointer(p).assumingMemoryBound(to: CChar.self))
}

/// Return a Swift String to Crystal as a malloc'd NUL-terminated UTF-8 C string.
/// Ownership transfers to the caller, which releases it with free_string.
func retStr(_ s: String) -> UnsafeMutablePointer<UInt8>? {
    guard let d = strdup(s) else { return nil }
    return UnsafeMutablePointer<UInt8>(OpaquePointer(d))
}

/// Resolve a Crystal int64 handle back to a retained object.
func resolve<T: AnyObject>(_ handle: Int64, as type: T.Type) -> T? {
    guard handle != 0,
          let p = UnsafeRawPointer(bitPattern: UInt(bitPattern: Int64(handle))) else { return nil }
    return Unmanaged<T>.fromOpaque(p).takeUnretainedValue()
}

/// Register a new object and hand its handle to Crystal (retain +1, immortal).
func retainHandle(_ obj: AnyObject) -> UnsafeMutableRawPointer {
    Unmanaged.passRetained(obj).toOpaque()
}

func color(_ r: Float, _ g: Float, _ b: Float, _ a: Float = 1.0) -> UIColor {
    UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(a))
}

// ── Animator ─────────────────────────────────────────────────────────────────

/// UIView.animate driver for Native::Animation::Animator.
/// NOTE: the current LibIOS ABI has no value channel (the Android path uses
/// ValueAnimator.ofFloat(start, end)); until the ABI grows one, animators
/// drive the attached update closure with 0→1 progress. The framework's iOS
/// bootstrap wires that closure to a view property.
final class NativeAnimator {
    var duration: Double = 0.3
    var repeatCount: Float = 1
    var running = false
    var onUpdate: ((Float) -> Void)?
    var playSequentially = false

    func start() {
        guard !running else { return }
        running = true
        let repeats = max(1, Int(repeatCount))
        var iteration = 0
        let block: (Bool) -> Void = { [weak self] _ in
            guard let self = self else { return }
            iteration += 1
            if iteration >= repeats {
                self.running = false
                return
            }
            self.runOnce(completion: block)
        }
        runOnce(completion: block)
    }

    private func runOnce(completion: @escaping (Bool) -> Void) {
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut]) {
            self.onUpdate?(1.0)
        } completion: { done in
            completion(done)
        }
    }
}

final class NativeAnimatorSet {
    var animators: [NativeAnimator] = []
    var sequentially = false

    func start() {
        animators.forEach { $0.start() }
    }
}

// ── Platform / app ───────────────────────────────────────────────────────────

@_cdecl("get_device_model")
public func get_device_model() -> UnsafeMutablePointer<UInt8>? {
    var sysinfo = utsname()
    uname(&sysinfo)
    let mirror = Mirror(reflecting: sysinfo.machine)
    let model = mirror.children.reduce(into: "") { acc, e in
        if let v = e.value as? Int8, v != 0 { acc.append(Character(UnicodeScalar(UInt8(bitPattern: UInt(v))))) }
    }
    return retStr(model.isEmpty ? "iOS" : model)
}

@_cdecl("get_os_version")
public func get_os_version() -> UnsafeMutablePointer<UInt8>? {
    retStr(UIDevice.current.systemVersion)
}

@_cdecl("get_screen_width")
public func get_screen_width() -> Int32 { Int32(UIScreen.main.bounds.width) }

@_cdecl("get_screen_height")
public func get_screen_height() -> Int32 { Int32(UIScreen.main.bounds.height) }

@_cdecl("get_screen_density")
public func get_screen_density() -> Float { Float(UIScreen.main.scale) }

@_cdecl("get_battery_level")
public func get_battery_level() -> Int32 {
    UIDevice.current.isBatteryMonitoringEnabled = true
    return Int32(UIDevice.current.batteryLevel * 100)
}

@_cdecl("is_charging")
public func is_charging() -> Bool {
    UIDevice.current.isBatteryMonitoringEnabled = true
    let s = UIDevice.current.batteryState
    return s == .charging || s == .full
}

@_cdecl("vibrate")
public func vibrate() {
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
}

@_cdecl("open_url")
public func open_url(_ url: UnsafePointer<UInt8>?) -> Bool {
    guard let u = URL(string: swiftStr(url)) else { return false }
    guard UIApplication.shared.canOpenURL(u) else { return false }
    UIApplication.shared.open(u)
    return true
}

@_cdecl("open_settings")
public func open_settings() {
    if let u = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(u)
    }
}

@_cdecl("share")
public func share(_ text: UnsafePointer<UInt8>?, _ url: UnsafePointer<UInt8>?,
                  _ title: UnsafePointer<UInt8>?, _ imagePath: UnsafePointer<UInt8>?,
                  _ imageData: UnsafePointer<UInt8>?, _ mimeType: UnsafePointer<UInt8>?) {
    onMain {
        var items: [Any] = []
        let t = swiftStr(text)
        if !t.isEmpty { items.append(t) }
        let u = swiftStr(url)
        if let ur = URL(string: u) { items.append(ur) }
        let path = swiftStr(imagePath)
        if !path.isEmpty, let img = UIImage(contentsOfFile: path) { items.append(img) }
        if let vc = topViewController() {
            vc.present(UIActivityViewController(activityItems: items, applicationActivities: nil), animated: true)
        }
    }
}

@_cdecl("show_toast")
public func show_toast(_ text: UnsafePointer<UInt8>?, _ duration: Double) {
    onMain {
        guard let host = topViewController() else { return }
        let label = UILabel()
        label.text = swiftStr(text)
        label.textColor = .white
        label.backgroundColor = UIColor(white: 0, alpha: 0.8)
        label.textAlignment = .center
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        let size = label.sizeThatFits(CGSize(width: UIScreen.main.bounds.width - 60, height: .greatestFiniteMagnitude))
        label.frame = CGRect(x: 30, y: UIScreen.main.bounds.height - 140,
                             width: size.width + 32, height: size.height + 20)
        host.view.addSubview(label)
        UIView.animate(withDuration: 0.3, delay: max(0.1, duration), options: [],
                       animations: { label.alpha = 0 }) { _ in label.removeFromSuperview() }
    }
}

func topViewController() -> UIViewController? {
    let keyWindow = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }.flatMap { $0.windows }
        .first { $0.isKeyWindow }
    var top = keyWindow?.rootViewController
    while let p = top?.presentedViewController { top = p }
    return top
}

// ── Checkbox model ───────────────────────────────────────────────────────────

/// UILabel-backed checkbox: UIKit has no boxed "checkbox with label" control,
/// so the runtime models it as a label + tap-to-toggle checkmark. Used for
/// both create_checkbox and create_radio_button (radio grouping lands with
/// the widget callback bridge).
final class UICheckboxProxy: UIControl {
    private let label = UILabel()
    var isChecked = false
    var onToggle: ((Bool) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
        render()
    }
    required init?(coder: NSCoder) { fatalError("unsupported") }

    @objc private func tapped() { setChecked(!isChecked) }

    func setChecked(_ v: Bool) {
        isChecked = v
        render()
        onToggle?(v)
    }

    func setText(_ t: String) {
        label.text = t
        render()
    }

    private func render() {
        let base = label.text?.replacingOccurrences(of: "☐ ", with: "").replacingOccurrences(of: "☑ ", with: "") ?? ""
        label.text = (isChecked ? "☑ " : "☐ ") + base
        label.sizeToFit()
    }
}

// ── Creators ─────────────────────────────────────────────────────────────────

@_cdecl("create_button")         public func create_button() -> UnsafeMutableRawPointer? { onMain { retainHandle(UIButton(type: .system)) } }
@_cdecl("create_label")          public func create_label() -> UnsafeMutableRawPointer? { onMain { retainHandle(UILabel()) } }
@_cdecl("create_checkbox")       public func create_checkbox() -> UnsafeMutableRawPointer? { onMain { retainHandle(UICheckboxProxy()) } }
@_cdecl("create_switch")         public func create_switch() -> UnsafeMutableRawPointer? { onMain { retainHandle(UISwitch()) } }
@_cdecl("create_radio_button")   public func create_radio_button() -> UnsafeMutableRawPointer? { onMain { retainHandle(UICheckboxProxy()) } }
@_cdecl("create_text_field")     public func create_text_field() -> UnsafeMutableRawPointer? { onMain { retainHandle(UITextField()) } }
@_cdecl("create_image_view")     public func create_image_view() -> UnsafeMutableRawPointer? { onMain { retainHandle(UIImageView()) } }
@_cdecl("create_progress_view")  public func create_progress_view() -> UnsafeMutableRawPointer? { onMain { retainHandle(UIProgressView(progressViewStyle: .default)) } }
@_cdecl("create_slider")         public func create_slider() -> UnsafeMutableRawPointer? { onMain { retainHandle(UISlider()) } }
@_cdecl("create_card_view")      public func create_card_view() -> UnsafeMutableRawPointer? { onMain { let v = UIView(); v.layer.cornerRadius = 12; return retainHandle(v) } }
@_cdecl("create_stack_view")     public func create_stack_view() -> UnsafeMutableRawPointer? { onMain { retainHandle(UIStackView()) } }
@_cdecl("create_scroll_view")    public func create_scroll_view() -> UnsafeMutableRawPointer? { onMain { retainHandle(UIScrollView()) } }
@_cdecl("create_table_view")     public func create_table_view() -> UnsafeMutableRawPointer? { onMain { retainHandle(UITableView()) } }
@_cdecl("create_picker_view")    public func create_picker_view() -> UnsafeMutableRawPointer? { onMain { retainHandle(UIPickerView()) } }
@_cdecl("create_web_view")       public func create_web_view() -> UnsafeMutableRawPointer? { onMain { retainHandle(WKWebView(frame: .zero)) } }
@_cdecl("create_navigation_bar") public func create_navigation_bar() -> UnsafeMutableRawPointer? { onMain { retainHandle(UINavigationBar()) } }
@_cdecl("create_animator")       public func create_animator() -> UnsafeMutableRawPointer? { retainHandle(NativeAnimator()) }
@_cdecl("create_animator_set")   public func create_animator_set() -> UnsafeMutableRawPointer? { retainHandle(NativeAnimatorSet()) }

// ── View base ────────────────────────────────────────────────────────────────

func view(_ h: Int64) -> UIView? { resolve(h, as: UIView.self) }

@_cdecl("view_set_position")
public func view_set_position(_ h: Int64, _ x: Int32, _ y: Int32) {
    onMain { view(h)?.frame.origin = CGPoint(x: CGFloat(x), y: CGFloat(y)) }
}

@_cdecl("view_set_size")
public func view_set_size(_ h: Int64, _ w: Int32, _ ht: Int32) {
    onMain { view(h)?.frame.size = CGSize(width: CGFloat(w), height: CGFloat(ht)) }
}

@_cdecl("view_set_visible")
public func view_set_visible(_ h: Int64, _ v: Bool) {
    onMain { view(h)?.isHidden = !v }
}

@_cdecl("view_set_enabled")
public func view_set_enabled(_ h: Int64, _ v: Bool) {
    onMain { view(h)?.isUserInteractionEnabled = v }
}

@_cdecl("view_set_tag")
public func view_set_tag(_ h: Int64, _ tag: UnsafePointer<UInt8>?) {
    onMain { view(h)?.accessibilityIdentifier = swiftStr(tag) }
}

@_cdecl("view_set_background_color")
public func view_set_background_color(_ h: Int64, _ r: Float, _ g: Float, _ b: Float, _ a: Float) {
    onMain { view(h)?.backgroundColor = color(r, g, b, a) }
}

// ── Label ────────────────────────────────────────────────────────────────────

@_cdecl("label_set_text")        public func label_set_text(_ h: Int64, _ t: UnsafePointer<UInt8>?) { onMain { (resolve(h, as: UILabel.self))?.text = swiftStr(t) } }
@_cdecl("label_set_text_color")  public func label_set_text_color(_ h: Int64, _ r: Float, _ g: Float, _ b: Float) { onMain { (resolve(h, as: UILabel.self))?.textColor = color(r, g, b) } }
@_cdecl("label_set_text_size")   public func label_set_text_size(_ h: Int64, _ s: Int32) { onMain { (resolve(h, as: UILabel.self))?.font = .systemFont(ofSize: CGFloat(s)) } }
@_cdecl("label_set_font")        public func label_set_font(_ h: Int64, _ f: UnsafePointer<UInt8>?) { onMain { (resolve(h, as: UILabel.self))?.fontName = swiftStr(f) } }
@_cdecl("label_set_max_lines")   public func label_set_max_lines(_ h: Int64, _ n: Int32) { onMain { (resolve(h, as: UILabel.self))?.numberOfLines = Int(n) } }

// ── Button ───────────────────────────────────────────────────────────────────

@_cdecl("button_set_text")              public func button_set_text(_ h: Int64, _ t: UnsafePointer<UInt8>?) { onMain { (resolve(h, as: UIButton.self))?.setTitle(swiftStr(t), for: .normal) } }
@_cdecl("button_set_text_color")        public func button_set_text_color(_ h: Int64, _ r: Float, _ g: Float, _ b: Float) { onMain { (resolve(h, as: UIButton.self))?.setTitleColor(color(r, g, b), for: .normal) } }
@_cdecl("button_set_text_size")         public func button_set_text_size(_ h: Int64, _ s: Int32) { onMain { (resolve(h, as: UIButton.self))?.titleLabel?.font = .systemFont(ofSize: CGFloat(s)) } }
@_cdecl("button_set_background_color")  public func button_set_background_color(_ h: Int64, _ r: Float, _ g: Float, _ b: Float) { onMain { (resolve(h, as: UIButton.self))?.backgroundColor = color(r, g, b) } }

// ── Checkbox / radio / switch ────────────────────────────────────────────────

@_cdecl("checkbox_set_text")       public func checkbox_set_text(_ h: Int64, _ t: UnsafePointer<UInt8>?) { onMain { (resolve(h, as: UICheckboxProxy.self))?.setText(swiftStr(t)) } }
@_cdecl("checkbox_set_checked")    public func checkbox_set_checked(_ h: Int64, _ v: Bool) { onMain { (resolve(h, as: UICheckboxProxy.self))?.setChecked(v) } }
@_cdecl("checkbox_is_checked")     public func checkbox_is_checked(_ h: Int64) -> Bool { onMain { (resolve(h, as: UICheckboxProxy.self))?.isChecked ?? false } }
@_cdecl("checkbox_set_text_color") public func checkbox_set_text_color(_ h: Int64, _ r: Float, _ g: Float, _ b: Float) { onMain { (resolve(h, as: UICheckboxProxy.self))?.tintColor = color(r, g, b) } }
@_cdecl("checkbox_set_text_size")  public func checkbox_set_text_size(_ h: Int64, _ s: Int32) { onMain { (resolve(h, as: UICheckboxProxy.self))?.transform = CGAffineTransform(scaleX: CGFloat(s) / 14.0, y: CGFloat(s) / 14.0) } }

@_cdecl("radio_button_set_text")       public func radio_button_set_text(_ h: Int64, _ t: UnsafePointer<UInt8>?) { checkbox_set_text(h, t) }
@_cdecl("radio_button_set_checked")    public func radio_button_set_checked(_ h: Int64, _ v: Bool) { checkbox_set_checked(h, v) }
@_cdecl("radio_button_is_checked")     public func radio_button_is_checked(_ h: Int64) -> Bool { checkbox_is_checked(h) }
@_cdecl("radio_button_set_text_color") public func radio_button_set_text_color(_ h: Int64, _ r: Float, _ g: Float, _ b: Float) { checkbox_set_text_color(h, r, g, b) }
@_cdecl("radio_button_set_text_size")  public func radio_button_set_text_size(_ h: Int64, _ s: Int32) { checkbox_set_text_size(h, s) }

@_cdecl("switch_set_on") public func switch_set_on(_ h: Int64, _ v: Bool) { onMain { (resolve(h, as: UISwitch.self))?.setOn(v, animated: true) } }
@_cdecl("switch_is_on")  public func switch_is_on(_ h: Int64) -> Bool { onMain { (resolve(h, as: UISwitch.self))?.isOn ?? false } }

// ── Text field ───────────────────────────────────────────────────────────────

@_cdecl("text_field_set_text")        public func text_field_set_text(_ h: Int64, _ t: UnsafePointer<UInt8>?) { onMain { (resolve(h, as: UITextField.self))?.text = swiftStr(t) } }
@_cdecl("text_field_set_placeholder") public func text_field_set_placeholder(_ h: Int64, _ t: UnsafePointer<UInt8>?) { onMain { (resolve(h, as: UITextField.self))?.placeholder = swiftStr(t) } }
@_cdecl("text_field_set_text_color")  public func text_field_set_text_color(_ h: Int64, _ r: Float, _ g: Float, _ b: Float) { onMain { (resolve(h, as: UITextField.self))?.textColor = color(r, g, b) } }
@_cdecl("text_field_set_text_size")   public func text_field_set_text_size(_ h: Int64, _ s: Int32) { onMain { (resolve(h, as: UITextField.self))?.font = .systemFont(ofSize: CGFloat(s)) } }
@_cdecl("text_field_set_input_type")  public func text_field_set_input_type(_ h: Int64, _ t: Int32) {
    // Matches the framework's InputType values (1 text, 2 number, 3 phone, 4 email, 5 password).
    onMain {
        guard let f = resolve(h, as: UITextField.self) else { return }
        switch t {
        case 2: f.keyboardType = .numberPad
        case 3: f.keyboardType = .phonePad
        case 4: f.keyboardType = .emailAddress
        case 5: f.isSecureTextEntry = true
        default: f.keyboardType = .default
        }
    }
}
@_cdecl("text_field_get_text") public func text_field_get_text(_ h: Int64) -> UnsafeMutablePointer<UInt8>? {
    onMain { retStr(resolve(h, as: UITextField.self)?.text ?? "") }
}

// ── Progress / slider ────────────────────────────────────────────────────────

@_cdecl("progress_view_set_progress") public func progress_view_set_progress(_ h: Int64, _ p: Int32, _ max: Int32) {
    onMain { (resolve(h, as: UIProgressView.self))?.progress = max > 0 ? Float(p) / Float(max) : 0 }
}
@_cdecl("progress_view_set_max") public func progress_view_set_max(_ h: Int64, _ m: Int32) { /* progress is normalized per-set */ }
@_cdecl("progress_view_set_indeterminate") public func progress_view_set_indeterminate(_ h: Int64, _ v: Bool) {
    onMain {
        guard let p = resolve(h, as: UIProgressView.self) else { return }
        p.progressViewStyle = v ? .bar : .default
        if v { p.setProgress(0, animated: false) }
    }
}

@_cdecl("slider_set_value") public func slider_set_value(_ h: Int64, _ p: Int32, _ max: Int32) {
    onMain { (resolve(h, as: UISlider.self))?.value = max > 0 ? Float(p) / Float(max) : 0 }
}
@_cdecl("slider_set_max") public func slider_set_max(_ h: Int64, _ m: Int32) { /* normalized */ }
@_cdecl("slider_get_value") public func slider_get_value(_ h: Int64) -> Float {
    onMain { (resolve(h, as: UISlider.self))?.value ?? 0 }
}

// ── Image view ───────────────────────────────────────────────────────────────

@_cdecl("image_view_set_resource") public func image_view_set_resource(_ h: Int64, _ id: Int32) {
    // Numeric resource ids are an Android concept; on iOS images come from the
    // bundle by name (set_path) or bytes (set_data).
}
@_cdecl("image_view_set_path") public func image_view_set_path(_ h: Int64, _ p: UnsafePointer<UInt8>?) {
    onMain { (resolve(h, as: UIImageView.self))?.image = UIImage(named: swiftStr(p)) ?? UIImage(contentsOfFile: swiftStr(p)) }
}
@_cdecl("image_view_set_data") public func image_view_set_data(_ h: Int64, _ data: UnsafePointer<UInt8>?, _ size: Int32) {
    guard let data = data, size > 0 else { return }
    let bytes = Data(bytes: data, count: Int(size))
    onMain { (resolve(h, as: UIImageView.self))?.image = UIImage(data: bytes) }
}
@_cdecl("image_view_set_scale_type") public func image_view_set_scale_type(_ h: Int64, _ t: Int32) {
    onMain {
        guard let iv = resolve(h, as: UIImageView.self) else { return }
        switch t {
        case 1: iv.contentMode = .scaleAspectFit
        case 2: iv.contentMode = .scaleAspectFill
        case 3: iv.contentMode = .center
        default: iv.contentMode = .scaleToFill
        }
    }
}
@_cdecl("image_view_set_alpha") public func image_view_set_alpha(_ h: Int64, _ a: Float) {
    onMain { (resolve(h, as: UIImageView.self))?.alpha = CGFloat(a) }
}

// ── Card / stack / scroll ────────────────────────────────────────────────────

@_cdecl("card_view_add_subview") public func card_view_add_subview(_ h: Int64, _ child: Int64) {
    onMain { view(h)?.addSubview(view(child) ?? UIView()) }
}
@_cdecl("card_view_remove_subview") public func card_view_remove_subview(_ h: Int64, _ child: Int64) {
    onMain { view(child)?.removeFromSuperview() }
}
@_cdecl("card_view_set_background_color") public func card_view_set_background_color(_ h: Int64, _ r: Float, _ g: Float, _ b: Float) {
    onMain { view(h)?.backgroundColor = color(r, g, b) }
}
@_cdecl("card_view_set_radius") public func card_view_set_radius(_ h: Int64, _ r: Float) {
    onMain { view(h)?.layer.cornerRadius = CGFloat(r) }
}
@_cdecl("card_view_set_elevation") public func card_view_set_elevation(_ h: Int64, _ e: Float) {
    onMain {
        guard let v = view(h) else { return }
        v.layer.shadowOpacity = min(1, e / 12)
        v.layer.shadowRadius = CGFloat(e)
        v.layer.shadowOffset = CGSize(width: 0, height: CGFloat(e) / 2)
    }
}

@_cdecl("stack_view_add_view") public func stack_view_add_view(_ h: Int64, _ child: Int64) {
    onMain { (resolve(h, as: UIStackView.self))?.addArrangedSubview(view(child) ?? UIView()) }
}
@_cdecl("stack_view_remove_view") public func stack_view_remove_view(_ h: Int64, _ child: Int64) {
    onMain {
        guard let s = resolve(h, as: UIStackView.self), let c = view(child) else { return }
        s.removeArrangedSubview(c)
        c.removeFromSuperview()
    }
}
@_cdecl("stack_view_remove_all_views") public func stack_view_remove_all_views(_ h: Int64) {
    onMain { (resolve(h, as: UIStackView.self))?.arrangedSubviews.forEach { $0.removeFromSuperview() } }
}
@_cdecl("stack_view_set_axis") public func stack_view_set_axis(_ h: Int64, _ axis: Int32) {
    // Matches the framework: 0 = vertical, 1 = horizontal.
    onMain { (resolve(h, as: UIStackView.self))?.axis = axis == 0 ? .vertical : .horizontal }
}
@_cdecl("stack_view_set_padding") public func stack_view_set_padding(_ h: Int64, _ l: Int32, _ t: Int32, _ r: Int32, _ b: Int32) {
    onMain {
        guard let s = resolve(h, as: UIStackView.self) else { return }
        s.isLayoutMarginsRelativeArrangement = true
        s.layoutMargins = UIEdgeInsets(top: CGFloat(t), left: CGFloat(l), bottom: CGFloat(b), right: CGFloat(r))
    }
}

@_cdecl("scroll_view_add_view") public func scroll_view_add_view(_ h: Int64, _ child: Int64) {
    onMain {
        guard let s = resolve(h, as: UIScrollView.self), let c = view(child) else { return }
        s.addSubview(c)
        s.contentSize = c.frame.size
    }
}
@_cdecl("scroll_view_remove_view") public func scroll_view_remove_view(_ h: Int64, _ child: Int64) {
    onMain { view(child)?.removeFromSuperview() }
}
@_cdecl("scroll_view_scroll_to") public func scroll_view_scroll_to(_ h: Int64, _ x: Int32, _ y: Int32, _ animated: Bool) {
    onMain { (resolve(h, as: UIScrollView.self))?.setContentOffset(CGPoint(x: CGFloat(x), y: CGFloat(y)), animated: animated) }
}
@_cdecl("scroll_view_scroll_to_bottom") public func scroll_view_scroll_to_bottom(_ h: Int64, _ animated: Bool) {
    onMain {
        guard let s = resolve(h, as: UIScrollView.self) else { return }
        s.setContentOffset(CGPoint(x: 0, y: max(0, s.contentSize.height - s.bounds.height)), animated: animated)
    }
}
@_cdecl("scroll_view_get_scroll_x") public func scroll_view_get_scroll_x(_ h: Int64) -> Int32 {
    onMain { Int32((resolve(h, as: UIScrollView.self))?.contentOffset.x ?? 0) }
}
@_cdecl("scroll_view_get_scroll_y") public func scroll_view_get_scroll_y(_ h: Int64) -> Int32 {
    onMain { Int32((resolve(h, as: UIScrollView.self))?.contentOffset.y ?? 0) }
}
@_cdecl("scroll_view_set_direction") public func scroll_view_set_direction(_ h: Int64, _ d: Int32) { /* UIScrollView is free-form */ }

// ── Table view (RecyclerView) ────────────────────────────────────────────────

@_cdecl("table_view_reload_data") public func table_view_reload_data(_ h: Int64) {
    onMain { (resolve(h, as: UITableView.self))?.reloadData() }
}
@_cdecl("table_view_scroll_to_row") public func table_view_scroll_to_row(_ h: Int64, _ pos: Int32, _ smooth: Bool) {
    onMain {
        guard let t = resolve(h, as: UITableView.self), pos >= 0 else { return }
        t.scrollToRow(at: IndexPath(row: Int(pos), section: 0), at: .none, animated: smooth)
    }
}
@_cdecl("table_view_set_delegate") public func table_view_set_delegate(_ h: Int64, _ delegate: Int64) { /* data source lands with the widget callback bridge */ }
@_cdecl("table_view_set_style") public func table_view_set_style(_ h: Int64, _ style: Int32) {
    onMain { (resolve(h, as: UITableView.self))?.separatorStyle = style == 0 ? .none : .singleLine }
}

// ── Picker view (Spinner) ────────────────────────────────────────────────────

final class PickerModel: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    static var assocKey: UInt8 = 0
    private let items: [String]
    init(items: [String]) { self.items = items }
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { items.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        items.indices.contains(row) ? items[row] : nil
    }
}

@_cdecl("picker_view_set_items") public func picker_view_set_items(_ h: Int64, _ items: UnsafePointer<UInt8>?) {
    onMain {
        guard let p = resolve(h, as: UIPickerView.self) else { return }
        let names = swiftStr(items).split(separator: "|").map(String.init)
        let model = PickerModel(items: names)
        p.dataSource = model
        p.delegate = model
        objc_setAssociatedObject(p, &PickerModel.assocKey, model, .OBJC_ASSOCIATION_RETAIN)
    }
}
@_cdecl("picker_view_set_selected") public func picker_view_set_selected(_ h: Int64, _ pos: Int32) {
    onMain { (resolve(h, as: UIPickerView.self))?.selectRow(Int(pos), inComponent: 0, animated: true) }
}
@_cdecl("picker_view_get_selected") public func picker_view_get_selected(_ h: Int64) -> Int32 {
    onMain { Int32((resolve(h, as: UIPickerView.self))?.selectedRow(inComponent: 0) ?? 0) }
}

// ── Web view ─────────────────────────────────────────────────────────────────

@_cdecl("web_view_load_url") public func web_view_load_url(_ h: Int64, _ url: UnsafePointer<UInt8>?) {
    onMain {
        guard let w = resolve(h, as: WKWebView.self), let u = URL(string: swiftStr(url)) else { return }
        w.load(URLRequest(url: u))
    }
}
@_cdecl("web_view_load_html") public func web_view_load_html(_ h: Int64, _ html: UnsafePointer<UInt8>?, _ base: UnsafePointer<UInt8>?) {
    onMain {
        guard let w = resolve(h, as: WKWebView.self) else { return }
        w.loadHTMLString(swiftStr(html), baseURL: URL(string: swiftStr(base)))
    }
}
@_cdecl("web_view_set_js_enabled") public func web_view_set_js_enabled(_ h: Int64, _ v: Bool) {
    onMain { (resolve(h, as: WKWebView.self))?.configuration.preferences.javaScriptEnabled = v }
}
@_cdecl("web_view_can_go_back") public func web_view_can_go_back(_ h: Int64) -> Bool { onMain { (resolve(h, as: WKWebView.self))?.canGoBack ?? false } }
@_cdecl("web_view_can_go_forward") public func web_view_can_go_forward(_ h: Int64) -> Bool { onMain { (resolve(h, as: WKWebView.self))?.canGoForward ?? false } }
@_cdecl("web_view_go_back") public func web_view_go_back(_ h: Int64) { onMain { (resolve(h, as: WKWebView.self))?.goBack() } }
@_cdecl("web_view_go_forward") public func web_view_go_forward(_ h: Int64) { onMain { (resolve(h, as: WKWebView.self))?.goForward() } }
@_cdecl("web_view_reload") public func web_view_reload(_ h: Int64) { onMain { (resolve(h, as: WKWebView.self))?.reload() } }
@_cdecl("web_view_stop_loading") public func web_view_stop_loading(_ h: Int64) { onMain { (resolve(h, as: WKWebView.self))?.stopLoading() } }

// ── Navigation bar ───────────────────────────────────────────────────────────

@_cdecl("navigation_bar_set_title") public func navigation_bar_set_title(_ h: Int64, _ t: UnsafePointer<UInt8>?) {
    onMain {
        guard let bar = resolve(h, as: UINavigationBar.self) else { return }
        if let item = bar.topItem {
            item.title = swiftStr(t)
        } else {
            bar.items = [UINavigationItem(title: swiftStr(t))]
        }
    }
}

// ── Alerts ───────────────────────────────────────────────────────────────────

final class NativeAlert {
    let controller: UIAlertController
    init() { controller = UIAlertController(title: nil, message: nil, preferredStyle: .alert) }
}

@_cdecl("create_alert_controller") public func create_alert_controller() -> UnsafeMutableRawPointer? { retainHandle(NativeAlert()) }
@_cdecl("alert_set_title") public func alert_set_title(_ h: Int64, _ t: UnsafePointer<UInt8>?) { onMain { (resolve(h, as: NativeAlert.self))?.controller.title = swiftStr(t) } }
@_cdecl("alert_set_message") public func alert_set_message(_ h: Int64, _ m: UnsafePointer<UInt8>?) { onMain { (resolve(h, as: NativeAlert.self))?.controller.message = swiftStr(m) } }

/// Action kinds match the framework: 0 = positive, 1 = negative, 2 = neutral.
@_cdecl("alert_add_action") public func alert_add_action(_ h: Int64, _ label: UnsafePointer<UInt8>?, _ kind: Int32) {
    onMain {
        guard let a = resolve(h, as: NativeAlert.self) else { return }
        a.controller.addAction(UIAlertAction(title: swiftStr(label), style: kind == 1 ? .destructive : .default) { _ in
            // Tap delivery lands with the widget callback bridge (see PR notes).
        })
    }
}
@_cdecl("alert_show") public func alert_show(_ h: Int64) {
    onMain {
        if let a = resolve(h, as: NativeAlert.self) {
            topViewController()?.present(a.controller, animated: true)
        }
    }
}
@_cdecl("alert_dismiss") public func alert_dismiss(_ h: Int64) {
    onMain { (resolve(h, as: NativeAlert.self))?.controller.dismiss(animated: true) }
}

// ── Animators ────────────────────────────────────────────────────────────────

@_cdecl("animator_start") public func animator_start(_ h: Int64) { (resolve(h, as: NativeAnimator.self))?.start() }
@_cdecl("animator_cancel") public func animator_cancel(_ h: Int64) { (resolve(h, as: NativeAnimator.self))?.running = false }
@_cdecl("animator_set_duration") public func animator_set_duration(_ h: Int64, _ d: Int32) { (resolve(h, as: NativeAnimator.self))?.duration = Double(d) / 1000.0 }
@_cdecl("animator_set_repeat_count") public func animator_set_repeat_count(_ h: Int64, _ n: Int32) { (resolve(h, as: NativeAnimator.self))?.repeatCount = Float(n) }
@_cdecl("animator_set_play_sequentially") public func animator_set_play_sequentially(_ h: Int64) { (resolve(h, as: NativeAnimatorSet.self))?.sequentially = true }
@_cdecl("animator_set_start") public func animator_set_start(_ h: Int64) { (resolve(h, as: NativeAnimatorSet.self))?.start() }
