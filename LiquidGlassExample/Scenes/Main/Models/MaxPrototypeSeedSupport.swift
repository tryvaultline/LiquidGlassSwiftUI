import SwiftUI

extension MaxPrototypeStore {
    func ensurePhotoSeed() {
        guard !media.contains(where: { $0.id == "window-light" }) else { return }

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
}
