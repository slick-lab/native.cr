
name: Bug Report
description: Report a bug in native.cr
title: "[BUG]: "
labels: ["bug", "triage"]
assignees: []

body:
  - type: markdown
    attributes:
      value: |
        Thanks for reporting a bug! Please fill out the information below.

  - type: input
    attributes:
      label: Native.cr Version
      description: Run `native.cr --version` and paste the output
      placeholder: "0.1.0"
    validations:
      required: true

  - type: dropdown
    attributes:
      label: Platform
      description: Which platform are you targeting?
      options:
        - Android
        - iOS
        - Both
    validations:
      required: true

  - type: input
    attributes:
      label: Crystal Version
      description: Run `crystal --version`
    validations:
      required: true

  - type: textarea
    attributes:
      label: Description
      description: A clear description of what the bug is
    validations:
      required: true

  - type: textarea
    attributes:
      label: Steps to Reproduce
      description: Steps to reproduce the behavior
      placeholder: |
        1. Run `native.cr create test_app`
        2. Change X in file Y
        3. Run `native.cr build android`
        4. See error
    validations:
      required: true

  - type: textarea
    attributes:
      label: Expected Behavior
      description: What you expected to happen
    validations:
      required: true

  - type: textarea
    attributes:
      label: Actual Behavior
      description: What actually happened
    validation:
      required: true

  - type: textarea
    attributes:
      label: Logs/Output
      description: Paste any relevant logs or error messages
      render: shell

  - type: textarea
    attributes:
      label: Additional Context
      description: Any other information that might help
