import AVFoundation
import SwiftUI
import UIKit

struct CameraPreview: UIViewRepresentable {
    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.start()
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {}
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

    private func configureAndStart() {
        session.beginConfiguration()
        session.sessionPreset = .high

        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .front
        )

        guard
            let device = discovery.devices.first,
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }

        session.addInput(input)
        session.commitConfiguration()

        DispatchQueue.main.async { [weak self] in
            guard let connection = self?.previewLayer.connection else { return }
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }

        session.startRunning()
    }
}
