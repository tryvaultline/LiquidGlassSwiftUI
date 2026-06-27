import SwiftUI

private struct ChatRoute: Identifiable {
    let id: String
}

private struct ChatMessageRoute: Identifiable {
    let conversationID: String
    let messageID: String

    var id: String { "\(conversationID)-\(messageID)" }
}

private enum ChatInboxFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case unread = "Unread"
    case direct = "DMs"
    case groups = "Groups"

    var id: String { rawValue }
}

struct MaxChatsView: View {
    @EnvironmentObject private var store: MaxPrototypeStore

    let openMedia: (String) -> Void

    @State private var selectedConversation: ChatRoute?
    @State private var showCreateGroup = false
    @State private var showEmptyChats = false
    @State private var showSearch = false
    @State private var searchText = ""
    @State private var filter: ChatInboxFilter = .all

    private var visibleConversations: [MaxConversation] {
        let loweredQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered = store.conversations.filter { conversation in
            let matchesFilter: Bool
            switch filter {
            case .all:
                matchesFilter = true
            case .unread:
                matchesFilter = conversation.unreadCount > 0
            case .direct:
                matchesFilter = !conversation.isGroup
            case .groups:
                matchesFilter = conversation.isGroup
            }

            let matchesSearch = loweredQuery.isEmpty || conversation.title.lowercased().contains(loweredQuery) || conversation.lastPreview.lowercased().contains(loweredQuery)
            return matchesFilter && matchesSearch
        }

        return filtered.enumerated().sorted { left, right in
            let leftPinned = store.isConversationPinned(left.element.id)
            let rightPinned = store.isConversationPinned(right.element.id)
            if leftPinned != rightPinned {
                return leftPinned && !rightPinned
            }
            return left.offset < right.offset
        }
        .map(\.element)
    }

    private var pinnedConversations: [MaxConversation] {
        visibleConversations.filter { store.isConversationPinned($0.id) }
    }

    private var directMessages: [MaxConversation] {
        visibleConversations.filter { !$0.isGroup && !store.isConversationPinned($0.id) }
    }

    private var groupMessages: [MaxConversation] {
        visibleConversations.filter { $0.isGroup && !store.isConversationPinned($0.id) }
    }

