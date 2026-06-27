import SwiftUI

enum MaxTab: String, CaseIterable, Identifiable {
    case home
    case library
    case create
    case chats
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .library: "Library"
        case .create: "Create"
        case .chats: "Chats"
        case .profile: "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .library: "rectangle.stack.fill"
        case .create: "plus"
        case .chats: "bubble.left.and.bubble.right.fill"
        case .profile: "person.crop.circle.fill"
        }
    }
}

enum MediaKind: String, CaseIterable, Identifiable {
    case video
    case photo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .video: "Video"
        case .photo: "Photo"
        }
    }

    var icon: String {
        switch self {
        case .video: "play.rectangle.fill"
        case .photo: "photo.fill"
        }
    }
}

enum MediaPrivacy: String, CaseIterable, Identifiable {
    case direct = "Direct"
    case group = "Group"
    case privateOnly = "Private"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .direct: "person.fill"
        case .group: "person.2.fill"
        case .privateOnly: "lock.fill"
        }
    }
}

enum DownloadState: String, CaseIterable, Identifiable {
    case downloading
    case queued
    case completed
    case paused
    case failed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .downloading: "Downloading"
        case .queued: "Queued"
        case .completed: "Completed"
        case .paused: "Paused"
        case .failed: "Failed"
        }
    }

    var icon: String {
        switch self {
        case .downloading: "arrow.down.circle.fill"
        case .queued: "clock.fill"
        case .completed: "checkmark.circle.fill"
        case .paused: "pause.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        }
    }
}

enum UploadState: String, CaseIterable, Identifiable {
    case preparing
    case uploading
    case readyToSend
    case sent
    case failed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .preparing: "Preparing"
        case .uploading: "Uploading"
        case .readyToSend: "Ready to Send"
        case .sent: "Sent"
        case .failed: "Failed"
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "English"
    case arabic = "العربية"

    var id: String { rawValue }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system = "System"
    case dark = "Dark"

    var id: String { rawValue }
}

enum ChatDeliveryState: String, CaseIterable, Identifiable {
    case sending
    case sent
    case delivered
    case failed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sending: "Sending"
        case .sent: "Sent"
        case .delivered: "Delivered"
        case .failed: "Failed"
        }
    }

    var icon: String {
        switch self {
        case .sending: "clock"
        case .sent: "checkmark"
        case .delivered: "checkmark.circle.fill"
        case .failed: "exclamationmark.circle.fill"
        }
    }
}

struct MaxMediaItem: Identifiable, Hashable {
    let id: String
    var title: String
    var kind: MediaKind
    var owner: String
    var dateLabel: String
    var privacy: MediaPrivacy
    var duration: String
    var sizeLabel: String
    var icon: String
    var isDownloadAvailable: Bool
    var isLocked: Bool
    var requestAccessSent: Bool
    var isSaved: Bool
    var isLiked: Bool
    var rating: Int?
    var isWatched: Bool
    var downloadState: DownloadState?
    var downloadProgress: Double
    var caption: String

    var metadataLine: String {
        "\(kind.title) · \(owner) · \(dateLabel)"
    }
}

struct MaxChatMessage: Identifiable, Hashable {
    let id: String
    var author: String
    var text: String
    var mediaID: String?
    var timeLabel: String
    var reaction: String?
    var isMine: Bool
}

struct MaxConversation: Identifiable, Hashable {
    let id: String
    var title: String
    var isGroup: Bool
    var members: [String]
    var unreadCount: Int
    var messages: [MaxChatMessage]

    var lastMessage: MaxChatMessage? { messages.last }

    var lastPreview: String {
        guard let lastMessage else { return "No messages yet" }
        if lastMessage.mediaID != nil {
            return lastMessage.text.isEmpty ? "Shared media" : lastMessage.text
        }
        return lastMessage.text
    }

    var lastTime: String {
        lastMessage?.timeLabel ?? ""
    }
}

struct PrototypeToast: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let detail: String
    let symbol: String
}

@MainActor
final class MaxPrototypeStore: ObservableObject {
    @Published var media: [MaxMediaItem]
    @Published var conversations: [MaxConversation]
    @Published var isOfflineMode = false
    @Published var isScreenLocked = true
    @Published var screenLockEnabled = true
    @Published var language: AppLanguage = .english
    @Published var appearance: AppAppearance = .dark
    @Published var toast: PrototypeToast?

