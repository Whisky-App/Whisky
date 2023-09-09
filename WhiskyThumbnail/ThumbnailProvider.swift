//
//  ThumbnailProvider.swift
//  Whisky
//
//  Created by Isaac Marovitz on 09/09/2023.
//

import Foundation
import QuickLookThumbnailing
import AppKit
import WhiskyKit

class ThumbnailProvider: QLThumbnailProvider {
    override func provideThumbnail(for request: QLFileThumbnailRequest,
                                   _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        let thumbnailFrame = CGRect(x: 0, y: 0, width: request.maximumSize.width, height: request.maximumSize.height)
        do {
            var image: NSImage?
            var icons: [NSImage] = []

            let peFile = try PEFile(data: Data(contentsOf: request.fileURL))

            if let resourceSection = peFile.resourceSection {
                for entries in resourceSection.allEntries where entries.icon.isValid {
                    icons.append(entries.icon)
                }
            }

            if icons.count > 0 {
                image = icons[0]
            }

            let reply: QLThumbnailReply = QLThumbnailReply.init(contextSize: thumbnailFrame.size) { () -> Bool in
                if let image = image {
                    image.draw(in: thumbnailFrame)
                    return true
                }

                // We didn't draw anything
                return false
            }

            handler(reply, nil)
        } catch {
            handler(nil, nil)
        }
    }
}
