import SwiftUI

struct MainView: View {
    enum AppSection: String, CaseIterable, Identifiable {
        case home
        case library
        case chats
        case downloads

        var id: String { rawValue }

        var title: String {
            switch self {
            case .home: "Home"
            case .library: "Library"
            case .chats: "Chats"
            case .downloads: "Downloads"
            }
        }

        var icon: String {
            switch self {
            case .home: "house.fill"
            case .library: "rectangle.stack.fill"
            case .chats: "bubble.left.and.bubble.right.fill"
            case .downloads: "arrow.down.circle.fill"
            }
        }
    }

    let quote: String

    @State private var selectedSection: AppSection = .home

    var body: some View {
        ZStack {
            BackgroundView()

            Group {
                switch selectedSection {
                case .home:
                    MaxHomeView(seedMessage: quote)
                case .library:
                    MaxLibraryView()
                case .chats:
                    MaxChatsView()
                case .downloads:
                    MaxDownloadsView()
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MaxTabBar(selection: $selectedSection)
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 8)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainView(quote: "Everything you want, in one place.")
}