    // Local-only chat presentation state. This deliberately has no API, socket, or persistence layer.
    @Published private(set) var messageMediaAlbums: [String: [String]] = [:]
    @Published private(set) var messageDeliveries: [String: ChatDeliveryState] = [:]
    @Published private(set) var messageParents: [String: String] = [:]
    @Published private(set) var messageReactions: [String: [String]] = [:]
    @Published private(set) var pinnedMessageIDs: Set<String> = []
    @Published private(set) var pinnedConversationIDs: Set<String> = []
    @Published private(set) var mutedConversationIDs: Set<String> = []

    init() {
        media = [
            MaxMediaItem(
                id: "afterlight",
                title: "Afterlight",
                kind: .video,
                owner: "Weekend Group",
                dateLabel: "Today",
                privacy: .group,
                duration: "18:42",
                sizeLabel: "842 MB",
                icon: "moon.stars.fill",
                isDownloadAvailable: true,
                isLocked: false,
                requestAccessSent: false,
                isSaved: false,
                isLiked: false,
                rating: nil,
                isWatched: false,
                downloadState: .downloading,
                downloadProgress: 0.64,
                caption: "A quiet cut from the weekend."
            ),
            MaxMediaItem(
                id: "paper-cities",
                title: "Paper Cities",
                kind: .video,
                owner: "Noura",
                dateLabel: "Yesterday",
                privacy: .direct,
                duration: "09:28",
                sizeLabel: "620 MB",
                icon: "building.2.fill",
                isDownloadAvailable: true,
                isLocked: false,
                requestAccessSent: false,
                isSaved: true,
                isLiked: true,
                rating: 9,
                isWatched: true,
                downloadState: .completed,
                downloadProgress: 1,
                caption: "Saved from a private conversation."
            ),
            MaxMediaItem(
                id: "low-signal",
                title: "Low Signal",
                kind: .video,
                owner: "Noura",
                dateLabel: "Jun 24",
                privacy: .direct,
                duration: "05:14",
                sizeLabel: "415 MB",
                icon: "antenna.radiowaves.left.and.right",
                isDownloadAvailable: true,
                isLocked: false,
                requestAccessSent: false,
                isSaved: false,
                isLiked: false,
                rating: nil,
                isWatched: true,
                downloadState: .paused,
                downloadProgress: 0.42,
                caption: "One more scene for the road."
            ),
            MaxMediaItem(
                id: "weekend-clips",
                title: "Weekend clips",
                kind: .video,
                owner: "Weekend Group",
                dateLabel: "Jun 23",
                privacy: .group,
                duration: "12 clips",
                sizeLabel: "1.1 GB",
                icon: "film.stack.fill",
                isDownloadAvailable: true,
                isLocked: false,
                requestAccessSent: false,
                isSaved: false,
                isLiked: false,
                rating: nil,
                isWatched: false,
                downloadState: .queued,
                downloadProgress: 0,
                caption: "Three new clips from your private group."
            ),
            MaxMediaItem(
                id: "rooftop-still",
                title: "Rooftop stills",
                kind: .photo,
                owner: "Maya",
                dateLabel: "Jun 19",
                privacy: .direct,
                duration: "6 photos",
                sizeLabel: "186 MB",
                icon: "photo.on.rectangle.angled",
                isDownloadAvailable: false,
                isLocked: true,
                requestAccessSent: false,
                isSaved: false,
                isLiked: false,
                rating: nil,
                isWatched: false,
                downloadState: nil,
                downloadProgress: 0,
                caption: "Ask Maya to view this private album."
            )
        ]

        conversations = [
            MaxConversation(
                id: "weekend-group",
                title: "Weekend Group",
                isGroup: true,
                members: ["You", "Noura", "Maya", "Sami"],
                unreadCount: 3,
                messages: [
                    MaxChatMessage(id: "weekend-1", author: "Noura", text: "Three new clips from Weekend Group", mediaID: "weekend-clips", timeLabel: "09:42", reaction: "✨", isMine: false),
                    MaxChatMessage(id: "weekend-2", author: "Sami", text: "That last scene is my favorite", mediaID: nil, timeLabel: "09:44", reaction: nil, isMine: false)
                ]
            ),
            MaxConversation(
                id: "noura-dm",
                title: "Noura",
                isGroup: false,
                members: ["You", "Noura"],
                unreadCount: 1,
                messages: [
                    MaxChatMessage(id: "noura-1", author: "Noura", text: "I kept this one for you", mediaID: "paper-cities", timeLabel: "Yesterday", reaction: "♥︎", isMine: false),
                    MaxChatMessage(id: "noura-2", author: "You", text: "Saved it. It is beautiful.", mediaID: nil, timeLabel: "Yesterday", reaction: nil, isMine: true)
                ]
            ),
            MaxConversation(
                id: "max-notes",
                title: "Max Notes",
                isGroup: true,
                members: ["You", "Noura", "Sami"],
                unreadCount: 0,
                messages: [
                    MaxChatMessage(id: "notes-1", author: "Sami", text: "The private player flow is ready to try.", mediaID: nil, timeLabel: "Mon", reaction: nil, isMine: false)
                ]
            )
        ]

        messageMediaAlbums = ["weekend-1": ["weekend-clips"]]
        messageDeliveries = [
            "weekend-1": .delivered,
            "weekend-2": .delivered,
            "noura-1": .delivered,
            "noura-2": .delivered,
            "notes-1": .delivered
        ]
        messageReactions = ["weekend-1": ["✨"], "noura-1": ["♥︎"]]
    }