    private var unreadTotal: Int {
        store.conversations.reduce(0) { $0 + $1.unreadCount }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header

                if showSearch {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.white.opacity(0.58))
                        TextField("Search private chats", text: $searchText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundStyle(.white)
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Clear chat search")
                        }
                    }
                    .padding(.horizontal, 13)
                    .padding(.vertical, 12)
                    .maxSurface(cornerRadius: 18)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                inboxFilters

                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: unreadTotal > 0 ? "bubble.left.and.bubble.right.fill" : "checkmark.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.black)
                        .frame(width: 28, height: 28)
                        .background(.white, in: Circle())
                    Text(unreadTotal > 0 ? "\(unreadTotal) unread messages across your private circles" : "Your private inbox is up to date")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                    Spacer(minLength: 0)
                }
                .padding(11)
                .maxSurface(cornerRadius: 18)

                if showEmptyChats {
                    MaxEmptyState(
                        symbol: "bubble.left.and.bubble.right",
                        title: "No Private Chats",
                        detail: "Start a direct message or create a private group. Public channels are not part of Max.",
                        actionTitle: "Restore Conversations"
                    ) {
                        showEmptyChats = false
                    }
                } else if visibleConversations.isEmpty {
                    MaxEmptyState(
                        symbol: "magnifyingglass",
                        title: "No Matching Chats",
                        detail: "Try a different name or clear the active inbox filter.",
                        actionTitle: "Show All Chats"
                    ) {
                        searchText = ""
                        filter = .all
                    }
                } else {
                    if !pinnedConversations.isEmpty {
                        chatSection(title: "PINNED", conversations: pinnedConversations)
                    }
                    if !directMessages.isEmpty {
                        chatSection(title: "DIRECT MESSAGES", conversations: directMessages)
                    }
                    if !groupMessages.isEmpty {
                        chatSection(title: "PRIVATE GROUPS", conversations: groupMessages)
                    }

                    HStack(spacing: 10) {
                        Image(systemName: "lock.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.black)
                            .frame(width: 30, height: 30)
                            .background(.white, in: Circle())
                        Text("Messages, groups, threads, and shared media are private by design.")
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
        .animation(.easeInOut(duration: 0.22), value: showSearch)
    }

    private var header: some View {
        MaxPageHeader(
            title: "Chats",
            subtitle: "Private messages, groups, and shared media",
            trailing: AnyView(
                HStack(spacing: 8) {
                    Button {
                        HapticFeedback.selection()
                        showSearch.toggle()
                        if !showSearch { searchText = "" }
                    } label: {
                        Image(systemName: showSearch ? "xmark" : "magnifyingglass")
                            .actionIcon(font: .body.weight(.bold))
                    }
                    .buttonStyle(.plain)
                    .glassCircleButton(diameter: 42)
                    .accessibilityLabel(showSearch ? "Close chat search" : "Search chats")

                    Menu {
                        Button("Preview Empty Chats", systemImage: "rectangle.on.rectangle.slash") { showEmptyChats = true }
                        Button("Show Conversations", systemImage: "bubble.left.and.bubble.right") { showEmptyChats = false }
                        Button("Clear Inbox Filters", systemImage: "line.3.horizontal.decrease.circle") {
                            searchText = ""
                            filter = .all
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .actionIcon(font: .body.weight(.bold))
                    }
                    .glassCircleButton(diameter: 42)
                    .accessibilityLabel("Chat inbox actions")

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

    private var inboxFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ChatInboxFilter.allCases) { item in
                    Button {
                        HapticFeedback.selection()
                        filter = item
                    } label: {
                        Text(item.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(filter == item ? .black : .white.opacity(0.72))
                            .padding(.horizontal, 13)
                            .padding(.vertical, 8)
                            .background(filter == item ? .white : .white.opacity(0.08), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(filter == item ? .isSelected : [])
                }
            }
        }
    }

    private func chatSection(title: String, conversations: [MaxConversation]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption2.weight(.bold))
                .tracking(1.1)
                .foregroundStyle(.white.opacity(0.46))

            ForEach(conversations) { conversation in
                ChatListRow(
                    conversation: conversation,
                    isTyping: conversation.id == "weekend-group" && !store.isConversationMuted(conversation.id)
                ) {
                    HapticFeedback.tap()
                    selectedConversation = ChatRoute(id: conversation.id)
                }
            }
        }
    }
}

private struct ChatListRow: View {
    @EnvironmentObject private var store: MaxPrototypeStore

    let conversation: MaxConversation
    let isTyping: Bool
    let action: () -> Void

    private var avatarSymbol: String {
        conversation.isGroup ? "person.3.fill" : "person.fill"
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: avatarSymbol)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))
                        .frame(width: 48, height: 48)
                        .background(.white.opacity(0.09), in: Circle())

                    if isTyping {
                        Circle()
                            .fill(.white)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().strokeBorder(.black, lineWidth: 2))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(conversation.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        if store.isConversationPinned(conversation.id) {
                            Image(systemName: "pin.fill")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white.opacity(0.55))
                        }
                        if store.isConversationMuted(conversation.id) {
                            Image(systemName: "bell.slash.fill")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                    }

                    Text(isTyping ? "Noura is typing…" : conversation.lastPreview)
                        .font(.caption)
                        .foregroundStyle(isTyping ? .white.opacity(0.82) : .white.opacity(0.55))
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

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
            .maxSurface(cornerRadius: 22, emphasized: store.isConversationPinned(conversation.id))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(store.isConversationPinned(conversation.id) ? "Unpin Chat" : "Pin Chat", systemImage: store.isConversationPinned(conversation.id) ? "pin.slash" : "pin") {
                store.togglePinnedConversation(conversation.id)
            }
            Button(store.isConversationMuted(conversation.id) ? "Unmute" : "Mute", systemImage: store.isConversationMuted(conversation.id) ? "bell" : "bell.slash") {
                store.toggleMutedConversation(conversation.id)
            }
            if conversation.unreadCount > 0 {
                Button("Mark Read", systemImage: "checkmark.circle") {
                    store.markConversationRead(conversation.id)
                }
            } else {
                Button("Mark Unread", systemImage: "circle") {
                    store.markConversationUnread(conversation.id)
                }
            }
        }
        .accessibilityHint("Opens \(conversation.title)")
    }
}

struct MaxChatDetail: View {
    @EnvironmentObject private var store: MaxPrototypeStore
    @Environment(\.dismiss) private var dismiss
    @FocusState private var composerFocused: Bool

