import SwiftUI

private struct ChatRoute: Identifiable {
    let id: String
}

struct MaxChatsView: View {
    @EnvironmentObject private var store: MaxPrototypeStore

    let openMedia: (String) -> Void

    @State private var selectedConversation: ChatRoute?
    @State private var showCreateGroup = false
    @State private var showEmptyChats = false

    private var directMessages: [MaxConversation] {
        store.conversations.filter { !$0.isGroup }
    }

    private var groupMessages: [MaxConversation] {
        store.conversations.filter(\.isGroup)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header

                if showEmptyChats {
                    MaxEmptyState(
                        symbol: "bubble.left.and.bubble.right",
                        title: "No Private Chats",
                        detail: "Start a direct message or create a private group. Public channels are not part of Max.",
                        actionTitle: "Restore Conversations"
                    ) {
                        showEmptyChats = false
                    }
                } else {
                    chatSection(title: "DIRECT MESSAGES", conversations: directMessages)
                    chatSection(title: "PRIVATE GROUPS", conversations: groupMessages)

                    HStack(spacing: 10) {
                        Image(systemName: "lock.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.black)
                            .frame(width: 30, height: 30)
                            .background(.white, in: Circle())
                        Text("Messages, groups, and media here are private by design.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.58))
                        Spacer()
                    }
                    .padding(11)
                    .maxSurface(cornerRadius: 18)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 112)
        }
        .sheet(item: $selectedConversation) { route in
            MaxChatDetail(conversationID: route.id, openMedia: openMedia)
        }
        .sheet(isPresented: $showCreateGroup) {
            MaxGroupCreationSheet()
                .presentationDetents([.medium])
        }
    }

    private var header: some View {
        MaxPageHeader(
            title: "Chats",
            subtitle: "Direct messages and private groups",
            trailing: AnyView(
                HStack(spacing: 8) {
                    Menu {
                        Button("Preview Empty Chats") { showEmptyChats = true }
                        Button("Show Conversations") { showEmptyChats = false }
                    } label: {
                        Image(systemName: "ellipsis")
                            .actionIcon(font: .body.weight(.bold))
                    }
                    .glassCircleButton(diameter: 42)

                    Button {
                        HapticFeedback.tap()
                        showCreateGroup = true
                    } label: {
                        Image(systemName: "person.3.fill")
                            .actionIcon(font: .body.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .glassCircleButton(diameter: 42)
                    .accessibilityLabel("Create private group")
                }
            )
        )
    }

    private func chatSection(title: String, conversations: [MaxConversation]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption2.weight(.bold))
                .tracking(1.1)
                .foregroundStyle(.white.opacity(0.46))

            ForEach(conversations) { conversation in
                ChatListRow(conversation: conversation) {
                    HapticFeedback.tap()
                    selectedConversation = ChatRoute(id: conversation.id)
                }
            }
        }
    }
}

private struct ChatListRow: View {
    let conversation: MaxConversation
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: conversation.isGroup ? "person.3.fill" : "person.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))
                    .frame(width: 48, height: 48)
                    .background(.white.opacity(0.09), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(conversation.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(conversation.lastPreview)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(conversation.lastTime)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.43))
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption2.weight(.bold).monospacedDigit())
                            .foregroundStyle(.black)
                            .frame(minWidth: 19, minHeight: 19)
                            .background(.white, in: Capsule())
                    }
                }
            }
            .padding(12)
            .maxSurface(cornerRadius: 22)
        }
        .buttonStyle(.plain)
    }
}

struct MaxChatDetail: View {
    @EnvironmentObject private var store: MaxPrototypeStore
    @Environment(\.dismiss) private var dismiss

    let conversationID: String
    let openMedia: (String) -> Void

    @State private var composer = ""
    @State private var attachmentKind: MediaKind?
    @State private var showTyping = true

