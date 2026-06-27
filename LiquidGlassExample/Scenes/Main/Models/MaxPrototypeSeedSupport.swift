import SwiftUI

extension MaxPrototypeStore {
    func ensurePhotoSeed() {
        if !media.contains(where: { $0.id == "window-light" }) {
            media.append(
                MaxMediaItem(
                    id: "window-light",
                    title: "Window Light",
                    kind: .photo,
                    owner: "Noura",
                    dateLabel: "Jun 26",
                    privacy: .direct,
                    duration: "4 photos",
                    sizeLabel: "74 MB",
                    icon: "camera.fill",
                    isDownloadAvailable: true,
                    isLocked: false,
                    requestAccessSent: false,
                    isSaved: false,
                    isLiked: false,
                    rating: nil,
                    isWatched: false,
                    downloadState: nil,
                    downloadProgress: 0,
                    caption: "A photo set shared in a direct chat."
                )
            )
        }

        guard let conversationIndex = conversations.firstIndex(where: { $0.id == "weekend-group" }),
              !conversations[conversationIndex].messages.contains(where: { $0.id == "weekend-locked-media" }) else {
            return
        }

        conversations[conversationIndex].messages.insert(
            MaxChatMessage(
                id: "weekend-locked-media",
                author: "Maya",
                text: "I shared the rooftop stills privately. Request access when you are ready.",
                mediaID: "rooftop-still",
                timeLabel: "09:45",
                reaction: nil,
                isMine: false
            ),
            at: 1
        )
    }
}
