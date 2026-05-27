import SwiftUI
import UIKit

struct ContentView: View {
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
        GeometryReader { geometry in
            ZStack {
                CameraPreview(zoom: zoom)
                    .allowsHitTesting(false)
                VStack(spacing: 0) {
                    Color.white
                        .frame(height: geometry.size.height / 6)
                        .opacity(floodLightOn ? 1 : 0)
                    Spacer(minLength: 0)
                    Color.white
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
                            .frame(width: 64, height: 64)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .glassEffect(floodLightOn ? .clear.tint(Color(red: 0.5, green: 0.5, blue: 0.6)) : .clear, in: Circle())
                    .padding(.bottom, geometry.size.height / 12 - 32 + 2)
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