    var savedMedia: [MaxMediaItem] {
        media.filter(\.isSaved)
    }

    var watchedMedia: [MaxMediaItem] {
        media.filter(\.isWatched)
    }

    var ratedMedia: [MaxMediaItem] {
        media.filter { $0.rating != nil }
    }

    var downloads: [MaxMediaItem] {
        media.filter { $0.downloadState != nil }
    }

    var usedStorageText: String {
        "3.8 GB"
    }

    var storageCapacityText: String {
        "10 GB"
    }

    var storageProgress: Double {
        0.38
    }

    func mediaItem(id: String) -> MaxMediaItem? {
        media.first { $0.id == id }
    }

    func conversation(id: String) -> MaxConversation? {
        conversations.first { $0.id == id }
    }

    func message(id: String, in conversationID: String) -> MaxChatMessage? {
        conversation(id: conversationID)?.messages.first { $0.id == id }
    }

    func mediaIDs(for messageID: String, in conversationID: String) -> [String] {
        if let album = messageMediaAlbums[messageID] {
            return album
        }
        guard let mediaID = message(id: messageID, in: conversationID)?.mediaID else { return [] }
        return [mediaID]
    }

    func deliveryState(for messageID: String) -> ChatDeliveryState {
        messageDeliveries[messageID] ?? .delivered
    }

    func parentMessageID(for messageID: String) -> String? {
        messageParents[messageID]
    }

    func threadReplies(for messageID: String, in conversationID: String) -> [MaxChatMessage] {
        conversation(id: conversationID)?.messages.filter { messageParents[$0.id] == messageID } ?? []
    }

    func threadReplyCount(for messageID: String, in conversationID: String) -> Int {
        threadReplies(for: messageID, in: conversationID).count
    }

    func reactions(for messageID: String, in conversationID: String) -> [String] {
        if let reactions = messageReactions[messageID] {
            return reactions
        }
        guard let legacyReaction = message(id: messageID, in: conversationID)?.reaction else { return [] }
        return [legacyReaction]
    }

    func isConversationPinned(_ conversationID: String) -> Bool {
        pinnedConversationIDs.contains(conversationID)
    }

    func isConversationMuted(_ conversationID: String) -> Bool {
        mutedConversationIDs.contains(conversationID)
    }

    func isMessagePinned(_ messageID: String) -> Bool {
        pinnedMessageIDs.contains(messageID)
    }

    func markWatched(_ mediaID: String) {
        updateMedia(mediaID) { $0.isWatched = true }
    }

    func toggleSaved(_ mediaID: String) {
        updateMedia(mediaID) { item in
            item.isSaved.toggle()
            showSuccess(item.isSaved ? "Saved to Library" : "Removed from Saved", detail: item.title, symbol: item.isSaved ? "bookmark.fill" : "bookmark")
        }
    }

    func toggleLiked(_ mediaID: String) {
        updateMedia(mediaID) { item in
            item.isLiked.toggle()
            showSuccess(item.isLiked ? "Added a like" : "Like removed", detail: item.title, symbol: item.isLiked ? "heart.fill" : "heart")
        }
    }

    func setRating(_ value: Int, for mediaID: String) {
        updateMedia(mediaID) { item in
            item.rating = value
            showSuccess("Rated \(value) / 10", detail: item.title, symbol: "star.fill")
        }
    }

    func requestAccess(for mediaID: String) {
        updateMedia(mediaID) { item in
            item.requestAccessSent = true
            showSuccess("Request Access Sent", detail: "Maya will be notified in this prototype.", symbol: "checkmark.circle.fill")
        }
    }