    let conversationID: String
    let openMedia: (String) -> Void

    @State private var composer = ""
    @State private var attachmentKind: MediaKind?
    @State private var showTyping = true
    @State private var replyTargetID: String?
    @State private var threadRoute: ChatMessageRoute?
    @State private var reactionTargetID: String?
    @State private var showConversationInfo = false

    private var conversation: MaxConversation? {
        store.conversation(id: conversationID)
    }

    private var rootMessages: [MaxChatMessage] {
        conversation?.messages.filter { store.parentMessageID(for: $0.id) == nil } ?? []
    }

    private var pinnedMessages: [MaxChatMessage] {
        rootMessages.filter { store.isMessagePinned($0.id) }
    }

    private var replyTarget: MaxChatMessage? {
        guard let replyTargetID else { return nil }
        return store.message(id: replyTargetID, in: conversationID)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let conversation {
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                if !pinnedMessages.isEmpty {
                                    pinnedBanner(messages: pinnedMessages)
                                }

                                ChatTimelineMarker(title: "TODAY")

                                ForEach(rootMessages) { message in
                                    ChatMessageBubble(
                                        message: message,
                                        conversationID: conversationID,
                                        openMedia: openMedia,
                                        onReply: { replyTargetID = message.id },
                                        onOpenThread: { threadRoute = ChatMessageRoute(conversationID: conversationID, messageID: message.id) },
                                        onReact: { reactionTargetID = message.id }
                                    )
                                    .id(message.id)
                                }

                                typingIndicator(for: conversation)
                                    .id("typing")

                                Color.clear
                                    .frame(height: 1)
                                    .id("chat-bottom")
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 14)
                            .padding(.bottom, 16)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .onAppear {
                            store.markConversationRead(conversationID)
                            proxy.scrollTo("chat-bottom", anchor: .bottom)
                        }
                        .onChange(of: conversation.messages.count) { _, _ in
                            withAnimation(.easeOut(duration: 0.22)) {
                                proxy.scrollTo("chat-bottom", anchor: .bottom)
                            }
                        }
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
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
                    Button {
                        showConversationInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.white.opacity(0.78))
                    }
                    .accessibilityLabel("Conversation details")
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(item: $attachmentKind) { kind in
            ChatAttachmentPicker(kind: kind, conversationID: conversationID)
                .presentationDetents([.large])
        }
        .sheet(item: $threadRoute) { route in
            MaxChatThreadSheet(conversationID: route.conversationID, rootMessageID: route.messageID, openMedia: openMedia)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showConversationInfo) {
            MaxConversationInfoSheet(conversationID: conversationID, openMedia: openMedia)
                .presentationDetents([.large])
        }
        .confirmationDialog(
            "React to message",
            isPresented: Binding(
                get: { reactionTargetID != nil },
                set: { if !$0 { reactionTargetID = nil } }
            ),
            titleVisibility: .visible
        ) {
            ForEach(["♥︎", "✨", "😂", "!!", "👀"], id: \.self) { reaction in
                Button(reaction) {
                    if let reactionTargetID {
                        store.toggleReaction(reaction, to: reactionTargetID, in: conversationID)
                    }
                    self.reactionTargetID = nil
                }
            }
        }
    }

    @ViewBuilder
    private func typingIndicator(for conversation: MaxConversation) -> some View {
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

    private func pinnedBanner(messages: [MaxChatMessage]) -> some View {
        Button {
            if let first = messages.first {
                threadRoute = ChatMessageRoute(conversationID: conversationID, messageID: first.id)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "pin.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(width: 28, height: 28)
                    .background(.white, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pinned message")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                    Text(messages.first?.text.isEmpty == false ? messages.first?.text ?? "Shared media" : "Shared private media")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.58))
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(10)
            .maxSurface(cornerRadius: 17)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Pinned message")
    }

    private var composerBar: some View {
        VStack(spacing: 8) {
            if let replyTarget {
                HStack(spacing: 9) {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.7))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Replying to \(replyTarget.author)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                        Text(replyTarget.text.isEmpty ? "Shared private media" : replyTarget.text)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.54))
                            .lineLimit(1)
                    }
                    Spacer()
                    Button {
                        replyTargetID = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.46))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Cancel reply")
                }
                .padding(.horizontal, 14)
                .padding(.top, 9)
            }

            HStack(alignment: .bottom, spacing: 8) {
                Menu {
                    Button("Attach Photos", systemImage: "photo") { attachmentKind = .photo }
                    Button("Attach Videos", systemImage: "video.fill") { attachmentKind = .video }
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.bold))
                }
                .glassCircleButton(diameter: 40)
                .accessibilityLabel("Attach media")

                TextField("Message", text: $composer, axis: .vertical)
                    .focused($composerFocused)
                    .lineLimit(1...4)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .maxSurface(cornerRadius: 18)
                    .accessibilityLabel("Message composer")

                Button(action: sendComposer) {
                    Image(systemName: "arrow.up")
                        .font(.body.weight(.bold))
                }
                .buttonStyle(.plain)
                .glassCircleButton(diameter: 40, isActive: !composer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .disabled(composer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel("Send message")
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
        .background(.black.opacity(0.94))
    }

    private func sendComposer() {
        HapticFeedback.tap()
        store.sendText(composer, to: conversationID, replyTo: replyTargetID)
        composer = ""
        replyTargetID = nil
    }
}

