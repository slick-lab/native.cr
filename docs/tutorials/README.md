# Tutorials

Hands-on, sequential guides. Each one builds a working app and introduces
the framework surface you need at that step. Every snippet uses the real
native.cr API.

| # | Tutorial | You learn |
|---|----------|-----------|
| 1 | [Your First App](01-first-app.md) | Project layout, widgets, `on_click`, building for Android and iOS |
| 2 | [A Persistent To-Do List](02-todo-list.md) | Input, lists, `Native::Storage::Preferences` |
| 3 | [Talking to the Network](03-network-app.md) | `HTTP.get/post`, `Request`, JSON, form encoding, streaming |
| 4 | [A Touch-Driven Game](04-game.md) | `GameLoop`, touch overrides, `ValueAnimator`, `Sound` |

---

## How the tutorials build on each other

```
01 first app          — widgets + clicks
   └─> 02 to-do list  — adds input + persistence
         └─> 03 network — adds HTTP + JSON + forms
   └─> 04 game        — adds loop + touch + animation + audio
```

---

## Before you start

- Install the toolchain once: see [getting-started.md](../getting-started.md)
- Android needs the NDK; iOS needs a Mac with Xcode
- `native.cr doctor` verifies everything in one shot

## Where to go after

The module references are the next layer of depth: [ui-components.md](../ui-components.md),
[storage.md](../storage.md), [networking.md](../networking.md),
[image-picker.md](../image-picker.md), [animation.md](../animation.md),
[audio.md](../audio.md) and the rest of the [index](../README.md).
