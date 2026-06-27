import SwiftUI

struct MaxProfileView: View {
    @EnvironmentObject private var store: MaxPrototypeStore

    let openMedia: (String) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                identityCard
                MaxStorageCard()
                personalMedia
                privacySettings
                accountSettings
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 112)
        }
    }

    private var header: some View {
        MaxPageHeader(
            title: "Profile",
            subtitle: "Your private space in Max",
            trailing: AnyView(
                Button {
                    HapticFeedback.tap()
                    if store.screenLockEnabled {
                        store.isScreenLocked = true
                    } else {
                        store.showSuccess("Screen Lock Disabled", detail: "Enable it in Privacy to use the Face ID mock gate.", symbol: "lock.open.fill")
                    }
                } label: {
                    Image(systemName: "lock.fill")
                        .actionIcon(font: .body.weight(.semibold))
                }
                .buttonStyle(.plain)
                .glassCircleButton(diameter: 42)
                .accessibilityLabel("Lock Max")
            )
        )
    }

    private var identityCard: some View {
        HStack(spacing: 14) {
            Text("R")
                .font(.title.weight(.bold))
                .foregroundStyle(.black)
                .frame(width: 66, height: 66)
                .background(.white, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Raied")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text("Private media, chats, and library")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.57))
                Label("Private account", systemImage: "lock.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.67))
            }
            Spacer()
        }
        .padding(15)
        .maxSurface(cornerRadius: 26, emphasized: true)
    }

    private var personalMedia: some View {
        VStack(alignment: .leading, spacing: 18) {
            profileShelf(
                title: "Saved Media",
                subtitle: "\(store.savedMedia.count) kept for later",
                items: store.savedMedia,
                emptyTitle: "Nothing saved yet",
                emptyDetail: "Save media from Home or the player and it will appear here."
            )

            profileShelf(
                title: "Ratings",
                subtitle: "Your private 1–10 ratings",
                items: store.ratedMedia,
                emptyTitle: "No ratings yet",
                emptyDetail: "Rate a video in the player to see it here."
            )

            profileShelf(
                title: "Watch History",
                subtitle: "Visible only to you",
                items: store.watchedMedia,
                emptyTitle: "No watch history yet",
                emptyDetail: "Play private media and it will appear here."
            )
        }
    }

    private var privacySettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            MaxSectionTitle(title: "Privacy", subtitle: "Controls that stay on your device")

            Toggle(isOn: $store.screenLockEnabled) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Screen Lock")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Require the Face ID mock gate when reopening Max.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.53))
                }
            }
            .tint(.white)
            .padding(12)
            .maxSurface(cornerRadius: 20)

            Button {
                HapticFeedback.tap()
                store.isScreenLocked = true
            } label: {
                HStack {
                    Label("Test Face ID Gate", systemImage: "faceid")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(12)
                .maxSurface(cornerRadius: 20)
            }
            .buttonStyle(.plain)

            Toggle(isOn: $store.isOfflineMode) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Offline Mode")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Limit playback to completed local downloads.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.53))
                }
            }
            .tint(.white)
            .padding(12)
            .maxSurface(cornerRadius: 20)
        }
    }

    private var accountSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            MaxSectionTitle(title: "Account", subtitle: "Prototype preferences")

            VStack(alignment: .leading, spacing: 8) {
                Text("Language")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.57))
                HStack(spacing: 8) {
                    ForEach(AppLanguage.allCases) { language in
                        Button {
                            HapticFeedback.selection()
                            store.language = language
                            store.showSuccess("Language Selected", detail: language.rawValue, symbol: "globe")
                        } label: {
                            Text(language.rawValue)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(store.language == language ? .black : .white.opacity(0.72))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(store.language == language ? .white : .white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(12)
            .maxSurface(cornerRadius: 20)

            VStack(alignment: .leading, spacing: 8) {
                Text("Appearance")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.57))
                HStack(spacing: 8) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Button {
                            HapticFeedback.selection()
                            store.appearance = appearance
                            store.showSuccess("Appearance Selected", detail: appearance.rawValue, symbol: appearance == .dark ? "moon.fill" : "circle.lefthalf.filled")
                        } label: {
                            Label(appearance.rawValue, systemImage: appearance == .dark ? "moon.fill" : "circle.lefthalf.filled")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(store.appearance == appearance ? .black : .white.opacity(0.72))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(store.appearance == appearance ? .white : .white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(12)
            .maxSurface(cornerRadius: 20)

            Button {
                store.showSuccess("Account Prototype", detail: "Account management remains local and mock-only.", symbol: "person.crop.circle")
            } label: {
                HStack {
                    Label("Manage Account", systemImage: "person.crop.circle")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(12)
                .maxSurface(cornerRadius: 20)
            }
            .buttonStyle(.plain)
        }
    }

    private func profileShelf(
        title: String,
        subtitle: String,
        items: [MaxMediaItem],
        emptyTitle: String,
        emptyDetail: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            MaxSectionTitle(title: title, subtitle: subtitle)
            if items.isEmpty {
                MaxEmptyState(
                    symbol: "rectangle.stack",
                    title: emptyTitle,
                    detail: emptyDetail,
                    actionTitle: "Go to Home"
                ) {
                    store.showSuccess("Open Home", detail: "Use the Home tab to find private media.", symbol: "house.fill")
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(items) { item in
                            MaxMediaCard(item: item, isCompact: true) {
                                HapticFeedback.tap()
                                openMedia(item.id)
                            }
                            .frame(width: 184)
                        }
                    }
                }
            }
        }
    }
}