private struct ChatTimelineMarker: View {
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Rectangle().fill(.white.opacity(0.1)).frame(height: 1)
            Text(title)
                .font(.caption2.weight(.bold))
                .tracking(0.9)
                .foregroundStyle(.white.opacity(0.36))
            Rectangle().fill(.white.opacity(0.1)).frame(height: 1)
        }
        .padding(.vertical, 2)
        .accessibilityLabel(title)
    }
}

private struct ChatMessageBubble: View {
    @EnvironmentObject private var store: MaxPrototypeStore

    let message: MaxChatMessage
    let conversationID: String
    let openMedia: (String) -> Void
    let onReply: () -> Void
    let onOpenThread: () -> Void
    let onReact: () -> Void
    var allowsThreadAction = true

    private var mediaIDs: [String] {
        store.mediaIDs(for: message.id, in: conversationID)
    }

    private var reactions: [String] {
        store.reactions(for: message.id, in: conversationID)
    }

    private var deliveryState: ChatDeliveryState {
        store.deliveryState(for: message.id)
    }

    private var threadCount: Int {
        store.threadReplyCount(for: message.id, in: conversationID)
    }

    private var parentMessage: MaxChatMessage? {
        guard let parentID = store.parentMessageID(for: message.id) else { return nil }
        return store.message(id: parentID, in: conversationID)
    }

    var body: some View {
        HStack(alignment: .bottom) {
            if message.isMine { Spacer(minLength: 46) }

            VStack(alignment: message.isMine ? .trailing : .leading, spacing: 6) {
                if !message.isMine {
                    HStack(spacing: 6) {
                        Text(message.author)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.52))
                        if store.isMessagePinned(message.id) {
                            Image(systemName: "pin.fill")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white.opacity(0.42))
                        }
                    }
                }

                if let parentMessage {
                    ChatReplyContext(message: parentMessage)
                }

                if !mediaIDs.isEmpty {
                    ChatMediaAlbum(mediaIDs: mediaIDs, conversationID: conversationID, openMedia: openMedia)
                }

