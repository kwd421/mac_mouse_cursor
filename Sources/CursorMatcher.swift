import AppKit
import CryptoKit
import Darwin
import Foundation

struct CursorObservation: Identifiable {
    let id = UUID()
    let role: CursorRole
    let hotspot: CGPoint
    let fingerprintPrefix: String
    let timestamp: Date
}

struct CursorMatcherSelfTestResult: Identifiable {
    let id = UUID()
    let name: String
    let expectedRole: CursorRole
    let observedRole: CursorRole

    var passed: Bool {
        expectedRole == observedRole
    }
}

@MainActor
final class CursorMatcher {
    private typealias CGSConnectionID = Int32
    private typealias CGSMainConnectionIDFn = @convention(c) () -> CGSConnectionID
    private typealias CGSCopyRegisteredCursorImagesFn = @convention(c) (
        CGSConnectionID,
        UnsafeMutablePointer<CChar>,
        UnsafeMutablePointer<CGSize>,
        UnsafeMutablePointer<CGPoint>,
        UnsafeMutablePointer<UInt>,
        UnsafeMutablePointer<CGFloat>,
        UnsafeMutablePointer<Unmanaged<CFArray>?>?
    ) -> Int32
    private typealias CoreCursorCopyImagesFn = @convention(c) (
        CGSConnectionID,
        Int32,
        UnsafeMutablePointer<Unmanaged<CFArray>?>?,
        UnsafeMutablePointer<CGSize>,
        UnsafeMutablePointer<CGPoint>,
        UnsafeMutablePointer<UInt>,
        UnsafeMutablePointer<CGFloat>
    ) -> Int32

