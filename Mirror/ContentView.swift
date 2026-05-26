import SwiftUI
import UIKit

struct ContentView: View {
    @State private var e = false
    @State private var brightnessBeforeFlashlight: CGFloat = UIScreen.main.brightness
    @State private var zoom: CGFloat = 1.0
    @State private var zoomAtGestureStart: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CameraPreview(zoom: zoom)
                    .allowsHitTesting(false)
                VStack(spacing: 0) {
                    Color.white
                        .frame(height: geometry.size.height / 6)
                        .opacity(e ? 1 : 0)
                    Spacer(minLength: 0)
                    Color.white
                        .frame(height: geometry.size.height / 6)
                        .opacity(e ? 1 : 0)
                }
                .allowsHitTesting(false)
                VStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            e.toggle()
                        }
                    } label: {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .shadow(color: e ? .black : .clear, radius: 0, x: 1, y: 0)
                            .shadow(color: e ? .black : .clear, radius: 0, x: -1, y: 0)
                            .shadow(color: e ? .black : .clear, radius: 0, x: 0, y: 1)
                            .shadow(color: e ? .black : .clear, radius: 0, x: 0, y: -1)
                            .frame(width: 64, height: 64)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.clear, in: Circle())
                    .overlay(Circle().stroke(e ? Color.black : Color.clear, lineWidth: 1.5))
                    .padding(.bottom, geometry.size.height / 12 - 32 + 20)
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
        .onChange(of: e) { _, turnedOn in
            if turnedOn {
                brightnessBeforeFlashlight = UIScreen.main.brightness
                UIScreen.main.brightness = 1.0
            } else {
                UIScreen.main.brightness = brightnessBeforeFlashlight
            }
        }
    }
}