                if !message.text.isEmpty {
                    Text(message.text)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(message.isMine ? .white.opacity(0.16) : .white.opacity(0.08), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                }

                if !reactions.isEmpty {
                    HStack(spacing: 5) {
                        ForEach(reactions, id: \.self) { reaction in
                            Button(reaction) {
                                store.toggleReaction(reaction, to: message.id, in: conversationID)
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.82))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(.white.opacity(0.1), in: Capsule())
                            .buttonStyle(.plain)
                            .accessibilityLabel("Remove \(reaction) reaction")
                        }
                        Button {
                            onReact()
                        } label: {
                            Image(systemName: "plus")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white.opacity(0.55))
                                .padding(5)
                                .background(.white.opacity(0.07), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add reaction")
                    }
                }

                HStack(spacing: 7) {
                    if allowsThreadAction, threadCount > 0 {
                        Button("\(threadCount) \(threadCount == 1 ? "reply" : "replies")") {
                            onOpenThread()
                        }
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.65))
                        .buttonStyle(.plain)
                    } else if allowsThreadAction {
                        Button("Reply") {
                            onReply()
                        }
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.46))
                        .buttonStyle(.plain)
                    }

                    Text(message.timeLabel)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))

                    if message.isMine {
                        Image(systemName: deliveryState.icon)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(deliveryState == .failed ? .white.opacity(0.9) : .white.opacity(0.42))
                            .accessibilityLabel(deliveryState.title)
                    }
                }
            }
            .contextMenu {
                Button("Reply", systemImage: "arrowshape.turn.up.left") { onReply() }
                Button("React", systemImage: "face.smiling") { onReact() }
                if allowsThreadAction {
                    Button(threadCount > 0 ? "View Thread" : "Start Thread", systemImage: "bubble.left.and.bubble.right") { onOpenThread() }
                }
                Button(store.isMessagePinned(message.id) ? "Unpin Message" : "Pin Message", systemImage: store.isMessagePinned(message.id) ? "pin.slash" : "pin") {
                    store.togglePinnedMessage(message.id)
                }
                if message.isMine && deliveryState == .failed {
                    Button("Retry", systemImage: "arrow.clockwise") {
                        store.retryMessage(message.id, in: conversationID)
                    }
                }
                if message.isMine && deliveryState != .failed {
                    Button("Preview Failed Send", systemImage: "exclamationmark.circle") {
                        store.simulateMessageFailure(message.id, in: conversationID)
                    }
                }
                if message.isMine {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        store.deleteMessage(message.id, in: conversationID)
                    }
                }
            }

            if !message.isMine { Spacer(minLength: 46) }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct ChatReplyContext: View {
    let message: MaxChatMessage

    var body: some View {
        HStack(spacing: 7) {
            Rectangle()
                .fill(.white.opacity(0.45))
                .frame(width: 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(message.author)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.72))
                Text(message.text.isEmpty ? "Shared private media" : message.text)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.47))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

private struct ChatMediaAlbum: View {
    @EnvironmentObject private var store: MaxPrototypeStore

    let mediaIDs: [String]
    let conversationID: String
    let openMedia: (String) -> Void

    private var items: [MaxMediaItem] {
        mediaIDs.compactMap { store.mediaItem(id: $0) }
    }

    var body: some View {
        Group {
            if items.count == 1, let item = items.first {
                ChatMediaTile(item: item, openMedia: openMedia, large: true)
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 5), GridItem(.flexible(), spacing: 5)], spacing: 5) {
                    ForEach(Array(items.prefix(4))) { item in
                        ZStack {
                            ChatMediaTile(item: item, openMedia: openMedia, large: false)
                            if item.id == items.prefix(4).last?.id && items.count > 4 {
                                Text("+\(items.count - 4)")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(.black.opacity(0.48), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                            }
                        }
                    }
                }
                .frame(width: 224)
            }
        }
        .padding(7)
        .maxSurface(cornerRadius: 20)
        .accessibilityLabel("Shared media album with \(items.count) items")
    }
}

private struct ChatMediaTile: View {
    @EnvironmentObject private var store: MaxPrototypeStore

    let item: MaxMediaItem
    let openMedia: (String) -> Void
    let large: Bool

