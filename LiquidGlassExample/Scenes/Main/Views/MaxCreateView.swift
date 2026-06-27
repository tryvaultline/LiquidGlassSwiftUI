import SwiftUI

struct MaxCreateView: View {
    @EnvironmentObject private var store: MaxPrototypeStore

    let selectTab: (MaxTab) -> Void

    @State private var selectedIDs: Set<String> = []
    @State private var pickerKind: MediaKind?
    @State private var caption = ""
    @State private var recipientID = "weekend-group"
    @State private var allowDownloads = true
    @State private var uploadState: UploadState = .preparing
    @State private var mediaAccessBlocked = false
    @State private var showSentConfirmation = false

    private var selectedItems: [MaxMediaItem] {
        store.media.filter { selectedIDs.contains($0.id) }
    }

    private var recipient: MaxConversation? {
        store.conversations.first { $0.id == recipientID }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                MaxPageHeader(title: "Create", subtitle: "Send media to people you choose")
                privacyPromise

                if mediaAccessBlocked {
                    accessBlockedState
                } else {
                    sourceButtons

                    if selectedItems.isEmpty {
                        MaxEmptyState(
                            symbol: "rectangle.stack.badge.plus",
                            title: "Select private media",
                            detail: "Choose photos or videos to prepare a private share. Nothing is posted publicly.",
                            actionTitle: "Select Videos"
                        ) {
                            pickerKind = .video
                        }
                    } else {
                        selectedPreview
                        deliveryDetails
                        uploadQueue
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 112)
        }
        .sheet(item: $pickerKind) { kind in
            CreateMediaPicker(
                kind: kind,
                selectedIDs: $selectedIDs,
                mediaAccessBlocked: $mediaAccessBlocked
            )
            .presentationDetents([.large])
        }
        .onChange(of: selectedIDs) { _, value in
            if value.isEmpty {
                uploadState = .preparing
            } else if uploadState != .sent {
                uploadState = .readyToSend
            }
        }
    }

