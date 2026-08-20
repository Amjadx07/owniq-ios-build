# OWNIQ iOS Build Shell

Public build-only shell used to compile and physically test the OWNIQ iPhone client pipeline.

This repository intentionally excludes OWNIQ's private recognition engines, market-pricing logic, taxonomies, calibration data, intelligence packs, credentials, private endpoints, and other proprietary core logic.

The production/private source remains in a separate private repository.

## Build

GitHub Actions generates the Xcode project with XcodeGen, builds an unsigned `iphoneos` Release app, packages it as an unsigned IPA, and uploads the IPA as a workflow artifact.

## Rights

Copyright © 2026. All rights reserved. Public visibility does not grant a license to copy, modify, redistribute, sublicense, or commercially exploit this source code.