    var body: some View {
        Button {
            HapticFeedback.tap()
            if item.isLocked {
                store.requestAccess(for: item.id)
            } else {
                openMedia(item.id)
            }
        } label: {
            ZStack(alignment: .bottomLeading) {
                MaxMediaArtwork(item: item, height: large ? 142 : 104, showsProgress: item.downloadState != nil)
                    .frame(width: large ? 214 : nil)
                LinearGradient(colors: [.clear, .black.opacity(0.74)], startPoint: .top, endPoint: .bottom)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    if item.isLocked {
                        Label(item.requestAccessSent ? "Access requested" : "Shared privately", systemImage: item.requestAccessSent ? "checkmark.circle.fill" : "lock.fill")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    Text(item.title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.isLocked ? "\(item.title), shared privately. Request access." : "Open \(item.title)")
    }
}

private struct MaxChatThreadSheet: View {
    @EnvironmentObject private var store: MaxPrototypeStore
    @Environment(\.dismiss) private var dismiss
    @FocusState private var composerFocused: Bool

    let conversationID: String
    let rootMessageID: String
    let openMedia: (String) -> Void

    @State private var composer = ""
    @State private var reactionTargetID: String?

    private var rootMessage: MaxChatMessage? {
        store.message(id: rootMessageID, in: conversationID)
    }

    private var replies: [MaxChatMessage] {
        store.threadReplies(for: rootMessageID, in: conversationID)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if let rootMessage {
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ChatMessageBubble(
                                    message: rootMessage,
                                    conversationID: conversationID,
                                    openMedia: openMedia,
                                    onReply: {},
                                    onOpenThread: {},
                                    onReact: { reactionTargetID = rootMessage.id },
                                    allowsThreadAction: false
                                )

                                HStack(spacing: 10) {
                                    Rectangle().fill(.white.opacity(0.1)).frame(height: 1)
                                    Text("\(replies.count) \(replies.count == 1 ? "reply" : "replies")")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white.opacity(0.45))
                                    Rectangle().fill(.white.opacity(0.1)).frame(height: 1)
                                }
                                .padding(.vertical, 3)

                                if replies.isEmpty {
                                    MaxEmptyState(
                                        symbol: "bubble.left",
                                        title: "Start the thread",
                                        detail: "Reply below to keep this private conversation focused.",
                                        actionTitle: nil,
                                        action: {}
                                    )
                                } else {
                                    ForEach(replies) { reply in
                                        ChatMessageBubble(
                                            message: reply,
                                            conversationID: conversationID,
                                            openMedia: openMedia,
                                            onReply: {},
                                            onOpenThread: {},
                                            onReact: { reactionTargetID = reply.id },
                                            allowsThreadAction: false
                                        )
                                        .id(reply.id)
                                    }
                                }
                                Color.clear.frame(height: 1).id("thread-bottom")
                            }
                            .padding(16)
                        }
                        .onChange(of: replies.count) { _, _ in
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo("thread-bottom", anchor: .bottom)
                            }
                        }
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        HStack(alignment: .bottom, spacing: 8) {
                            TextField("Reply in thread", text: $composer, axis: .vertical)
                                .focused($composerFocused)
                                .lineLimit(1...4)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .maxSurface(cornerRadius: 18)
                            Button {
                                store.sendText(composer, to: conversationID, replyTo: rootMessageID)
                                composer = ""
                            } label: {
                                Image(systemName: "arrow.up")
                                    .font(.body.weight(.bold))
                            }
                            .buttonStyle(.plain)
                            .glassCircleButton(diameter: 40, isActive: !composer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .disabled(composer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .accessibilityLabel("Send thread reply")
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.94))
                    }
                }
            }
            .navigationTitle("Thread")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog(
            "React to message",
            isPresented: Binding(
                get: { reactionTargetID != nil },
                set: { if !$0 { reactionTargetID = nil } }
            ),
            titleVisibility: .visible
        ) {
            ForEach(["♥︎", "✨", "😂", "!!", "👀"], id: \.self) { reaction in
                Button(reaction) {
                    if let reactionTargetID {
                        store.toggleReaction(reaction, to: reactionTargetID, in: conversationID)
                    }
                    self.reactionTargetID = nil
                }
            }
        }
    }
}

private struct MaxConversationInfoSheet: View {
    @EnvironmentObject private var store: MaxPrototypeStore
    @Environment(\.dismiss) private var dismiss

    let conversationID: String
    let openMedia: (String) -> Void

    private var conversation: MaxConversation? {
        store.conversation(id: conversationID)
    }

