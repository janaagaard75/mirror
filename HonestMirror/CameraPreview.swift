import AVFoundation
import SwiftUI
import UIKit

struct CameraPreview: UIViewRepresentable {
  let zoom: CGFloat

  func makeUIView(context: Context) -> CameraPreviewView {
    let view = CameraPreviewView()
    view.start()
    return view
  }

  func updateUIView(_ uiView: CameraPreviewView, context: Context) {
    uiView.setZoom(zoom)
  }
}

final class CameraPreviewView: UIView {
  override class var layerClass: AnyClass {
    AVCaptureVideoPreviewLayer.self
  }

  private var previewLayer: AVCaptureVideoPreviewLayer {
      layer as! AVCaptureVideoPreviewLayer
  }

  private let session = AVCaptureSession()
  private let sessionQueue = DispatchQueue(label: "mirror.camera.session")
  private var device: AVCaptureDevice?
  private let maximumZoom: CGFloat = 5.0
  private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
  private var rotationObservation: NSKeyValueObservation?

  func start() {
    previewLayer.videoGravity = .resizeAspectFill
    previewLayer.session = session

    switch AVCaptureDevice.authorizationStatus(for: .video) {
      case .authorized:
        sessionQueue.async { [weak self] in self?.configureAndStart() }
      case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
          guard granted, let self else { return }
          self.sessionQueue.async { self.configureAndStart() }
        }
      case .denied, .restricted:
        return
      @unknown default:
        return
    }
  }

  func setZoom(_ factor: CGFloat) {
    sessionQueue.async { [weak self] in
      guard let self, let device = self.device else { return }
      let maximumSupported = min(device.activeFormat.videoMaxZoomFactor, self.maximumZoom)
      let clamped = max(1.0, min(factor, maximumSupported))
      do {
        try device.lockForConfiguration()
        device.videoZoomFactor = clamped
        device.unlockForConfiguration()
      } catch {
        return
      }
    }
  }

  private func configureAndStart() {
    session.beginConfiguration()
    session.sessionPreset = .high

    let discovery = AVCaptureDevice.DiscoverySession(
      deviceTypes: [.builtInWideAngleCamera],
      mediaType: .video,
      position: .front
    )

    guard
      let frontCamera = discovery.devices.first,
      let input = try? AVCaptureDeviceInput(device: frontCamera),
      session.canAddInput(input)
    else {
      session.commitConfiguration()
      return
    }

    session.addInput(input)
    session.commitConfiguration()
    device = frontCamera

    DispatchQueue.main.async { [weak self] in
      guard let self, let connection = self.previewLayer.connection else { return }
      connection.automaticallyAdjustsVideoMirroring = false
      connection.isVideoMirrored = true

      // Only the iPad allows interface rotation. On iPhone the UI is locked to portrait, so the default preview rotation is already correct and we leave it untouched. On iPad, track the device so the preview stays upright as it rotates through all four orientations.
      guard UIDevice.current.userInterfaceIdiom == .pad else { return }
      let coordinator = AVCaptureDevice.RotationCoordinator(
        device: frontCamera, previewLayer: self.previewLayer
      )
      self.rotationCoordinator = coordinator
      self.applyPreviewRotation()
      self.rotationObservation = coordinator.observe(
        \.videoRotationAngleForHorizonLevelPreview, options: [.new]
      ) { [weak self] _, _ in
        DispatchQueue.main.async { self?.applyPreviewRotation() }
      }
    }

    session.startRunning()
  }

  private func applyPreviewRotation() {
    guard
      let coordinator = rotationCoordinator,
      let connection = previewLayer.connection
    else { return }
    let angle = coordinator.videoRotationAngleForHorizonLevelPreview
    if connection.isVideoRotationAngleSupported(angle) {
      connection.videoRotationAngle = angle
    }
  }
}
