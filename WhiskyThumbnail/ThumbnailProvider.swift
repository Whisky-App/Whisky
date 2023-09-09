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
        let thumbnailSize = CGSize(width: request.maximumSize.width,
                                   height: request.maximumSize.height)

        // % of thumbnail occupied by icon
        let iconScaleFactor = 0.9
        let whiskyIconScaleFactor = 0.4

        // AppKit coordinate system origin is in the bottom-left
        // Icon is centered
        let iconFrame = CGRect(x: (request.maximumSize.width - request.maximumSize.width * iconScaleFactor) / 2.0,
                               y: (request.maximumSize.height - request.maximumSize.height * iconScaleFactor) / 2.0,
                               width: request.maximumSize.width * iconScaleFactor,
                               height: request.maximumSize.height * iconScaleFactor)

        // Whisky icon is aligned bottom-right
        let whiskyIconFrame = CGRect(x: request.maximumSize.width - request.maximumSize.width * whiskyIconScaleFactor,
                                     y: 0,
                                     width: request.maximumSize.width * whiskyIconScaleFactor,
                                     height: request.maximumSize.height * whiskyIconScaleFactor)
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

            let reply: QLThumbnailReply = QLThumbnailReply.init(contextSize: thumbnailSize) { () -> Bool in
                if let image = image {
                    image.draw(in: iconFrame)
                    let whiskyIcon = NSImage(named: NSImage.Name("Icon"))
                    whiskyIcon?.draw(in: whiskyIconFrame, from: .zero, operation: .sourceOver, fraction: 1)
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
