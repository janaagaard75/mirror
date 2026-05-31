import AVFoundation
import SwiftUI
import UIKit

struct ContentView: View {
  let buttonSize = 64.0
  let buttonOffset = 2.0

  @Environment(\.scenePhase) private var scenePhase
  @State private var cameraAuthorization = AVCaptureDevice.authorizationStatus(for: .video)
  @State private var floodLightOn = false
  @State private var brightnessBeforeFlashlight: CGFloat = 0.5
  @State private var zoom: CGFloat = 1.0
  @State private var zoomAtGestureStart: CGFloat = 1.0

  private var currentScreen: UIScreen? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first(where: { $0.activationState == .foregroundActive })?
      .screen
  }

  var body: some View {
    Group {
      switch cameraAuthorization {
      case .authorized:
        mirror
      case .denied, .restricted:
        CameraAccessNeededView()
      case .notDetermined:
        Color.black.ignoresSafeArea()
      @unknown default:
        CameraAccessNeededView()
      }
    }
    .task {
      guard cameraAuthorization == .notDetermined else { return }
      let granted = await AVCaptureDevice.requestAccess(for: .video)
      cameraAuthorization = granted ? .authorized : .denied
    }
    .onChange(of: scenePhase) { _, phase in
      // Re-read the status when returning to the app, e.g. after the user
      // toggled camera access in Settings.
      if phase == .active {
        cameraAuthorization = AVCaptureDevice.authorizationStatus(for: .video)
      }
    }
  }

  private var mirror: some View {
    GeometryReader { geometry in
      ZStack {
        CameraPreview(zoom: zoom)
          .allowsHitTesting(false)
        VStack(spacing: 0) {
          Color.white
            .frame(height: geometry.size.height / 6)
            .opacity(floodLightOn ? 1 : 0)
          Spacer(minLength: 0)
          RectangleWithCircularCutout(
            cutoutRadius: buttonSize / 2,
            cutoutVerticalOffset: -buttonOffset
          )
          .fill(Color.white, style: FillStyle(eoFill: true))
          .frame(height: geometry.size.height / 6)
          .opacity(floodLightOn ? 1 : 0)
        }
        .allowsHitTesting(false)
        VStack {
          Spacer()
          Button {
            withAnimation(.easeInOut(duration: 0.2)) {
              floodLightOn.toggle()
            }
          } label: {
            Image(systemName: "bolt.fill")
              .font(.system(size: 28, weight: .semibold))
              .foregroundStyle(Color.white)
              .frame(width: buttonSize, height: buttonSize)
              .contentShape(Circle())
          }
          .buttonStyle(.plain)
          .glassEffect(.clear, in: Circle())
          .padding(.bottom, geometry.size.height / 12 - buttonSize / 2 + buttonOffset)
        }
      }
    }
    .ignoresSafeArea()
    .background(Color.black)
    .statusBarHidden()
    .persistentSystemOverlays(.hidden)
    .simultaneousGesture(
      MagnifyGesture()
        .onChanged { value in
          zoom = max(1.0, zoomAtGestureStart * value.magnification)
        }
        .onEnded { _ in
          zoomAtGestureStart = zoom
        }
    )
    .onChange(of: floodLightOn) { _, turnedOn in
      guard let screen = currentScreen else { return }
      if turnedOn {
        brightnessBeforeFlashlight = screen.brightness
        screen.brightness = 1.0
      } else {
        screen.brightness = brightnessBeforeFlashlight
      }
    }
  }
}

private struct CameraAccessNeededView: View {
  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      VStack(spacing: 24) {
        Image(systemName: "video.slash.fill")
          .font(.system(size: 56, weight: .regular))
          .foregroundStyle(Color.white)

        Text("Camera Access Needed")
          .font(.title2.weight(.semibold))
          .foregroundStyle(Color.white)

        Text("Mirror needs access to your camera to use the screen as a mirror. It can't work without access to the camera.")
          .multilineTextAlignment(.center)
          .foregroundStyle(Color.white.opacity(0.75))

        VStack(alignment: .leading, spacing: 8) {
          Label("Tap Open Settings below", systemImage: "1.circle.fill")
          Label("Turn on Camera", systemImage: "2.circle.fill")
        }
        .font(.callout)
        .foregroundStyle(Color.white.opacity(0.75))
        .padding(.top, 4)

        Button {
          guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
          UIApplication.shared.open(url)
        } label: {
          Text("Open Settings")
            .font(.headline)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.white)
        .glassEffect(.clear, in: Capsule())
        .padding(.top, 8)
      }
      .padding(40)
      .frame(maxWidth: 420)
    }
    .statusBarHidden()
    .persistentSystemOverlays(.hidden)
  }
}

private struct RectangleWithCircularCutout: Shape {
  let cutoutRadius: CGFloat
  let cutoutVerticalOffset: CGFloat

  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.addRect(rect)
    let center = CGPoint(x: rect.midX, y: rect.midY + cutoutVerticalOffset)
    path.addEllipse(
      in: CGRect(
        x: center.x - cutoutRadius,
        y: center.y - cutoutRadius,
        width: cutoutRadius * 2,
        height: cutoutRadius * 2
      )
    )
    return path
  }
}