    private let standardCursors: [(cursor: NSCursor, role: CursorRole)]
    private let roleByFingerprint: [Data: CursorRole]
    private let defaultAnimations: [CursorRole: CursorAnimation]
    private let mainConnectionID: CGSMainConnectionIDFn?
    private let copyRegisteredCursorImages: CGSCopyRegisteredCursorImagesFn?
    private let coreCursorCopyImages: CoreCursorCopyImagesFn?
    private static let roleIdentifiers: [CursorRole: [String]] = [
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

    init() {
        _ = NSApplication.shared
        let loadedMainConnectionID: CGSMainConnectionIDFn? = Self.loadSymbol("CGSMainConnectionID")
        let loadedCopyRegisteredCursorImages: CGSCopyRegisteredCursorImagesFn? = Self.loadSymbol("CGSCopyRegisteredCursorImages")
        let loadedCoreCursorCopyImages: CoreCursorCopyImagesFn? = Self.loadSymbol("CoreCursorCopyImages")
        mainConnectionID = loadedMainConnectionID
        copyRegisteredCursorImages = loadedCopyRegisteredCursorImages
        coreCursorCopyImages = loadedCoreCursorCopyImages

        var mapping: [Data: CursorRole] = [:]
        var ambiguousFingerprints = Set<Data>()
        var previews: [CursorRole: CursorAnimation] = [:]
        var cursors: [(NSCursor, CursorRole)] = []

        func localWithCString<Result>(_ identifier: String, _ body: (UnsafeMutablePointer<CChar>) -> Result) -> Result {
            let values = identifier.utf8CString
            let pointer = UnsafeMutablePointer<CChar>.allocate(capacity: values.count)
            values.withUnsafeBufferPointer { buffer in
                pointer.initialize(from: buffer.baseAddress!, count: values.count)
            }
            defer { pointer.deallocate() }
            return body(pointer)
        }

        func localSystemAnimation(for role: CursorRole) -> CursorAnimation? {
            guard let identifiers = Self.roleIdentifiers[role] else { return nil }

            for identifier in identifiers {
                if identifier.hasPrefix("com.apple.cursor."),
                   let loadedCoreCursorCopyImages,
                   let loadedMainConnectionID,
                   let cursorID = Int32(identifier.split(separator: ".").last ?? "") {
                    var size = CGSize.zero
                    var hotspot = CGPoint.zero
                    var frameCount: UInt = 0
                    var frameDuration: CGFloat = 0
                    var imagesRef: Unmanaged<CFArray>?
                    let result = loadedCoreCursorCopyImages(
                        loadedMainConnectionID(),
                        cursorID,
                        &imagesRef,
                        &size,
                        &hotspot,
                        &frameCount,
                        &frameDuration
                    )
                    if result == 0, let imagesRef {
                        let images = imagesRef.takeRetainedValue() as NSArray
                        let frames = Self.decodeSystemFrames(
                            from: images,
                            expectedFrameCount: Int(frameCount),
                            frameDuration: max(Double(frameDuration), 0.01),
                            canvasSize: size
                        )
                        if !frames.isEmpty {
                            return CursorAnimation(
                                frames: frames,
                                hotspot: hotspot,
                                canvasSize: size == .zero ? CGSize(width: 32, height: 32) : size
                            )
                        }
                    }
                } else if let loadedCopyRegisteredCursorImages, let loadedMainConnectionID {
                    var size = CGSize.zero
                    var hotspot = CGPoint.zero
                    var frameCount: UInt = 0
                    var frameDuration: CGFloat = 0
                    var imagesRef: Unmanaged<CFArray>?
                    let result = localWithCString(identifier) { symbol in
                        loadedCopyRegisteredCursorImages(
                            loadedMainConnectionID(),
                            symbol,
                            &size,
                            &hotspot,
                            &frameCount,
                            &frameDuration,
                            &imagesRef
                        )
                    }
                    if result == 0, let imagesRef {
                        let images = imagesRef.takeRetainedValue() as NSArray
                        let frames = Self.decodeSystemFrames(
                            from: images,
                            expectedFrameCount: Int(frameCount),
                            frameDuration: max(Double(frameDuration), 0.01),
                            canvasSize: size
                        )
                        if !frames.isEmpty {
                            return CursorAnimation(
                                frames: frames,
                                hotspot: hotspot,
                                canvasSize: size == .zero ? CGSize(width: 32, height: 32) : size
                            )
                        }
                    }
                }
            }

            return nil
        }

        func register(_ cursor: NSCursor, as role: CursorRole) {
            let fingerprint = Self.fingerprint(for: cursor)
            if let existing = mapping[fingerprint], existing != role {
                mapping.removeValue(forKey: fingerprint)
                ambiguousFingerprints.insert(fingerprint)
            } else if !ambiguousFingerprints.contains(fingerprint) {
                mapping[fingerprint] = role
            }
            previews[role] = localSystemAnimation(for: role) ?? Self.animation(for: cursor)
            cursors.append((cursor, role))
        }

        register(.arrow, as: .arrow)
        register(.iBeam, as: .text)
        register(.pointingHand, as: .link)
        register(.crosshair, as: .precision)
        register(.openHand, as: .move)
        register(.closedHand, as: .move)
        register(.operationNotAllowed, as: .unavailable)
        register(.resizeLeftRight, as: .horizontalResize)
        register(.resizeUpDown, as: .verticalResize)

        for role in CursorRole.allCases where previews[role] == nil {
            previews[role] = localSystemAnimation(for: role) ?? previews[.arrow]
        }

        standardCursors = cursors
        roleByFingerprint = mapping
        defaultAnimations = previews
    }

    func currentObservation() -> CursorObservation {
        observation(for: NSCursor.current)
    }

    func currentRole() -> CursorRole {
        currentObservation().role
    }

    func defaultPreview(for role: CursorRole) -> CursorAnimation {
        defaultAnimations[role] ?? defaultAnimations[.arrow]!
    }

    func runSelfTest() -> [CursorMatcherSelfTestResult] {
        let testCases: [(String, NSCursor, CursorRole)] = [
            ("Arrow", .arrow, .arrow),
            ("IBeam", .iBeam, .text),
            ("Pointing Hand", .pointingHand, .link),
            ("Crosshair", .crosshair, .precision),
            ("Open Hand", .openHand, .move),
            ("Closed Hand", .closedHand, .move),
            ("Not Allowed", .operationNotAllowed, .unavailable),
            ("Resize Left Right", .resizeLeftRight, .horizontalResize),
            ("Resize Up Down", .resizeUpDown, .verticalResize)
        ]

        return testCases.map { name, cursor, expectedRole in
            let observation = observation(for: cursor)
            return CursorMatcherSelfTestResult(
                name: name,
                expectedRole: expectedRole,
                observedRole: observation.role
            )
        }
    }

    private func observation(for cursor: NSCursor) -> CursorObservation {
        let fingerprint = Self.fingerprint(for: cursor)
        let role = standardCursors.first(where: { registered, _ in
            cursor === registered || cursor.isEqual(registered)
        })?.role ?? roleByFingerprint[fingerprint] ?? .arrow
        let fingerprintPrefix = fingerprint.prefix(4).map { String(format: "%02x", $0) }.joined()
        return CursorObservation(
            role: role,
            hotspot: cursor.hotSpot,
            fingerprintPrefix: fingerprintPrefix,
            timestamp: Date()
        )
    }

    private static func fingerprint(for cursor: NSCursor) -> Data {
        let imageData = canonicalImageData(for: cursor.image)
        var payload = Data()
        payload.append(imageData)

        var width = Float(cursor.image.size.width)
        var height = Float(cursor.image.size.height)
        var hotX = Float(cursor.hotSpot.x)
        var hotY = Float(cursor.hotSpot.y)
        withUnsafeBytes(of: &width) { payload.append(contentsOf: $0) }
        withUnsafeBytes(of: &height) { payload.append(contentsOf: $0) }
        withUnsafeBytes(of: &hotX) { payload.append(contentsOf: $0) }
        withUnsafeBytes(of: &hotY) { payload.append(contentsOf: $0) }

        return Data(SHA256.hash(data: payload))
    }

    private static func canonicalImageData(for image: NSImage) -> Data {
        let proposedSize = image.size == .zero ? NSSize(width: 32, height: 32) : image.size
        let proposedRect = NSRect(origin: .zero, size: proposedSize)

        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let rep = NSBitmapImageRep(cgImage: cgImage)
            if let png = rep.representation(using: .png, properties: [:]) {
                return png
            }
        }

        guard
            let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: max(Int(proposedRect.width.rounded(.up)), 1),
                pixelsHigh: max(Int(proposedRect.height.rounded(.up)), 1),
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            )
        else {
            return image.tiffRepresentation ?? Data()
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: proposedRect)
        NSGraphicsContext.restoreGraphicsState()