    func toggleDownload(for mediaID: String) {
        updateMedia(mediaID) { item in
            guard item.isDownloadAvailable else {
                showSuccess("Download unavailable", detail: "The owner has not allowed offline copies.", symbol: "lock.fill")
                return
            }

            switch item.downloadState {
            case .downloading:
                item.downloadState = .paused
                showSuccess("Download Paused", detail: item.title, symbol: "pause.circle.fill")
            case .paused, .queued, .failed, nil:
                item.downloadState = .downloading
                item.downloadProgress = max(item.downloadProgress, 0.08)
                showSuccess("Download Started", detail: item.title, symbol: "arrow.down.circle.fill")
            case .completed:
                showSuccess("Available Offline", detail: item.title, symbol: "checkmark.circle.fill")
            }
        }
    }

    func retryDownload(for mediaID: String) {
        updateMedia(mediaID) { item in
            item.downloadState = .downloading
            item.downloadProgress = max(item.downloadProgress, 0.12)
            showSuccess("Download Retried", detail: item.title, symbol: "arrow.clockwise.circle.fill")
        }
    }

    func deleteLocalDownload(for mediaID: String) {
        updateMedia(mediaID) { item in
            item.downloadState = nil
            item.downloadProgress = 0
            showSuccess("Local Download Deleted", detail: "The source media is still in your Library.", symbol: "trash.fill")
        }
    }

    func simulateDownloadFailure(for mediaID: String) {
        updateMedia(mediaID) { item in
            item.downloadState = .failed
            showSuccess("Download Failed", detail: "Use Retry to continue this local prototype flow.", symbol: "exclamationmark.triangle.fill")
        }
    }

    func sendMedia(
        templateIDs: [String],
        caption: String,
        recipientID: String,
        allowDownloads: Bool
    ) {
        guard let recipientIndex = conversations.firstIndex(where: { $0.id == recipientID }) else { return }

        var createdIDs: [String] = []
        for templateID in templateIDs {
            guard let template = mediaItem(id: templateID) else { continue }
            let newID = "shared-\(UUID().uuidString)"
            let recipient = conversations[recipientIndex]
            let created = MaxMediaItem(
                id: newID,
                title: template.title + " · Shared",
                kind: template.kind,
                owner: "You",
                dateLabel: "Just now",
                privacy: recipient.isGroup ? .group : .direct,
                duration: template.duration,
                sizeLabel: template.sizeLabel,
                icon: template.icon,
                isDownloadAvailable: allowDownloads,
                isLocked: false,
                requestAccessSent: false,
                isSaved: false,
                isLiked: false,
                rating: nil,
                isWatched: false,
                downloadState: nil,
                downloadProgress: 0,
                caption: caption
            )
            media.insert(created, at: 0)
            createdIDs.append(newID)
        }

        guard let firstMediaID = createdIDs.first else { return }
        let messageID = "media-\(UUID().uuidString)"
        let message = MaxChatMessage(
            id: messageID,
            author: "You",
            text: caption.isEmpty ? "Shared privately" : caption,
            mediaID: firstMediaID,
            timeLabel: "Now",
            reaction: nil,
            isMine: true
        )
        conversations[recipientIndex].messages.append(message)
        messageMediaAlbums[messageID] = createdIDs
        messageDeliveries[messageID] = .sending
        settleMessage(messageID)
        showSuccess("Sent Privately", detail: "Added to \(conversations[recipientIndex].title) and your Library.", symbol: "paperplane.fill")
    }

    func sendText(_ text: String, to conversationID: String, replyTo parentMessageID: String? = nil) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty,
              let index = conversations.firstIndex(where: { $0.id == conversationID }) else { return }

