import AppKit
import Foundation

struct CapeExporter {
    struct ExportMetrics: Equatable {
        let baseScale: Double
        let targetPixelWidth: Int
        let targetPixelHeight: Int
        let pointsWidth: Double
        let pointsHeight: Double
        let hotspotX: Double
        let hotspotY: Double
    }

    private let roleIdentifiers: [CursorRole: [String]] = [
        .arrow: ["com.apple.coregraphics.Arrow", "com.apple.cursor.0"],
        .text: ["com.apple.coregraphics.IBeam", "com.apple.coregraphics.IBeamXOR"],
        .link: ["com.apple.cursor.2", "com.apple.cursor.13"],
        .location: ["com.apple.coregraphics.Copy", "com.apple.cursor.5"],
        .precision: ["com.apple.cursor.7", "com.apple.cursor.8"],
        .move: ["com.apple.coregraphics.Move", "com.apple.cursor.11", "com.apple.cursor.12"],
        .unavailable: ["com.apple.cursor.3"],
        .busy: ["com.apple.cursor.4"],
        .working: ["com.apple.coregraphics.Wait"],
        .help: ["com.apple.cursor.40"],
        .handwriting: ["com.apple.cursor.20"],
        .person: ["com.apple.cursor.41"],
        .alternate: ["com.apple.coregraphics.Alias"],
        .verticalResize: ["com.apple.cursor.21", "com.apple.cursor.22", "com.apple.cursor.23", "com.apple.cursor.31", "com.apple.cursor.32", "com.apple.cursor.36"],
        .horizontalResize: ["com.apple.cursor.17", "com.apple.cursor.18", "com.apple.cursor.19", "com.apple.cursor.27", "com.apple.cursor.28", "com.apple.cursor.38"],
        .diagonalResizeNWSE: ["com.apple.cursor.33", "com.apple.cursor.34", "com.apple.cursor.35"],
        .diagonalResizeNESW: ["com.apple.cursor.29", "com.apple.cursor.30", "com.apple.cursor.37"]
    ]

    private let supplementalIdentifiers: [SupplementalCursorRole: [String]] = [
        .contextualMenu: ["com.apple.coregraphics.ArrowCtx"],
        .dragCopy: ["com.apple.coregraphics.CopyDrag"],
        .dragLink: ["com.apple.coregraphics.LinkDrag"],
        .disappearingItem: ["com.apple.coregraphics.DisappearingItem"],
        .resizeUp: ["com.apple.coregraphics.ResizeUp"],
        .resizeDown: ["com.apple.coregraphics.ResizeDown"],
        .resizeLeft: ["com.apple.coregraphics.ResizeLeft"],
        .resizeRight: ["com.apple.coregraphics.ResizeRight"],
        .verticalIBeam: ["com.apple.coregraphics.IBeamForVerticalLayout"]
    ]

