import SwiftUI

struct ContentView: View {
    var body: some View {
        CameraPreview()
            .ignoresSafeArea()
            .background(Color.black)
            .statusBarHidden()
            .persistentSystemOverlays(.hidden)
    }
}
