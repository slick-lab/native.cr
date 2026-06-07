
---
title: Installation
description: Add native.cr to your Crystal project
---

# Installation

## For Crystal Developers

Add native.cr to your `shard.yml`:

```yaml
dependencies:
  native.cr:
    github: slick-lab/native.cr
    version: ~> 0.1.0
```

Then install:

```bash
shards install
```

That's it. native.cr is now available in your project.

## For Non-Crystal Users

If you just want to use the CLI tool without a Crystal project:

```bash
git clone https://github.com/slick-lab/native.cr
cd native.cr
shards install
shards build
sudo cp bin/native.cr /usr/local/bin/native.cr
```

Verify Installation

```bash
native.cr --version
```

Platform Dependencies

For Android Development

You need the Android NDK:

```bash
# macOS
brew install android-ndk

# Linux
wget https://dl.google.com/android/repository/android-ndk-r25c-linux.zip
unzip android-ndk-r25c-linux.zip -d ~/
export ANDROID_NDK_HOME=~/android-ndk-r25c
```

For iOS Development (macOS only)

Install Xcode from the App Store.

Next Steps

- hello - world