    func exportCape(
        name: String,
        author: String,
        identifier: String,
        theme: CursorTheme,
        sizeMultiplier: Double = 1.0,
        to url: URL
    ) throws {
        var cursors: [String: Any] = [:]

        for role in CursorRole.allCases {
            guard let animation = theme[role], let identifiers = roleIdentifiers[role] else { continue }
            let dictionary = try cursorDictionary(for: animation, sizeMultiplier: sizeMultiplier)
            for identifier in identifiers {
                cursors[identifier] = dictionary
            }
        }

        for role in SupplementalCursorRole.allCases {
            guard
                let identifiers = supplementalIdentifiers[role],
                let animation = theme[role] ?? theme[role.mappedPrimaryRole]
            else { continue }
            let dictionary = try cursorDictionary(for: animation, sizeMultiplier: sizeMultiplier)
            for identifier in identifiers {
                cursors[identifier] = dictionary
            }
        }

        guard !cursors.isEmpty else {
            throw CursorError.invalidThemeSelection(Localized.string("error.noCursorsToExport"))
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

    private func cursorDictionary(for animation: CursorAnimation, sizeMultiplier: Double) throws -> [String: Any] {
        let renderedFrames = try animation.frames.map { frame in
            try bitmapRep(for: frame.image, canvasSize: animation.canvasSize)
        }

        let basePixelWidth = renderedFrames.map(\.pixelsWide).max() ?? 1
        let basePixelHeight = renderedFrames.map(\.pixelsHigh).max() ?? 1
        let metrics = Self.exportMetrics(
            basePixelWidth: basePixelWidth,
            basePixelHeight: basePixelHeight,
            hotspot: animation.hotspot,
            sizeMultiplier: sizeMultiplier
        )
        let scaledFrames = try renderedFrames.map { frame in
            try scaledBitmapRep(for: frame, width: metrics.targetPixelWidth, height: metrics.targetPixelHeight)
        }

        let stacked = try stack(frames: scaledFrames, width: metrics.targetPixelWidth, height: metrics.targetPixelHeight)
        guard let pngData = stacked.representation(using: .png, properties: [:]) else {
            throw CursorError.unsupportedCursorPayload
        }

        return [
            "FrameCount": animation.frames.count,
            "FrameDuration": animation.frames.first?.delay ?? 1.0,
            "HotSpotX": metrics.hotspotX,
            "HotSpotY": metrics.hotspotY,
            "PointsWide": metrics.pointsWidth,
            "PointsHigh": metrics.pointsHeight,
            "Representations": [pngData]
        ]
    }

    static func previewDisplaySize(for animation: CursorAnimation, sizeMultiplier: Double) -> CGSize {
        let metrics = exportMetrics(
            basePixelWidth: max(Int(animation.canvasSize.width.rounded(.up)), 1),
            basePixelHeight: max(Int(animation.canvasSize.height.rounded(.up)), 1),
            hotspot: animation.hotspot,
            sizeMultiplier: sizeMultiplier
        )
        return CGSize(width: metrics.pointsWidth, height: metrics.pointsHeight)
    }

    static func exportMetrics(
        basePixelWidth: Int,
        basePixelHeight: Int,
        hotspot: CGPoint,
        sizeMultiplier: Double
    ) -> ExportMetrics {
        let multiplier = min(max(sizeMultiplier, 1.0), 3.0)
        let baseScale = suggestedScale(for: CGSize(width: basePixelWidth, height: basePixelHeight))
        let targetPixelWidth = max(Int((Double(basePixelWidth) * multiplier).rounded(.up)), 1)
        let targetPixelHeight = max(Int((Double(basePixelHeight) * multiplier).rounded(.up)), 1)
        return ExportMetrics(
            baseScale: baseScale,
            targetPixelWidth: targetPixelWidth,
            targetPixelHeight: targetPixelHeight,
            pointsWidth: Double(targetPixelWidth) / baseScale,
            pointsHeight: Double(targetPixelHeight) / baseScale,
            hotspotX: Double(hotspot.x) * multiplier,
            hotspotY: Double(hotspot.y) * multiplier
        )
    }

    private static func suggestedScale(for pixelSize: CGSize) -> Double {
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

    private func scaledBitmapRep(for source: NSBitmapImageRep, width: Int, height: Int) throws -> NSBitmapImageRep {
        guard source.pixelsWide == width, source.pixelsHigh == height else {
            guard
                let rep = NSBitmapImageRep(
                    bitmapDataPlanes: nil,
                    pixelsWide: width,
                    pixelsHigh: height,
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
            guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
                NSGraphicsContext.restoreGraphicsState()
                throw CursorError.unsupportedCursorPayload
            }
            context.imageInterpolation = .none
            NSGraphicsContext.current = context
            source.draw(
                in: NSRect(x: 0, y: 0, width: width, height: height),
                from: NSRect(x: 0, y: 0, width: source.pixelsWide, height: source.pixelsHigh),
                operation: .copy,
                fraction: 1.0,
                respectFlipped: true,
                hints: nil
            )
            NSGraphicsContext.restoreGraphicsState()
            return rep
        }

        return source
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
