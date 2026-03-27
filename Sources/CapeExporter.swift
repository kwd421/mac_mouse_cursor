import AppKit
import Foundation

struct CapeExporter {
    private let roleIdentifiers: [CursorRole: [String]] = [
        .arrow: ["com.apple.coregraphics.Arrow", "com.apple.cursor.0"],
        .text: ["com.apple.coregraphics.IBeam"],
        .link: ["com.apple.cursor.2", "com.apple.cursor.13"],
        .location: ["com.apple.coregraphics.Copy", "com.apple.cursor.5"],
        .precision: ["com.apple.cursor.7", "com.apple.cursor.8"],
        .move: ["com.apple.coregraphics.Move", "com.apple.cursor.11", "com.apple.cursor.12"],
        .unavailable: ["com.apple.cursor.3"],
        .busy: ["com.apple.cursor.4"],
        .working: ["com.apple.coregraphics.Wait"],
        .help: ["com.apple.cursor.40"],
        .handwriting: ["com.apple.coregraphics.IBeamXOR", "com.apple.cursor.20"],
        .person: ["com.apple.cursor.41"],
        .alternate: ["com.apple.coregraphics.Alias"],
        .verticalResize: ["com.apple.cursor.23", "com.apple.cursor.32"],
        .horizontalResize: ["com.apple.cursor.19", "com.apple.cursor.28"],
        .diagonalResizeNWSE: ["com.apple.cursor.34"],
        .diagonalResizeNESW: ["com.apple.cursor.30"]
    ]

    func exportCape(
        name: String,
        author: String,
        identifier: String,
        theme: CursorTheme,
        to url: URL
    ) throws {
        var cursors: [String: Any] = [:]

        for role in CursorRole.allCases {
            guard let animation = theme[role], let identifiers = roleIdentifiers[role] else { continue }
            let dictionary = try cursorDictionary(for: animation)
            for identifier in identifiers {
                cursors[identifier] = dictionary
            }
        }

        guard !cursors.isEmpty else {
            throw CursorError.invalidThemeSelection("내보낼 커서가 없습니다.")
        }

        let cape: [String: Any] = [
            "MinimumVersion": 2.0,
            "Version": 2.0,
            "CapeName": name,
            "CapeVersion": 1.0,
            "Cloud": false,
            "Author": author,
            "HiDPI": true,
            "Identifier": identifier,
            "Cursors": cursors
        ]

        let data = try PropertyListSerialization.data(fromPropertyList: cape, format: .xml, options: 0)
        try data.write(to: url, options: .atomic)
    }

    private func cursorDictionary(for animation: CursorAnimation) throws -> [String: Any] {
        let renderedFrames = try animation.frames.map { frame in
            try bitmapRep(for: frame.image, canvasSize: animation.canvasSize)
        }

        let maxPixelWidth = renderedFrames.map(\.pixelsWide).max() ?? 1
        let maxPixelHeight = renderedFrames.map(\.pixelsHigh).max() ?? 1
        let scale = suggestedScale(for: CGSize(width: maxPixelWidth, height: maxPixelHeight))
        let pointsWide = Double(maxPixelWidth) / scale
        let pointsHigh = Double(maxPixelHeight) / scale

        let stacked = try stack(frames: renderedFrames, width: maxPixelWidth, height: maxPixelHeight)
        guard let pngData = stacked.representation(using: .png, properties: [:]) else {
            throw CursorError.unsupportedCursorPayload
        }

        return [
            "FrameCount": animation.frames.count,
            "FrameDuration": animation.frames.first?.delay ?? 1.0,
            "HotSpotX": Double(animation.hotspot.x) / scale,
            "HotSpotY": Double(animation.hotspot.y) / scale,
            "PointsWide": pointsWide,
            "PointsHigh": pointsHigh,
            "Representations": [pngData]
        ]
    }

    private func suggestedScale(for pixelSize: CGSize) -> Double {
        pixelSize.width >= 64 || pixelSize.height >= 64 ? 2.0 : 1.0
    }

    private func bitmapRep(for image: NSImage, canvasSize: CGSize) throws -> NSBitmapImageRep {
        let pixelWidth = max(Int(canvasSize.width.rounded(.up)), 1)
        let pixelHeight = max(Int(canvasSize.height.rounded(.up)), 1)
        guard
            let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: pixelWidth,
                pixelsHigh: pixelHeight,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            )
        else {
            throw CursorError.unsupportedCursorPayload
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: NSRect(origin: .zero, size: NSSize(width: pixelWidth, height: pixelHeight)))
        NSGraphicsContext.restoreGraphicsState()
        return rep
    }

    private func stack(frames: [NSBitmapImageRep], width: Int, height: Int) throws -> NSBitmapImageRep {
        guard
            let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: width,
                pixelsHigh: height * frames.count,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            )
        else {
            throw CursorError.unsupportedCursorPayload
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

        var currentY = 0
        for frame in frames.reversed() {
            frame.draw(
                in: NSRect(x: 0, y: currentY, width: frame.pixelsWide, height: frame.pixelsHigh),
                from: .zero,
                operation: .sourceOver,
                fraction: 1.0,
                respectFlipped: true,
                hints: nil
            )
            currentY += frame.pixelsHigh
        }

        NSGraphicsContext.restoreGraphicsState()
        return rep
    }
}