    private var sharedMedia: [MaxMediaItem] {
        guard let conversation else { return [] }
        var identifiers = Set<String>()
        return conversation.messages
            .flatMap { store.mediaIDs(for: $0.id, in: conversationID) }
            .filter { identifiers.insert($0).inserted }
            .compactMap { store.mediaItem(id: $0) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if let conversation {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 18) {
                            HStack(spacing: 13) {
                                Image(systemName: conversation.isGroup ? "person.3.fill" : "person.fill")
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 58, height: 58)
                                    .background(.white.opacity(0.11), in: Circle())
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(conversation.title)
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(.white)
                                    Text(conversation.isGroup ? "Invite-only private group" : "Private direct message")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.56))
                                }
                            }
                            .padding(14)
                            .maxSurface(cornerRadius: 24)

                            HStack(spacing: 10) {
                                Button {
                                    store.togglePinnedConversation(conversationID)
                                } label: {
                                    Label(store.isConversationPinned(conversationID) ? "Unpin" : "Pin", systemImage: store.isConversationPinned(conversationID) ? "pin.slash.fill" : "pin.fill")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 11)
                                        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .buttonStyle(.plain)

                                Button {
                                    store.toggleMutedConversation(conversationID)
                                } label: {
                                    Label(store.isConversationMuted(conversationID) ? "Unmute" : "Mute", systemImage: store.isConversationMuted(conversationID) ? "bell.fill" : "bell.slash.fill")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 11)
                                        .maxSurface(cornerRadius: 16)
                                }
                                .buttonStyle(.plain)
                            }

                            sectionHeader("PEOPLE · \(conversation.members.count)")
                            VStack(spacing: 7) {
                                ForEach(conversation.members, id: \.self) { member in
                                    HStack(spacing: 10) {
                                        Image(systemName: member == "You" ? "person.crop.circle.fill" : "person.crop.circle")
                                            .font(.title3)
                                            .foregroundStyle(.white.opacity(0.74))
                                        Text(member)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white)
                                        Spacer()
                                        if member == "You" {
                                            Text("You")
                                                .font(.caption2.weight(.bold))
                                                .foregroundStyle(.black)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(.white, in: Capsule())
                                        } else if conversation.isGroup && member == conversation.members.dropFirst().first {
                                            Text("Owner")
                                                .font(.caption2.weight(.bold))
                                                .foregroundStyle(.white.opacity(0.56))
                                        }
                                    }
                                    .padding(11)
                                    .maxSurface(cornerRadius: 16)
                                }
                            }

                            sectionHeader("SHARED MEDIA · \(sharedMedia.count)")
                            if sharedMedia.isEmpty {
                                MaxEmptyState(
                                    symbol: "photo.on.rectangle.angled",
                                    title: "No shared media yet",
                                    detail: "Media sent here appears as a private reference.",
                                    actionTitle: nil,
                                    action: {}
                                )
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(sharedMedia) { item in
                                            Button {
                                                if item.isLocked {
                                                    store.requestAccess(for: item.id)
                                                } else {
                                                    openMedia(item.id)
                                                }
                                            } label: {
                                                VStack(alignment: .leading, spacing: 7) {
                                                    MaxMediaArtwork(item: item, height: 110, showsProgress: item.downloadState != nil)
                                                        .frame(width: 155)
                                                    Text(item.title)
                                                        .font(.caption.weight(.semibold))
                                                        .foregroundStyle(.white)
                                                        .lineLimit(1)
                                                }
                                                .padding(7)
                                                .maxSurface(cornerRadius: 18)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Conversation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .tracking(1)
            .foregroundStyle(.white.opacity(0.45))
    }
}

private struct ChatAttachmentPicker: View {
    @EnvironmentObject private var store: MaxPrototypeStore
    @Environment(\.dismiss) private var dismiss

    let kind: MediaKind
    let conversationID: String

    @State private var selectedIDs: Set<String> = []
    @State private var caption = ""

    private var options: [MaxMediaItem] {
        store.media.filter { $0.kind == kind && !$0.isLocked }
    }

    private var orderedSelectedIDs: [String] {
        options.filter { selectedIDs.contains($0.id) }.map(\.id)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
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
                                .accessibilityLabel("\(selectedIDs.contains(item.id) ? "Remove" : "Select") \(item.title)")
                            }
                        }
                        .padding(20)
                    }

                    VStack(spacing: 9) {
                        TextField("Add a caption", text: $caption, axis: .vertical)
                            .lineLimit(1...3)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .maxSurface(cornerRadius: 17)
                        HStack {
                            Text("\(selectedIDs.count) selected · one private message")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                            Spacer()
                            Button("Send") {
                                store.sendMedia(
                                    templateIDs: orderedSelectedIDs,
                                    caption: caption,
                                    recipientID: conversationID,
                                    allowDownloads: true
                                )
                                dismiss()
                            }
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(selectedIDs.isEmpty ? .black.opacity(0.38) : .black)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(.white.opacity(selectedIDs.isEmpty ? 0.42 : 1), in: Capsule())
                            .buttonStyle(.plain)
                            .disabled(selectedIDs.isEmpty)
                        }
                    }
                    .padding(14)
                    .background(.black.opacity(0.94))
                }
            }
            .navigationTitle("Attach \(kind.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
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
            HStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(width: 38, height: 38)
                    .background(.white, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Create Private Group")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Invite-only, with shared media references.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.56))
                }
            }

            TextField("Group name", text: $name)
                .foregroundStyle(.white)
                .padding(13)
                .maxSurface(cornerRadius: 18)

            VStack(alignment: .leading, spacing: 8) {
                Text("INVITE PEOPLE")
                    .font(.caption2.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.5))
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
                            Image(systemName: "person.crop.circle")
                                .font(.title3)
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