        let messageID = "text-\(UUID().uuidString)"
        conversations[index].messages.append(
            MaxChatMessage(
                id: messageID,
                author: "You",
                text: trimmedText,
                mediaID: nil,
                timeLabel: "Now",
                reaction: nil,
                isMine: true
            )
        )
        if let parentMessageID {
            messageParents[messageID] = parentMessageID
        }
        messageDeliveries[messageID] = .sending
        settleMessage(messageID)
    }

    func retryMessage(_ messageID: String, in conversationID: String) {
        guard message(id: messageID, in: conversationID) != nil else { return }
        messageDeliveries[messageID] = .sending
        settleMessage(messageID)
        showSuccess("Message Retried", detail: "Sending again in this local prototype.", symbol: "arrow.clockwise.circle.fill")
    }

    func simulateMessageFailure(_ messageID: String, in conversationID: String) {
        guard message(id: messageID, in: conversationID) != nil else { return }
        messageDeliveries[messageID] = .failed
        showSuccess("Message Failed", detail: "Use Retry to continue this prototype flow.", symbol: "exclamationmark.triangle.fill")
    }

    func deleteMessage(_ messageID: String, in conversationID: String) {
        guard let conversationIndex = conversations.firstIndex(where: { $0.id == conversationID }) else { return }
        var identifiersToRemove: Set<String> = [messageID]
        var didFindNewReplies = true
        while didFindNewReplies {
            didFindNewReplies = false
            for (childID, parentID) in messageParents where identifiersToRemove.contains(parentID) && !identifiersToRemove.contains(childID) {
                identifiersToRemove.insert(childID)
                didFindNewReplies = true
            }
        }
        conversations[conversationIndex].messages.removeAll { identifiersToRemove.contains($0.id) }
        for id in identifiersToRemove {
            messageMediaAlbums[id] = nil
            messageDeliveries[id] = nil
            messageParents[id] = nil
            messageReactions[id] = nil
            pinnedMessageIDs.remove(id)
        }
        showSuccess("Message Deleted", detail: "Removed from this local conversation.", symbol: "trash.fill")
    }

    func toggleReaction(_ reaction: String, to messageID: String, in conversationID: String) {
        guard message(id: messageID, in: conversationID) != nil else { return }
        var current = reactions(for: messageID, in: conversationID)
        if let index = current.firstIndex(of: reaction) {
            current.remove(at: index)
        } else {
            current.append(reaction)
        }
        messageReactions[messageID] = current
        HapticFeedback.selection()
    }

    func react(to messageID: String, in conversationID: String, reaction: String) {
        toggleReaction(reaction, to: messageID, in: conversationID)
    }

    func togglePinnedMessage(_ messageID: String) {
        if pinnedMessageIDs.contains(messageID) {
            pinnedMessageIDs.remove(messageID)
            showSuccess("Message Unpinned", detail: "Removed from pinned messages.", symbol: "pin.slash.fill")
        } else {
            pinnedMessageIDs.insert(messageID)
            showSuccess("Message Pinned", detail: "Saved at the top of this prototype chat.", symbol: "pin.fill")
        }
    }

    func togglePinnedConversation(_ conversationID: String) {
        if pinnedConversationIDs.contains(conversationID) {
            pinnedConversationIDs.remove(conversationID)
            showSuccess("Chat Unpinned", detail: "Removed from the top of your inbox.", symbol: "pin.slash.fill")
        } else {
            pinnedConversationIDs.insert(conversationID)
            showSuccess("Chat Pinned", detail: "Kept at the top of your inbox.", symbol: "pin.fill")
        }
    }

    func toggleMutedConversation(_ conversationID: String) {
        if mutedConversationIDs.contains(conversationID) {
            mutedConversationIDs.remove(conversationID)
            showSuccess("Notifications Restored", detail: "This local chat is no longer muted.", symbol: "bell.fill")
        } else {
            mutedConversationIDs.insert(conversationID)
            showSuccess("Chat Muted", detail: "Muted locally in this prototype.", symbol: "bell.slash.fill")
        }
    }

    func markConversationRead(_ conversationID: String) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationID }) else { return }
        conversations[index].unreadCount = 0
    }

    func markConversationUnread(_ conversationID: String) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationID }) else { return }
        conversations[index].unreadCount = max(1, conversations[index].unreadCount)
        showSuccess("Marked Unread", detail: conversations[index].title, symbol: "circle.fill")
    }

    func createGroup(named name: String, with members: [String]) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            showSuccess("Group name required", detail: "Give your private group a name first.", symbol: "exclamationmark.circle.fill")
            return
        }
        let conversation = MaxConversation(
            id: "group-\(UUID().uuidString)",
            title: trimmedName,
            isGroup: true,
            members: ["You"] + members,
            unreadCount: 0,
            messages: [
                MaxChatMessage(id: "welcome-\(UUID().uuidString)", author: "Max", text: "Private group created. Only invited people can see this conversation.", mediaID: nil, timeLabel: "Now", reaction: nil, isMine: false)
            ]
        )
        conversations.insert(conversation, at: 0)
        showSuccess("Private Group Created", detail: trimmedName, symbol: "person.3.fill")
    }

    func showSuccess(_ title: String, detail: String, symbol: String = "checkmark.circle.fill") {
        HapticFeedback.success()
        let newToast = PrototypeToast(title: title, detail: detail, symbol: symbol)
        toast = newToast
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            guard self?.toast?.id == newToast.id else { return }
            self?.toast = nil
        }
    }

    private func settleMessage(_ messageID: String) {
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 650_000_000)
            guard self?.messageDeliveries[messageID] == .sending else { return }
            self?.messageDeliveries[messageID] = .delivered
        }
    }

    private func updateMedia(_ mediaID: String, transform: (inout MaxMediaItem) -> Void) {
        guard let index = media.firstIndex(where: { $0.id == mediaID }) else { return }
        transform(&media[index])
    }
}
