# Introduction

Welcome to **native.cr** — the framework for building real native mobile apps with Crystal.

---

## What is native.cr?

native.cr is a mobile application framework that lets you write Android and iOS apps using the Crystal programming language. Unlike hybrid frameworks that run in a JavaScript bridge or web view, native.cr apps compile to native ARM64 code and use actual platform UI components.

**Your code talks directly to the operating system.**

```crystal
class CounterApp < Native::App
  @[Preserve]
  property count = 0

  def setup
    @label = Native::UI::TextView.new("Count: #{@count}")
    btn = Native::UI::Button.new("Increment")
    btn.on_click { increment }
    @root = layout
  end

  def increment
    @count += 1
    @label.text = "Count: #{@count}"
  end
end
```

---

## Why native.cr?

### Real Native Performance

Your Crystal code compiles to optimized ARM64 machine code. No interpreter, no JIT overhead, no JavaScript bridge. The performance is comparable to apps written in Swift or Kotlin.

### Platform UI Components

Widgets map directly to platform UI:

| native.cr Widget | Android | iOS |
|------------------|---------|-----|
| `TextView` | `TextView` | `UILabel` |
| `Button` | `Button` | `UIButton` |
| `EditText` | `EditText` | `UITextField` |
| `RecyclerView` | `RecyclerView` | `UITableView` |
| `WebView` | `WebView` | `WKWebView` |

Users get the look, feel, and behavior they expect from native apps.

### Crystal Language

Crystal combines Ruby-like syntax with C-like performance:

- Clean, readable syntax
- Type safety with type inference
- Compile-time error checking
- Zero-cost abstractions

### Hot Reload

During development, code changes appear instantly on your device. State is preserved across reloads using the `@[Preserve]` annotation.

### Small App Size

Apps typically ship at 2-5 MB — no massive JavaScript runtime, no bundled framework.

---

## Who Is This For?

native.cr is ideal for:

- **Mobile developers** who want performance without complexity
- **Backend developers** comfortable with Ruby-like syntax
- **Game developers** building 2D mobile games
- **Startups** needing fast iteration with native results
- **Teams** wanting a single codebase without web views

---

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                        Your Crystal Code                         │
│                     (app/main.cr, etc.)                         │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     native.cr Framework                          │
│          (UI, Storage, Network, Sensors, etc.)                   │
└─────────────────────────────────────────────────────────────────┘
                                │
                ┌───────────────┴───────────────┐
                ▼                               ▼
┌─────────────────────────────┐  ┌─────────────────────────────┐
│         Android             │  │            iOS              │
│   ┌─────────────────────┐   │  │   ┌─────────────────────┐   │
│   │   JNI Bridge        │   │  │   │   FFI Bridge        │   │
│   └─────────────────────┘   │  │   └─────────────────────┘   │
│   ┌─────────────────────┐   │  │   ┌─────────────────────┐   │
│   │   Android SDK       │   │  │   │   UIKit / Foundation│  │
│   └─────────────────────┘   │  │   └─────────────────────┘   │
└─────────────────────────────┘  └─────────────────────────────┘
```

**Android:** Crystal compiles to a shared library loaded by a minimal Java bootstrap. Your code calls Android SDK via JNI.

**iOS:** Crystal compiles directly into the app binary. Your code calls UIKit via FFI.

---

## Comparison

| Feature | native.cr | React Native | Flutter | Kotlin/Swift |
|---------|-----------|--------------|---------|--------------|
| Language | Crystal | JavaScript | Dart | Kotlin/Swift |
| UI | Native | Native (bridge) | Canvas | Native |
| Performance | Excellent | Good | Very Good | Excellent |
| App Size | 2-5 MB | 15-25 MB | 10-15 MB | 5-15 MB |
| Hot Reload | Yes | Yes | Yes | Limited |
| Learning Curve | Medium | Medium | Medium | Higher |
| Single Codebase | Yes | Yes | Yes | No |

---

## Next Steps

Ready to start building? Continue with:

- [Getting Started](getting-started.md) — Set up your environment
- [Core Concepts](core-concepts.md) — Understand the fundamentals
- [Tutorial: First App](tutorial.md) — Build your first app
