# Mirror

Minimal iOS app that shows a full-screen, mirrored live preview of the front-facing camera. No buttons — just two gestures.

## Gestures

- **Tap** anywhere to toggle the fill light: white bars top and bottom plus maximum screen brightness, for using the device as a mirror in dim light.
- **Pinch** to zoom (up to 5×).

## Setup

The Xcode project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen   # one-time
xcodegen generate       # regenerate Mirror.xcodeproj after editing project.yml
open Mirror.xcodeproj
```

Camera access requires a physical device — the simulator does not provide a real front camera feed.