    private var conversation: MaxConversation? {
        store.conversations.first { $0.id == conversationID }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let conversation {
                    VStack(spacing: 0) {
                        ScrollViewReader { proxy in
                            ScrollView(showsIndicators: false) {
                                LazyVStack(alignment: .leading, spacing: 12) {
                                    ForEach(conversation.messages) { message in
                                        ChatMessageBubble(message: message, conversationID: conversationID, openMedia: openMedia)
                                            .id(message.id)
                                    }

                                    if showTyping {
                                        HStack(spacing: 8) {
                                            ProgressView()
                                                .controlSize(.small)
                                                .tint(.white)
                                            Text("\(conversation.isGroup ? "Noura" : conversation.title) is typing…")
                                                .font(.caption)
                                                .foregroundStyle(.white.opacity(0.55))
                                            Spacer()
                                            Button("Hide") {
                                                showTyping = false
                                            }
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(.white.opacity(0.55))
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.leading, 8)
                                    } else {
                                        Button("Show typing indicator") {
                                            showTyping = true
                                        }
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.55))
                                        .buttonStyle(.plain)
                                        .padding(.leading, 8)
                                    }
                                }
                                .padding(16)
                            }
                            .onChange(of: conversation.messages.count) { _, _ in
                                withAnimation(.easeOut(duration: 0.2)) {
                                    proxy.scrollTo(conversation.messages.last?.id, anchor: .bottom)
                                }
                            }
                        }

                        composerBar
                    }
                } else {
                    MaxEmptyState(
                        symbol: "bubble.left.and.exclamationmark.bubble.right",
                        title: "Chat unavailable",
                        detail: "This prototype conversation no longer exists.",
                        actionTitle: "Close"
                    ) {
                        dismiss()
                    }
                    .padding(20)
                }
            }
            .navigationTitle(conversation?.title ?? "Private Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let conversation {
                        Text(conversation.isGroup ? "Private group" : "Direct message")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(item: $attachmentKind) { kind in
            ChatAttachmentPicker(kind: kind, conversationID: conversationID)
                .presentationDetents([.large])
        }
    }

    private var composerBar: some View {
        HStack(spacing: 8) {
            Button {
                attachmentKind = .photo
            } label: {
                Image(systemName: "photo")
                    .font(.body.weight(.semibold))
            }
            .buttonStyle(.plain)
            .glassCircleButton(diameter: 40)
            .accessibilityLabel("Attach photo")

            Button {
                attachmentKind = .video
            } label: {
                Image(systemName: "video.fill")
                    .font(.body.weight(.semibold))
            }
            .buttonStyle(.plain)
            .glassCircleButton(diameter: 40)
            .accessibilityLabel("Attach video")

            TextField("Message", text: $composer, axis: .vertical)
                .lineLimit(1...4)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .maxSurface(cornerRadius: 18)

            Button {
                HapticFeedback.tap()
                store.sendText(composer, to: conversationID)
                composer = ""
            } label: {
                Image(systemName: "arrow.up")
                    .font(.body.weight(.bold))
            }
            .buttonStyle(.plain)
            .glassCircleButton(diameter: 40, isActive: !composer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .disabled(composer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.black.opacity(0.92))
    }
}

private struct ChatMessageBubble: View {
    @EnvironmentObject private var store: MaxPrototypeStore

    let message: MaxChatMessage
    let conversationID: String
    let openMedia: (String) -> Void

    var body: some View {
        HStack {
            if message.isMine { Spacer(minLength: 46) }

            VStack(alignment: message.isMine ? .trailing : .leading, spacing: 5) {
                if !message.isMine {
                    Text(message.author)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.48))
                }

                if let mediaID = message.mediaID, let item = store.mediaItem(id: mediaID) {
                    Button {
                        HapticFeedback.tap()
                        openMedia(mediaID)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            MaxMediaArtwork(item: item, height: 138, showsProgress: item.downloadState != nil)
                                .frame(width: 214)
                            Text(item.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                            Text(item.metadataLine)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.54))
                        }
                        .padding(8)
                        .maxSurface(cornerRadius: 20)
                    }
                    .buttonStyle(.plain)
                }

                if !message.text.isEmpty {
                    Text(message.text)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(message.isMine ? .white.opacity(0.16) : .white.opacity(0.08), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                }

                HStack(spacing: 7) {
                    Text(message.timeLabel)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                    Button(message.reaction ?? "＋") {
                        HapticFeedback.selection()
                        store.react(to: message.id, in: conversationID, reaction: message.reaction == nil ? "♥︎" : "✨")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.67))
                    .buttonStyle(.plain)
                }
            }

            if !message.isMine { Spacer(minLength: 46) }
        }
    }
}

private struct ChatAttachmentPicker: View {
    @EnvironmentObject private var store: MaxPrototypeStore
    @Environment(\.dismiss) private var dismiss

    let kind: MediaKind
    let conversationID: String

    @State private var selectedIDs: Set<String> = []

    private var options: [MaxMediaItem] {
        store.media.filter { $0.kind == kind && !$0.isLocked }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(options) { item in
                            Button {
                                HapticFeedback.selection()
                                if selectedIDs.contains(item.id) {
                                    selectedIDs.remove(item.id)
                                } else {
                                    selectedIDs.insert(item.id)
                                }
                            } label: {
                                ZStack(alignment: .topTrailing) {
                                    MaxMediaArtwork(item: item, height: 150)
                                    Image(systemName: selectedIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(selectedIDs.contains(item.id) ? .black : .white)
                                        .padding(8)
                                        .background(selectedIDs.contains(item.id) ? .white : .black.opacity(0.3), in: Circle())
                                        .padding(8)
                                }
                                .padding(8)
                                .maxSurface(cornerRadius: 20, emphasized: selectedIDs.contains(item.id))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Attach \(kind.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Send") {
                        store.sendMedia(
                            templateIDs: Array(selectedIDs),
                            caption: "Shared from private chat",
                            recipientID: conversationID,
                            allowDownloads: true
                        )
                        dismiss()
                    }
                    .foregroundStyle(selectedIDs.isEmpty ? .white.opacity(0.35) : .white)
                    .disabled(selectedIDs.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct MaxGroupCreationSheet: View {
    @EnvironmentObject private var store: MaxPrototypeStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var members: Set<String> = ["Noura"]

    private let people = ["Noura", "Maya", "Sami"]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Create Private Group")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Text("Only invited people can see this group and its shared media.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.56))

            TextField("Group name", text: $name)
                .foregroundStyle(.white)
                .padding(13)
                .maxSurface(cornerRadius: 18)

            VStack(alignment: .leading, spacing: 8) {
                Text("Invite people")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
                ForEach(people, id: \.self) { person in
                    Button {
                        HapticFeedback.selection()
                        if members.contains(person) {
                            members.remove(person)
                        } else {
                            members.insert(person)
                        }
                    } label: {
                        HStack {
                            Text(person)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Image(systemName: members.contains(person) ? "checkmark.circle.fill" : "circle")
                        }
                        .foregroundStyle(members.contains(person) ? .white : .white.opacity(0.58))
                        .padding(10)
                        .maxSurface(cornerRadius: 16, emphasized: members.contains(person))
                    }
                    .buttonStyle(.plain)
                }
            }

            Button("Create Private Group") {
                store.createGroup(named: name, with: Array(members).sorted())
                if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    dismiss()
                }
            }
            .font(.headline.weight(.semibold))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .buttonStyle(.plain)
        }
        .padding(22)
        .presentationBackground(.black)
    }
}