        return rep.representation(using: .png, properties: [:]) ?? image.tiffRepresentation ?? Data()
    }

    private static func animation(for cursor: NSCursor) -> CursorAnimation {
        let size = cursor.image.size
        return CursorAnimation(
            frames: [CursorFrame(image: cursor.image, delay: 1.0)],
            hotspot: cursor.hotSpot,
            canvasSize: size == .zero ? CGSize(width: 32, height: 32) : size
        )
    }

    private static func decodeSystemFrames(
        from images: NSArray,
        expectedFrameCount: Int,
        frameDuration: TimeInterval,
        canvasSize: CGSize
    ) -> [CursorFrame] {
        let normalizedSize = canvasSize == .zero ? CGSize(width: 32, height: 32) : canvasSize
        let directFrames = images.compactMap { item in
            frameImage(from: item, size: normalizedSize)
        }
        if directFrames.count != 1 {
            return directFrames.map { CursorFrame(image: $0, delay: frameDuration) }
        }

        let singleFrame = directFrames[0]
        let expectedFrames = max(expectedFrameCount, 1)
        guard expectedFrames > 1 else {
            return [CursorFrame(image: singleFrame, delay: frameDuration)]
        }

        var proposedRect = NSRect(origin: .zero, size: normalizedSize)
        guard
            let sourceCGImage = singleFrame.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil)
        else {
            return [CursorFrame(image: singleFrame, delay: frameDuration)]
        }

        let fullWidth = sourceCGImage.width
        let fullHeight = sourceCGImage.height
        guard
            fullWidth > 0,
            fullHeight > fullWidth,
            fullHeight % expectedFrames == 0
        else {
            return [CursorFrame(image: singleFrame, delay: frameDuration)]
        }

        let frameHeight = fullHeight / expectedFrames
        guard frameHeight > 0 else {
            return [CursorFrame(image: singleFrame, delay: frameDuration)]
        }

        let splitFrames = (0..<expectedFrames).compactMap { index -> CursorFrame? in
            let originY = fullHeight - ((index + 1) * frameHeight)
            let cropRect = CGRect(x: 0, y: originY, width: fullWidth, height: frameHeight)
            guard let cropped = sourceCGImage.cropping(to: cropRect) else { return nil }
            let image = NSImage(cgImage: cropped, size: normalizedSize)
            return CursorFrame(image: image, delay: frameDuration)
        }

        return splitFrames.isEmpty ? [CursorFrame(image: singleFrame, delay: frameDuration)] : splitFrames
    }

    private static func frameImage(from item: Any, size: CGSize) -> NSImage? {
        let cfItem = item as CFTypeRef
        if CFGetTypeID(cfItem) == CGImage.typeID {
            let cgImage = unsafeDowncast(cfItem, to: CGImage.self)
            return NSImage(cgImage: cgImage, size: size)
        }
        if let data = item as? Data {
            return NSImage(data: data)
        }
        if let data = item as? NSData {
            return NSImage(data: data as Data)
        }
        return nil
    }

    private static func loadSymbol<T>(_ name: String) -> T? {
        let handles = [
            dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_NOW),
            dlopen("/System/Library/Frameworks/ApplicationServices.framework/Frameworks/HIServices.framework/HIServices", RTLD_NOW),
            dlopen(nil, RTLD_NOW)
        ]

        for handle in handles {
            guard let handle, let symbol = dlsym(handle, name) else { continue }
            return unsafeBitCast(symbol, to: T.self)
        }
        return nil
    }

}
