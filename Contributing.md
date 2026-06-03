
# Contributing to native.cr

First off, thank you for considering contributing to native.cr. This project exists because someone wanted Crystal to run on mobile devices. Now it needs people like you.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and constructive environment. Be kind, be clear, be helpful.

## How Can I Contribute?

### Reporting Bugs

Before creating a bug report:

- Check if the issue already exists in GitHub Issues
- Try the latest version of native.cr
- Collect information: Crystal version, OS, Android/iOS SDK versions

When creating a bug report:

```markdown
**Description:** Clear description of the bug
**Steps to reproduce:** 
1. native.cr create test_app
2. native.cr build android
3. See error

**Expected behavior:** What should happen
**Actual behavior:** What actually happens
**Logs:** Relevant error messages
**Environment:** 
- Crystal version: 1.20.0
- OS: macOS 15.0
- Android NDK: r25
```

Suggesting Features

Feature requests are welcome. Before suggesting:

- Check if the feature already exists
- Consider if the feature belongs in core or should be an external library

When suggesting a feature:

```markdown
**Problem:** What problem does this solve?
**Solution:** How should it work?
**API example:** Show Crystal code that users would write
**Platform impact:** Android, iOS, or both?
```

Pull Requests

1. Fork the repository
2. Create a feature branch: git checkout -b feature/my-feature
3. Make your changes
4. Run tests: make test
5. Format code: make format
6. Push and open a pull request

Development Setup

Prerequisites

```bash
# Crystal
brew install crystal

# Android (optional, for Android development)
brew install android-ndk

# iOS (optional, requires macOS)
# Install Xcode from App Store
```

Clone and Build

```bash
git clone https://github.com/slick-lab/native.cr
cd native.cr
make build
./.build/native.cr doctor
```

Running Tests

```bash
# Run all tests
make test

# Run specific test
crystal spec spec/framework_spec.cr

# Run specific test group
crystal spec spec/framework_spec.cr -t "Gesture"
```

Code Style

Crystal

- Use 2 spaces for indentation
- Maximum line length: 100 characters
- Use def method_name : ReturnType for return types
- Use @[Preserve] for state annotations
- Use {{ if flag?(:android) }} for platform-specific code

Example:

```crystal
class MyComponent < UI::View
  @[Preserve]
  property title : String = ""

  def draw(renderer : Void*) : Nil
    {{ if flag?(:android) }}
      draw_android(renderer)
    {{ else }}
      draw_ios(renderer)
    {{ end }}
  end

  private def draw_android(renderer : Void*) : Nil
    # Android-specific drawing
  end
end
```

C (Android Engine)

- Use snake_case for functions
- Use struct with _t suffix
- Prefix functions with native_cr_
- Keep functions small and focused

Objective-C (iOS Engine)

- Use standard Objective-C naming conventions
- Prefix classes with NativeCr
- Use properties instead of getter/setter methods

Project Structure

```
src/native/
├── core/              # Core runtime (don't change without discussion)
├── framework/         # User APIs (most contributions go here)
├── engine/            # Platform engines (C/Obj-C code)
│   ├── android/       # Android C engine
│   └── ios/           # iOS Obj-C engine
└── cli/               # CLI tools

spec/                  # Tests must cover new features
cli/                   # Shell scripts for project creation
assets/                # Images, logos, branding
```

Adding a New UI Component

1. Create src/native/framework/my_component.cr
2. Add tests in spec/framework_spec.cr
3. Add example in examples/ if appropriate
4. Update documentation

Template for new component:

```crystal
module Native
  module UI
    class MyComponent < View
      def initialize
        super
        @width = 100
        @height = 100
      end

      def draw(renderer : Void*) : Nil
        return unless @visible

        {{ if flag?(:android) }}
          # Android drawing code
        {{ elsif flag?(:ios) }}
          # iOS drawing code
        {{ end }}
      end
    end
  end
end
```

Adding a New Platform API

1. Add C function in src/native/engine/android/native.c
2. Add Obj-C method in src/native/engine/ios/
3. Add Crystal binding in src/native/engine/*/bridge.cr
4. Add Crystal wrapper in src/native/framework/my_api.cr

Commit Messages

Format: type(scope): description

Types:

- feat: New feature
- fix: Bug fix
- docs: Documentation
- style: Code style (formatting)
- refactor: Code change that neither fixes nor adds feature
- perf: Performance improvement
- test: Adding/fixing tests
- chore: Maintenance tasks

Examples:

```
feat(camera): add video recording support
fix(ios): prevent crash on Metal initialization
docs(readme): update installation instructions
```

Release Process

1. Update CHANGELOG.md
2. Update version in src/native.cr
3. Create pull request
4. After merge, tag release: git tag v0.1.0
5. Push tags: git push --tags
6. GitHub Actions creates release

Questions?

- Open an issue for bugs/features
- Join Discord for chat
- Email: dev@emailme.com

---

Again, thank you. This project exists because you care enough to help.

```
```
