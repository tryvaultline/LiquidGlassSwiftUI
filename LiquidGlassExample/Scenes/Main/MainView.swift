import SwiftUI

private struct MediaRoute: Identifiable {
    let id: String
}

struct MainView: View {
    let quote: String

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = MaxPrototypeStore()
    @State private var selectedTab: MaxTab = .home
    @State private var presentedMedia: MediaRoute?
    @State private var searchPresented = false
    @State private var showPrivacyShield = false

    var body: some View {
        ZStack {
            BackgroundView()

            Group {
                switch selectedTab {
                case .home:
                    MaxHomeView(
                        openSearch: { searchPresented = true },
                        openMedia: presentMedia,
                        selectTab: selectTab
                    )
                case .library:
                    MaxLibraryView(openMedia: presentMedia)
                case .create:
                    MaxCreateView(selectTab: selectTab)
                case .chats:
                    MaxChatsView(openMedia: presentMedia)
                case .profile:
                    MaxProfileView(openMedia: presentMedia)
                }
            }
            .id(selectedTab)
            .transition(.opacity.combined(with: .scale(scale: 0.985)))
        }
        .environmentObject(store)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MaxTabBar(selection: $selectedTab)
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 8)
        }
        .sheet(isPresented: $searchPresented) {
            MaxSearchOverlay(isPresented: $searchPresented, selectMedia: presentMedia)
        }
        .fullScreenCover(item: $presentedMedia) { route in
            MaxPlayerScreen(mediaID: route.id) {
                presentedMedia = nil
            }
            .environmentObject(store)
        }
        .overlay(alignment: .bottom) {
            if let toast = store.toast {
                MaxToastView(toast: toast)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 98)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay {
            if showPrivacyShield && !store.isScreenLocked {
                AppPrivacyShield()
                    .transition(.opacity)
            }
        }
        .overlay {
            if store.isScreenLocked {
                FaceIDMockGate(quote: quote) {
                    withAnimation(.easeOut(duration: 0.28)) {
                        store.isScreenLocked = false
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: store.toast)
        .animation(.easeInOut(duration: 0.2), value: showPrivacyShield)
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, phase in
            withAnimation(.easeInOut(duration: 0.16)) {
                showPrivacyShield = phase != .active
            }
        }
    }

    private func presentMedia(_ mediaID: String) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.9)) {
            presentedMedia = MediaRoute(id: mediaID)
        }
    }

    private func selectTab(_ tab: MaxTab) {
        HapticFeedback.selection()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            selectedTab = tab
        }
    }
}

private struct FaceIDMockGate: View {
    let quote: String
    let unlock: () -> Void

    @State private var isScanning = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer()

                Image(systemName: "faceid")
                    .font(.system(size: 54, weight: .light))
                    .foregroundStyle(.white)
                    .frame(width: 122, height: 122)
                    .background(.white.opacity(isScanning ? 0.16 : 0.08), in: RoundedRectangle(cornerRadius: 38, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 38, style: .continuous)
                            .strokeBorder(.white.opacity(isScanning ? 0.44 : 0.14), lineWidth: 1)
                    }
                    .scaleEffect(isScanning ? 1.04 : 1)
                    .animation(.easeInOut(duration: 0.55).repeatCount(isScanning ? 2 : 0, autoreverses: true), value: isScanning)

                Text("Unlock Max")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text("Your private media room is protected by a Face ID mock gate.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.58))
                    .padding(.horizontal, 38)

                Button {
                    HapticFeedback.tap()
                    isScanning = true
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 700_000_000)
                        unlock()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "faceid")
                        Text(isScanning ? "Authenticating…" : "Use Face ID")
                            .font(.headline.weight(.semibold))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.white, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isScanning)
                .padding(.horizontal, 28)

                Button("Use Passcode Instead") {
                    HapticFeedback.selection()
                    unlock()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
                .buttonStyle(.plain)

                Text(quote)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.34))
                    .padding(.top, 8)

                Spacer()
                Spacer()
            }
        }
    }
}

private struct AppPrivacyShield: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.85))
                Text("Max")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text("Private content hidden")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.52))
            }
        }
        .accessibilityLabel("Private content hidden")
    }
}

#Preview {
    MainView(quote: "Everything you want, in one place.")
}
