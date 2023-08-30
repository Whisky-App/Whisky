# How to contribute

Thanks for your interest! First, make a fork of Whisky, make a new branch for your changes, and get coding!

# Build environment

Whisky is built using Xcode 15 on macOS Sonoma. All external dependencies are handled through the Swift Package Manager.

# Code style

Every Whisky commit is automatically linted using SwiftLint. You can run these checks locally simply by building in Xcode, violations will appear as errors or warnings. For your pull request to be merged, you must meet all the requirements outlined by SwiftLint and have no violations.

Generally, it is not advised to disable a SwiftLint rule, but there are certain situations where it is necessary. Please use your discretion when disabling rules temporarily.

SwiftLint does not fully check indentation, but we ask that you indent with 4-width spaces. This can be automatically configured in Xcode's settings.

All added strings must be properly localised and added to the EN strings file. Do not add keys for other languages or translate within your PR. All translations should be handled on [Crowdin](https://crowdin.com/project/whisky).

# Making your PR

Please provide a detailed description of your changes in your PR. If your commits contain UI changes, we ask that you provide screenshots.

# Review

Once your pull request passes CI SwiftLint checks and builds, it will be ready for review. You may receive feedback on code that should changed. Once you have received an approval, your code will be merged!
