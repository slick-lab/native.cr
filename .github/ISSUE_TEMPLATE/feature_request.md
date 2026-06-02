# .github/ISSUE_TEMPLATE/feature_request.md

name: Feature Request
description: Suggest an idea for native.cr
title: "[FEATURE]: "
labels: ["enhancement"]
assignees: []

body:
  - type: markdown
    attributes:
      value: |
        Thanks for suggesting a feature! Please describe what you'd like to see.

  - type: dropdown
    attributes:
      label: Is this feature platform-specific?
      options:
        - Both Android and iOS
        - Android only
        - iOS only
        - Desktop only
    validations:
      required: true

  - type: textarea
    attributes:
      label: Problem Statement
      description: Is your feature request related to a problem? Please describe.
      placeholder: "I'm always frustrated when..."
    validations:
      required: true

  - type: textarea
    attributes:
      label: Proposed Solution
      description: Describe the solution you'd like
    validations:
      required: true

  - type: textarea
    attributes:
      label: Alternatives Considered
      description: Describe alternatives you've considered

  - type: textarea
    attributes:
      label: Example API
      description: Show how developers would use this feature
      placeholder: |
        ```crystal
        # Example code here
        ```
    validations:
      required: true

  - type: dropdown
    attributes:
      label: Would you be willing to contribute this feature?
      options:
        - "Yes"
        - "No"
        - "Maybe, need guidance"