    private var privacyPromise: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.black)
                .frame(width: 34, height: 34)
                .background(.white, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("Private sharing only")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Max does not have public posting in this prototype.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.54))
            }
            Spacer()
        }
        .padding(12)
        .maxSurface(cornerRadius: 21, emphasized: true)
    }

    private var sourceButtons: some View {
        HStack(spacing: 10) {
            CreateSourceButton(title: "Select Photos", symbol: "photo.on.rectangle") { pickerKind = .photo }
            CreateSourceButton(title: "Select Videos", symbol: "play.rectangle.fill") { pickerKind = .video }
        }
    }

    private var selectedPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            MaxSectionTitle(title: "Selected Media", subtitle: "\(selectedItems.count) items · Multi-select enabled")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(selectedItems) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            ZStack(alignment: .topTrailing) {
                                MaxMediaArtwork(item: item, height: 134)
                                    .frame(width: 158)
                                Button {
                                    HapticFeedback.selection()
                                    selectedIDs.remove(item.id)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.black)
                                        .frame(width: 28, height: 28)
                                        .background(.white, in: Circle())
                                }
                                .buttonStyle(.plain)
                                .padding(7)
                            }
                            Text(item.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        }
                        .frame(width: 158, alignment: .leading)
                    }

                    Button { pickerKind = .video } label: {
                        VStack(spacing: 9) {
                            Image(systemName: "plus")
                                .font(.title3.weight(.semibold))
                            Text("Add More")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(.white.opacity(0.78))
                        .frame(width: 108, height: 134)
                        .maxSurface(cornerRadius: 20)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var deliveryDetails: some View {
        VStack(alignment: .leading, spacing: 14) {
            MaxSectionTitle(title: "Private Delivery", subtitle: "Choose a person or private group")

            VStack(alignment: .leading, spacing: 8) {
                Text("Caption")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.63))
                TextField("Add a caption", text: $caption, axis: .vertical)
                    .lineLimit(2...4)
                    .foregroundStyle(.white)
                    .padding(13)
                    .maxSurface(cornerRadius: 18)
            }

            Menu {
                ForEach(store.conversations) { conversation in
                    Button {
                        HapticFeedback.selection()
                        recipientID = conversation.id
                    } label: {
                        Label(conversation.title, systemImage: conversation.isGroup ? "person.3.fill" : "person.fill")
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: recipient?.isGroup == true ? "person.3.fill" : "person.fill")
                        .foregroundStyle(.white.opacity(0.75))
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Send privately to")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.48))
                        Text(recipient?.title ?? "Choose recipient")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.42))
                }
                .padding(10)
                .maxSurface(cornerRadius: 19)
            }

            Toggle(isOn: $allowDownloads) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Allow Download")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Recipients can keep an offline copy on their device.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.52))
                }
            }
            .tint(.white)
            .padding(12)
            .maxSurface(cornerRadius: 19)
        }
    }

    private var uploadQueue: some View {
        VStack(alignment: .leading, spacing: 12) {
            MaxSectionTitle(title: "Upload Queue", subtitle: uploadState.title)

            ForEach(selectedItems) { item in
                HStack(spacing: 11) {
                    MaxMediaArtwork(item: item, height: 54)
                        .frame(width: 82)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        HStack(spacing: 5) {
                            Image(systemName: uploadIcon)
                            Text(uploadState.title)
                        }
                        .font(.caption)
                        .foregroundStyle(uploadState == .failed ? .white.opacity(0.74) : .white.opacity(0.53))
                        if uploadState == .uploading {
                            ProgressView(value: 0.68)
                                .tint(.white)
                        }
                    }
                    Spacer()
                    if uploadState == .sent {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.white)
                    }
                }
                .padding(9)
                .maxSurface(cornerRadius: 19)
            }

            HStack(spacing: 10) {
                if uploadState == .failed {
                    Button("Retry Upload") { runUploadPreparation() }
                        .buttonStyle(.plain)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.white, in: Capsule())
                } else if uploadState != .sent {
                    Button("Prepare Upload") { runUploadPreparation() }
                        .buttonStyle(.plain)
                        .foregroundStyle(.white.opacity(0.78))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.08), in: Capsule())
                }

                if uploadState != .sent {
                    Button("Preview Failed Upload") {
                        HapticFeedback.selection()
                        uploadState = .failed
                        store.showSuccess("Upload Failed", detail: "Retry is available in the queue.", symbol: "exclamationmark.triangle.fill")
                    }
                    .buttonStyle(.plain)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()
            }

            if showSentConfirmation {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.black)
                        .frame(width: 34, height: 34)
                        .background(.white, in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sent to \(recipient?.title ?? "your chat")")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("The same media is now in Chats and Library.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    Spacer()
                    Button("Open Chat") { selectTab(.chats) }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .buttonStyle(.plain)
                }
                .padding(12)
                .maxSurface(cornerRadius: 20, emphasized: true)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Button(action: sendPrivately) {
                HStack(spacing: 8) {
                    Image(systemName: "paperplane.fill")
                    Text(uploadState == .sent ? "Sent Privately" : "Send Privately")
                        .font(.headline.weight(.semibold))
                }
                .foregroundStyle(uploadState == .readyToSend ? .black : .white.opacity(0.45))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(uploadState == .readyToSend ? .white : .white.opacity(0.08), in: RoundedRectangle(cornerRadius: 19, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(uploadState != .readyToSend)
        }
    }

    private var accessBlockedState: some View {
        MaxEmptyState(
            symbol: "photo.badge.exclamationmark",
            title: "Permission Denied",
            detail: "Photos and videos stay unavailable until access is granted. This is a visible prototype state.",
            actionTitle: "Restore Demo Access"
        ) {
            mediaAccessBlocked = false
            store.showSuccess("Permission Restored", detail: "You can select prototype media again.", symbol: "photo.on.rectangle")
        }
    }

    private var uploadIcon: String {
        switch uploadState {
        case .preparing: "tray.and.arrow.up"
        case .uploading: "arrow.up.circle.fill"
        case .readyToSend: "checkmark.circle.fill"
        case .sent: "paperplane.fill"
        case .failed: "exclamationmark.triangle.fill"
        }
    }

    private func runUploadPreparation() {
        HapticFeedback.tap()
        uploadState = .uploading
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 750_000_000)
            guard uploadState == .uploading else { return }
            uploadState = .readyToSend
            store.showSuccess("Upload Ready", detail: "Your selected media is ready for private delivery.", symbol: "checkmark.circle.fill")
        }
    }

    private func sendPrivately() {
        guard !selectedIDs.isEmpty else {
            store.showSuccess("Select media first", detail: "Choose at least one photo or video.", symbol: "photo.badge.plus")
            return
        }
        guard uploadState == .readyToSend else { return }
        HapticFeedback.success()
        uploadState = .sent
        store.sendMedia(templateIDs: Array(selectedIDs), caption: caption, recipientID: recipientID, allowDownloads: allowDownloads)
        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
            showSentConfirmation = true
        }
    }
}

private struct CreateSourceButton: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.title3.weight(.semibold))
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white.opacity(0.82))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .maxSurface(cornerRadius: 22)
        }
        .buttonStyle(.plain)
    }
}
