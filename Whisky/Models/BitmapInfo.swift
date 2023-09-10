//
//  BitmapInfo.swift
//  Whisky
//
//  Created by Isaac Marovitz on 09/09/2023.
//

import Foundation
import AppKit

struct BitmapInfoHeader: Hashable {
    var size: UInt32
    var width: Int32
    var height: Int32
    var planes: UInt16
    var bitCount: UInt16
    var compression: BitmapCompression
    var sizeImage: UInt32
    var xPelsPerMeter: Int32
    var yPelsPerMeter: Int32
    var clrUsed: UInt32
    var clrImportant: UInt32

    var originDirection: BitmapOriginDirection
    var colorFormat: ColorFormat

    init(data: Data, offset: Int) {
        var offset = offset
        self.size = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.width = data.extract(Int32.self, offset: offset) ?? 0
        offset += 4
        self.height = data.extract(Int32.self, offset: offset) ?? 0
        offset += 4
        self.planes = data.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.bitCount = data.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.compression = BitmapCompression(rawValue: data.extract(UInt32.self, offset: offset) ?? 0) ?? .rgb
        offset += 4
        self.sizeImage = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.xPelsPerMeter = data.extract(Int32.self, offset: offset) ?? 0
        offset += 4
        self.yPelsPerMeter = data.extract(Int32.self, offset: offset) ?? 0
        offset += 4
        self.clrUsed = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.clrImportant = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4

        self.originDirection = self.height < 0 ? .upperLeft : .bottomLeft
        self.colorFormat = ColorFormat(rawValue: bitCount) ?? .unknown
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func renderBitmap(data: Data, offset: Int) -> NSImage {
        var offset = offset
        let colorTable = buildColorTable(offset: &offset, data: data)

        var pixels: [ColorQuad] = []

        // Handle bitfields later if necessary

        for _ in 0..<Int(height / 2) {
            var pixelRow: [ColorQuad] = []

            for _ in 0..<width {
                switch colorFormat {
                case .indexed1:
                    // Swift has no data type equivelent to a single bit
                    // This will take some bitwise magic
                    break
                case .indexed2:
                    // Swift's smallest data type is 1 byte 
                    // Ditto .indexed1
                    break
                case .indexed4:
                    // Swift's smallest data type is 1 byte
                    // Ditto .indexed1
                    break
                case .indexed8:
                    let index = data.extract(UInt8.self, offset: offset) ?? 0
                    pixelRow.append(colorTable[Int(index)])
                    offset += 1
                case .sampled16:
                    let sample = data.extract(UInt16.self, offset: offset) ?? 0
                    let red = sample & 0x001F
                    let green = (sample & 0x03E0) >> 5
                    let blue = (sample & 0x7C00) >> 10
                    pixels.append(ColorQuad(red: UInt8(red),
                                            green: UInt8(green),
                                            blue: UInt8(blue),
                                            alpha: 1))
                    offset += 2
                case .sampled24:
                    let blue = data.extract(UInt8.self, offset: offset) ?? 0
                    offset += 1
                    let green = data.extract(UInt8.self, offset: offset) ?? 0
                    offset += 1
                    let red = data.extract(UInt8.self, offset: offset) ?? 0
                    offset += 1
                    pixelRow.append(ColorQuad(red: red,
                                              green: green,
                                              blue: blue,
                                              alpha: 1))
                case .sampled32:
                    let blue = data.extract(UInt8.self, offset: offset) ?? 0
                    offset += 1
                    let green = data.extract(UInt8.self, offset: offset) ?? 0
                    offset += 1
                    let red = data.extract(UInt8.self, offset: offset) ?? 0
                    offset += 1
                    let alpha = data.extract(UInt8.self, offset: offset) ?? 0
                    offset += 1
                    pixelRow.append(ColorQuad(red: red,
                                              green: green,
                                              blue: blue,
                                              alpha: alpha))
                case .unknown:
                    break
                }
            }

            if originDirection == .upperLeft {
                pixels.append(contentsOf: pixelRow)
            } else {
                pixels.insert(contentsOf: pixelRow, at: 0)
            }
        }

        return constructImage(pixels: pixels)
    }

    func buildColorTable(offset: inout Int, data: Data) -> [ColorQuad] {
        var colorTable: [ColorQuad] = []

        for _ in 0..<clrUsed {
            let blue = data.extract(UInt8.self, offset: offset) ?? 0
            offset += 1
            let green = data.extract(UInt8.self, offset: offset) ?? 0
            offset += 1
            let red = data.extract(UInt8.self, offset: offset) ?? 0
            offset += 2

            colorTable.append(ColorQuad(red: red,
                                        green: green,
                                        blue: blue,
                                        alpha: Int(red) + Int(green) + Int(blue) == 0 ? 0 : 255))
        }

        return colorTable
    }

    func constructImage(pixels: [ColorQuad]) -> NSImage {
        var pixels = pixels

        if pixels.count > 0 {
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)
            let quadStride = MemoryLayout<ColorQuad>.stride

            if let providerRef = CGDataProvider(data: Data(bytes: &pixels,
                                                           count: pixels.count * quadStride) as CFData) {
                if let cgImg = CGImage(width: Int(width),
                                       height: Int(height / 2),
                                       bitsPerComponent: 8,
                                       bitsPerPixel: 32,
                                       bytesPerRow: Int(width) * quadStride,
                                       space: CGColorSpaceCreateDeviceRGB(),
                                       bitmapInfo: bitmapInfo,
                                       provider: providerRef,
                                       decode: nil,
                                       shouldInterpolate: true,
                                       intent: .defaultIntent) {
                    return NSImage(cgImage: cgImg, size: .zero)
                }
            }
        }

        return NSImage()
    }
}

struct ColorQuad {
    var red: UInt8
    var green: UInt8
    var blue: UInt8
    var alpha: UInt8
}

enum BitmapCompression: UInt32 {
    case rgb = 0x0000
    case rle8 = 0x0001
    case rle4 = 0x0002
    case bitfields = 0x0003
    case jpeg = 0x0004
    case png = 0x0005
    case alphaBitfields = 0x0006
    case cmyk = 0x000B
    case cmykRle8 = 0x000C
    case cmykRle4 = 0x000D
}

enum BitmapOriginDirection {
    case bottomLeft
    case upperLeft
}

enum ColorFormat: UInt16 {
    case unknown = 0
    case indexed1 = 1
    case indexed2 = 2
    case indexed4 = 4
    case indexed8 = 8
    case sampled16 = 16
    case sampled24 = 24
    case sampled32 = 32
}
