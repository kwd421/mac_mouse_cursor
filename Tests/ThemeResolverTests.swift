import AppKit
import Foundation
import Testing
@testable import CapeForge

struct ThemeResolverTests {
    @Test
    func resolvesDecomposedHangulFileNames() throws {
        let tempDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let folder = tempDirectory.appendingPathComponent("기본", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let decomposedName = "독케익_일반선택.ani"
        FileManager.default.createFile(atPath: folder.appendingPathComponent(decomposedName).path, contents: Data("x".utf8))

        let resolved = try ThemeResolver().resolveTheme(in: folder)
        #expect(resolved.filesByRole[.arrow]?.lastPathComponent == decomposedName)
    }

    @Test
    func rejectsPackRootWithoutDirectCursorFiles() throws {
        let tempDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let nested = tempDirectory
            .appendingPathComponent("기본", isDirectory: true)
            .appendingPathComponent("테두리 O", isDirectory: true)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        FileManager.default.createFile(
            atPath: nested.appendingPathComponent("독케익_일반선택.ani").path,
            contents: Data("x".utf8)
        )

        #expect(throws: CursorError.self) {
            try ThemeResolver().resolveTheme(in: tempDirectory)
        }
    }

    @Test
    func keepsExistingMatchesAndFallsBackMissingRolesToArrow() throws {
        let tempDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let folder = tempDirectory.appendingPathComponent("세트", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let files = [
            "독케익_일반선택.ani",
            "독케익_텍스트 선택.ani",
            "독케익_이동.ani"
        ]
        for file in files {
            FileManager.default.createFile(atPath: folder.appendingPathComponent(file).path, contents: Data("x".utf8))
        }

        let resolved = try ThemeResolver().resolveTheme(in: folder)
        #expect(resolved.filesByRole[.arrow] != nil)
        #expect(resolved.filesByRole[.text] != nil)
        #expect(resolved.filesByRole[.move] != nil)
        #expect(resolved.filesByRole[.link]?.lastPathComponent == "독케익_일반선택.ani")
    }

    @Test
    func resolvesCombinedKoreanRoleFilesForExpandedMacRoles() throws {
        let tempDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let folder = tempDirectory.appendingPathComponent("기본", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let files = [
            "독케익_일반선택.ani",
            "독케익_연결,위치,사용자 선택.ani",
            "독케익_백그라운드 작업,사용중.ani"
        ]

        for file in files {
            FileManager.default.createFile(atPath: folder.appendingPathComponent(file).path, contents: Data("x".utf8))
        }

        let resolved = try ThemeResolver().resolveTheme(in: folder)
        #expect(resolved.filesByRole[.arrow]?.lastPathComponent == "독케익_일반선택.ani")
        #expect(resolved.filesByRole[.link]?.lastPathComponent == "독케익_연결,위치,사용자 선택.ani")
        #expect(resolved.filesByRole[.location]?.lastPathComponent == "독케익_연결,위치,사용자 선택.ani")
        #expect(resolved.filesByRole[.busy]?.lastPathComponent == "독케익_백그라운드 작업,사용중.ani")
        #expect(resolved.filesByRole[.working]?.lastPathComponent == "독케익_백그라운드 작업,사용중.ani")
    }

    @Test
    func resolvesGenericEnglishCursorNames() throws {
        let tempDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let folder = tempDirectory.appendingPathComponent("Saber", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let files = [
            "Normal.ani",
            "Text.ani",
            "Link.ani",
            "Pin.ani",
            "Precision.ani",
            "Move.ani",
            "Unavailable.ani",
            "Busy.ani",
            "Working.ani",
            "Help.ani",
            "Handwriting.ani",
            "Person.ani",
            "Alternate.ani",
            "Vertical.ani",
            "Horizontal.ani",
            "Diagonal1.ani",
            "Diagonal2.ani"
        ]

        for file in files {
            FileManager.default.createFile(atPath: folder.appendingPathComponent(file).path, contents: Data("x".utf8))
        }

        let resolved = try ThemeResolver().resolveTheme(in: folder)
        #expect(resolved.filesByRole[.arrow]?.lastPathComponent == "Normal.ani")
        #expect(resolved.filesByRole[.text]?.lastPathComponent == "Text.ani")
        #expect(resolved.filesByRole[.link]?.lastPathComponent == "Link.ani")
        #expect(resolved.filesByRole[.location]?.lastPathComponent == "Pin.ani")
        #expect(resolved.filesByRole[.precision]?.lastPathComponent == "Precision.ani")
        #expect(resolved.filesByRole[.move]?.lastPathComponent == "Move.ani")
        #expect(resolved.filesByRole[.unavailable]?.lastPathComponent == "Unavailable.ani")
        #expect(resolved.filesByRole[.busy]?.lastPathComponent == "Busy.ani")
        #expect(resolved.filesByRole[.working]?.lastPathComponent == "Working.ani")
        #expect(resolved.filesByRole[.help]?.lastPathComponent == "Help.ani")
        #expect(resolved.filesByRole[.handwriting]?.lastPathComponent == "Handwriting.ani")
        #expect(resolved.filesByRole[.person]?.lastPathComponent == "Person.ani")
        #expect(resolved.filesByRole[.alternate]?.lastPathComponent == "Alternate.ani")
        #expect(resolved.filesByRole[.verticalResize]?.lastPathComponent == "Vertical.ani")
        #expect(resolved.filesByRole[.horizontalResize]?.lastPathComponent == "Horizontal.ani")
        #expect(resolved.filesByRole[.diagonalResizeNWSE]?.lastPathComponent == "Diagonal1.ani")
        #expect(resolved.filesByRole[.diagonalResizeNESW]?.lastPathComponent == "Diagonal2.ani")
    }

    @Test
    func resolvesCommonLocalizedCursorKeywords() throws {
        let tempDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let folder = tempDirectory.appendingPathComponent("Localized", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let files = [
            "Normal.ani",
            "Arrastrar.ani",
            "Prohibido.ani",
            "Attesa.ani",
            "Hilfe.ani",
            "Manuscrit.ani"
        ]

        for file in files {
            FileManager.default.createFile(atPath: folder.appendingPathComponent(file).path, contents: Data("x".utf8))
        }

        let resolved = try ThemeResolver().resolveTheme(in: folder)
        #expect(resolved.filesByRole[.arrow]?.lastPathComponent == "Normal.ani")
        #expect(resolved.filesByRole[.move]?.lastPathComponent == "Arrastrar.ani")
        #expect(resolved.filesByRole[.unavailable]?.lastPathComponent == "Prohibido.ani")
        #expect(resolved.filesByRole[.working]?.lastPathComponent == "Attesa.ani")
        #expect(resolved.filesByRole[.help]?.lastPathComponent == "Hilfe.ani")
        #expect(resolved.filesByRole[.handwriting]?.lastPathComponent == "Manuscrit.ani")
    }

    @Test
    func resolvesLocalizedKeywordsWithDiacritics() throws {
        let tempDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let folder = tempDirectory.appendingPathComponent("Diacritics", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let files = [
            "Normal.ani",
            "déplacer.ani",
            "arrière-plan.ani",
            "lápiz.ani"
        ]

        for file in files {
            FileManager.default.createFile(atPath: folder.appendingPathComponent(file).path, contents: Data("x".utf8))
        }

        let resolved = try ThemeResolver().resolveTheme(in: folder)
        #expect(resolved.filesByRole[.arrow]?.lastPathComponent == "Normal.ani")
        #expect(resolved.filesByRole[.move]?.lastPathComponent == "déplacer.ani")
        #expect(resolved.filesByRole[.working]?.lastPathComponent == "arrière-plan.ani")
        #expect(resolved.filesByRole[.handwriting]?.lastPathComponent == "lápiz.ani")
    }

    @Test
    func doesNotMapAlternateToUnavailableWhenUnavailableExists() throws {
        let tempDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let folder = tempDirectory.appendingPathComponent("Ambiguous", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let files = [
            "Normal.ani",
            "Alternate.ani",
            "Unavailable.ani"
        ]

        for file in files {
            FileManager.default.createFile(atPath: folder.appendingPathComponent(file).path, contents: Data("x".utf8))
        }

        let resolved = try ThemeResolver().resolveTheme(in: folder)
        #expect(resolved.filesByRole[.arrow]?.lastPathComponent == "Normal.ani")
        #expect(resolved.filesByRole[.unavailable]?.lastPathComponent == "Unavailable.ani")
    }

    @Test
    func fallsBackBusyToWorkingWhenBusyIsMissing() throws {
        let tempDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let folder = tempDirectory.appendingPathComponent("BusyFallback", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let files = [
            "Normal.ani",
            "Working.ani"
        ]

        for file in files {
            FileManager.default.createFile(atPath: folder.appendingPathComponent(file).path, contents: Data("x".utf8))
        }

        let resolved = try ThemeResolver().resolveTheme(in: folder)
        #expect(resolved.filesByRole[.working]?.lastPathComponent == "Working.ani")
        #expect(resolved.filesByRole[.busy]?.lastPathComponent == "Working.ani")
    }

    @Test
    func fallsBackWorkingToBusyWhenWorkingIsMissing() throws {
        let tempDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let folder = tempDirectory.appendingPathComponent("WorkingFallback", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let files = [
            "Normal.ani",
            "Busy.ani"
        ]

        for file in files {
            FileManager.default.createFile(atPath: folder.appendingPathComponent(file).path, contents: Data("x".utf8))
        }

        let resolved = try ThemeResolver().resolveTheme(in: folder)
        #expect(resolved.filesByRole[.busy]?.lastPathComponent == "Busy.ani")
        #expect(resolved.filesByRole[.working]?.lastPathComponent == "Busy.ani")
    }

    @Test
    func fallsBackToArrowWhenNoExactArrowMatchExists() throws {
        let tempDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let folder = tempDirectory.appendingPathComponent("Fallback", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let files = [
            "Mystery.ani",
            "Help.ani"
        ]

        for file in files {
            FileManager.default.createFile(atPath: folder.appendingPathComponent(file).path, contents: Data("x".utf8))
        }

        let resolved = try ThemeResolver().resolveTheme(in: folder)
        #expect(resolved.filesByRole[.help]?.lastPathComponent == "Help.ani")
        #expect(resolved.filesByRole[.arrow]?.lastPathComponent == "Mystery.ani")
    }

    @Test
    func fallsBackToThemeArrowForUnresolvedRoles() throws {
        let tempDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let folder = tempDirectory.appendingPathComponent("Partial", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let files = [
            "Normal.ani",
            "Help.ani"
        ]

        for file in files {
            FileManager.default.createFile(atPath: folder.appendingPathComponent(file).path, contents: Data("x".utf8))
        }

        let resolved = try ThemeResolver().resolveTheme(in: folder)
        #expect(resolved.filesByRole[.arrow]?.lastPathComponent == "Normal.ani")
        #expect(resolved.filesByRole[.help]?.lastPathComponent == "Help.ani")
        #expect(resolved.filesByRole[.text]?.lastPathComponent == "Normal.ani")
        #expect(resolved.filesByRole[.move]?.lastPathComponent == "Normal.ani")
        #expect(resolved.filesByRole[.verticalResize]?.lastPathComponent == "Normal.ani")
    }

    private func makeTemporaryDirectory() throws -> URL {
        let base = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let directory = base.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

struct CapeExporterTests {
    @MainActor
    @Test
    func exportsCapeFileWithMousecapeKeys() throws {
        let image = NSImage(size: NSSize(width: 16, height: 16))
        image.lockFocus()
        NSColor.white.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 16, height: 16)).fill()
        image.unlockFocus()

        let animation = CursorAnimation(
            frames: [CursorFrame(image: image, delay: 0.2)],
            hotspot: CGPoint(x: 1, y: 1),
            canvasSize: CGSize(width: 16, height: 16)
        )
        let theme = CursorTheme(animations: [
            .arrow: animation,
            .location: animation,
            .working: animation,
            .help: animation,
            .handwriting: animation,
            .person: animation,
            .alternate: animation
        ])

        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("cape")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        try CapeExporter().exportCape(
            name: "Test Cape",
            author: "Tester",
            identifier: "local.test.cape",
            theme: theme,
            to: tempURL
        )

        let data = try Data(contentsOf: tempURL)
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        let cursors = plist?["Cursors"] as? [String: Any]
        let arrow = cursors?["com.apple.coregraphics.Arrow"] as? [String: Any]
        let legacyArrow = cursors?["com.apple.cursor.0"] as? [String: Any]
        let iBeam = cursors?["com.apple.coregraphics.IBeam"] as? [String: Any]
        let iBeamXOR = cursors?["com.apple.coregraphics.IBeamXOR"] as? [String: Any]
        let copy = cursors?["com.apple.coregraphics.Copy"] as? [String: Any]
        let wait = cursors?["com.apple.coregraphics.Wait"] as? [String: Any]
        let help = cursors?["com.apple.cursor.40"] as? [String: Any]
        let cellXOR = cursors?["com.apple.cursor.20"] as? [String: Any]
        let cell = cursors?["com.apple.cursor.41"] as? [String: Any]
        let alias = cursors?["com.apple.coregraphics.Alias"] as? [String: Any]

        #expect(plist?["CapeName"] as? String == "Test Cape")
        #expect(plist?["Identifier"] as? String == "local.test.cape")
        #expect(arrow?["FrameCount"] as? Int == 1)
        #expect(legacyArrow?["FrameCount"] as? Int == 1)
        #expect(iBeam == nil)
        #expect(iBeamXOR == nil)
        #expect(copy?["FrameCount"] as? Int == 1)
        #expect(wait?["FrameCount"] as? Int == 1)
        #expect(help?["FrameCount"] as? Int == 1)
        #expect(cellXOR?["FrameCount"] as? Int == 1)
        #expect(cell?["FrameCount"] as? Int == 1)
        #expect(alias?["FrameCount"] as? Int == 1)
        #expect((arrow?["Representations"] as? [Data])?.isEmpty == false)
    }

    @MainActor
    @Test
    func exportsTextAndResizeRolesToExpandedMousecapeIdentifiers() throws {
        let image = NSImage(size: NSSize(width: 16, height: 16))
        image.lockFocus()
        NSColor.white.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 16, height: 16)).fill()
        image.unlockFocus()

        let animation = CursorAnimation(
            frames: [CursorFrame(image: image, delay: 0.2)],
            hotspot: CGPoint(x: 1, y: 1),
            canvasSize: CGSize(width: 16, height: 16)
        )
        let theme = CursorTheme(animations: [
            .text: animation,
            .verticalResize: animation,
            .horizontalResize: animation,
            .diagonalResizeNWSE: animation,
            .diagonalResizeNESW: animation
        ])

        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("cape")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        try CapeExporter().exportCape(
            name: "Test Cape",
            author: "Tester",
            identifier: "local.test.cape",
            theme: theme,
            to: tempURL
        )

        let data = try Data(contentsOf: tempURL)
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        let cursors = plist?["Cursors"] as? [String: Any] ?? [:]

        #expect(cursors["com.apple.coregraphics.IBeam"] != nil)
        #expect(cursors["com.apple.coregraphics.IBeamXOR"] != nil)
        #expect(cursors["com.apple.cursor.21"] != nil)
        #expect(cursors["com.apple.cursor.22"] != nil)
        #expect(cursors["com.apple.cursor.23"] != nil)
        #expect(cursors["com.apple.cursor.31"] != nil)
        #expect(cursors["com.apple.cursor.32"] != nil)
        #expect(cursors["com.apple.cursor.36"] != nil)
        #expect(cursors["com.apple.cursor.17"] != nil)
        #expect(cursors["com.apple.cursor.18"] != nil)
        #expect(cursors["com.apple.cursor.19"] != nil)
        #expect(cursors["com.apple.cursor.27"] != nil)
        #expect(cursors["com.apple.cursor.28"] != nil)
        #expect(cursors["com.apple.cursor.38"] != nil)
        #expect(cursors["com.apple.cursor.33"] != nil)
        #expect(cursors["com.apple.cursor.34"] != nil)
        #expect(cursors["com.apple.cursor.35"] != nil)
        #expect(cursors["com.apple.cursor.29"] != nil)
        #expect(cursors["com.apple.cursor.30"] != nil)
        #expect(cursors["com.apple.cursor.37"] != nil)
    }

    @MainActor
    @Test
    func exportsSupplementalMousecapeIdentifiersUsingMappedPrimaryRoles() throws {
        let image = NSImage(size: NSSize(width: 16, height: 16))
        image.lockFocus()
        NSColor.white.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 16, height: 16)).fill()
        image.unlockFocus()

        let animation = CursorAnimation(
            frames: [CursorFrame(image: image, delay: 0.2)],
            hotspot: CGPoint(x: 1, y: 1),
            canvasSize: CGSize(width: 16, height: 16)
        )
        let theme = CursorTheme(animations: [
            .link: animation,
            .location: animation,
            .alternate: animation,
            .unavailable: animation,
            .verticalResize: animation,
            .horizontalResize: animation,
            .text: animation
        ])

        let tempURL = temporaryCapeURL()
        defer { try? FileManager.default.removeItem(at: tempURL) }

        try CapeExporter().exportCape(
            name: "Supplemental",
            author: "Tester",
            identifier: "local.test.supplemental",
            theme: theme,
            to: tempURL
        )

        let data = try Data(contentsOf: tempURL)
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        let cursors = plist?["Cursors"] as? [String: Any] ?? [:]

        #expect(cursors["com.apple.coregraphics.ArrowCtx"] != nil)
        #expect(cursors["com.apple.coregraphics.CopyDrag"] != nil)
        #expect(cursors["com.apple.coregraphics.LinkDrag"] != nil)
        #expect(cursors["com.apple.coregraphics.DisappearingItem"] != nil)
        #expect(cursors["com.apple.coregraphics.ResizeUp"] != nil)
        #expect(cursors["com.apple.coregraphics.ResizeDown"] != nil)
        #expect(cursors["com.apple.coregraphics.ResizeLeft"] != nil)
        #expect(cursors["com.apple.coregraphics.ResizeRight"] != nil)
        #expect(cursors["com.apple.coregraphics.IBeamForVerticalLayout"] != nil)
    }

    @MainActor
    @Test
    func exportsSupplementalOverrideInsteadOfMappedPrimaryRole() throws {
        let baseImage = NSImage(size: NSSize(width: 16, height: 16))
        baseImage.lockFocus()
        NSColor.white.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 16, height: 16)).fill()
        baseImage.unlockFocus()

        let overrideImage = NSImage(size: NSSize(width: 24, height: 24))
        overrideImage.lockFocus()
        NSColor.red.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 24, height: 24)).fill()
        overrideImage.unlockFocus()

        let baseAnimation = CursorAnimation(
            frames: [CursorFrame(image: baseImage, delay: 0.2)],
            hotspot: CGPoint(x: 1, y: 1),
            canvasSize: CGSize(width: 16, height: 16)
        )
        let overrideAnimation = CursorAnimation(
            frames: [CursorFrame(image: overrideImage, delay: 0.2)],
            hotspot: CGPoint(x: 2, y: 2),
            canvasSize: CGSize(width: 24, height: 24)
        )
        let theme = CursorTheme(
            animations: [.location: baseAnimation],
            supplementalAnimations: [.dragCopy: overrideAnimation]
        )

        let tempURL = temporaryCapeURL()
        defer { try? FileManager.default.removeItem(at: tempURL) }

        try CapeExporter().exportCape(
            name: "Supplemental Override",
            author: "Tester",
            identifier: "local.test.supplemental-override",
            theme: theme,
            to: tempURL
        )

        let data = try Data(contentsOf: tempURL)
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        let cursors = plist?["Cursors"] as? [String: Any] ?? [:]
        let dragCopy = cursors["com.apple.coregraphics.CopyDrag"] as? [String: Any]

        #expect(dragCopy?["PointsWide"] as? Double == 24.0)
        #expect(dragCopy?["PointsHigh"] as? Double == 24.0)
        #expect(dragCopy?["HotSpotX"] as? Double == 2.0)
        #expect(dragCopy?["HotSpotY"] as? Double == 2.0)
    }

    @MainActor
    @Test
    func exportSizeMultiplierIncreasesLogicalCursorSize() throws {
        let image = NSImage(size: NSSize(width: 32, height: 32))
        image.lockFocus()
        NSColor.white.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 32, height: 32)).fill()
        image.unlockFocus()

        let animation = CursorAnimation(
            frames: [CursorFrame(image: image, delay: 0.2)],
            hotspot: CGPoint(x: 4, y: 5),
            canvasSize: CGSize(width: 32, height: 32)
        )
        let theme = CursorTheme(animations: [.arrow: animation])

        let baseURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("cape")
        let largeURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("cape")
        defer {
            try? FileManager.default.removeItem(at: baseURL)
            try? FileManager.default.removeItem(at: largeURL)
        }

        try CapeExporter().exportCape(
            name: "Base",
            author: "Tester",
            identifier: "local.test.base",
            theme: theme,
            sizeMultiplier: 1.0,
            to: baseURL
        )

        try CapeExporter().exportCape(
            name: "Large",
            author: "Tester",
            identifier: "local.test.large",
            theme: theme,
            sizeMultiplier: 1.25,
            to: largeURL
        )

        let baseData = try Data(contentsOf: baseURL)
        let largeData = try Data(contentsOf: largeURL)
        let basePlist = try PropertyListSerialization.propertyList(from: baseData, options: [], format: nil) as? [String: Any]
        let largePlist = try PropertyListSerialization.propertyList(from: largeData, options: [], format: nil) as? [String: Any]
        let baseArrow = (basePlist?["Cursors"] as? [String: Any])?["com.apple.coregraphics.Arrow"] as? [String: Any]
        let largeArrow = (largePlist?["Cursors"] as? [String: Any])?["com.apple.coregraphics.Arrow"] as? [String: Any]

        #expect((largeArrow?["PointsWide"] as? Double ?? 0) > (baseArrow?["PointsWide"] as? Double ?? 0))
        #expect((largeArrow?["PointsHigh"] as? Double ?? 0) > (baseArrow?["PointsHigh"] as? Double ?? 0))
        #expect((largeArrow?["HotSpotX"] as? Double ?? 0) > (baseArrow?["HotSpotX"] as? Double ?? 0))
        #expect((largeArrow?["HotSpotY"] as? Double ?? 0) > (baseArrow?["HotSpotY"] as? Double ?? 0))
    }

    @MainActor
    @Test
    func exportSizeMultiplierStaysMonotonicAcrossScaleThreshold() throws {
        let image = NSImage(size: NSSize(width: 40, height: 40))
        image.lockFocus()
        NSColor.white.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 40, height: 40)).fill()
        image.unlockFocus()

        let animation = CursorAnimation(
            frames: [CursorFrame(image: image, delay: 0.2)],
            hotspot: CGPoint(x: 5, y: 6),
            canvasSize: CGSize(width: 40, height: 40)
        )
        let theme = CursorTheme(animations: [.arrow: animation])

        let baseURL = temporaryCapeURL()
        let midURL = temporaryCapeURL()
        let largeURL = temporaryCapeURL()
        defer {
            try? FileManager.default.removeItem(at: baseURL)
            try? FileManager.default.removeItem(at: midURL)
            try? FileManager.default.removeItem(at: largeURL)
        }

        try CapeExporter().exportCape(name: "Base", author: "Tester", identifier: "local.test.base2", theme: theme, sizeMultiplier: 1.0, to: baseURL)
        try CapeExporter().exportCape(name: "Mid", author: "Tester", identifier: "local.test.mid2", theme: theme, sizeMultiplier: 1.5, to: midURL)
        try CapeExporter().exportCape(name: "Large", author: "Tester", identifier: "local.test.large2", theme: theme, sizeMultiplier: 1.8, to: largeURL)

        let baseArrow = try exportedArrow(at: baseURL)
        let midArrow = try exportedArrow(at: midURL)
        let largeArrow = try exportedArrow(at: largeURL)

        let baseWidth = baseArrow["PointsWide"] as? Double ?? 0
        let midWidth = midArrow["PointsWide"] as? Double ?? 0
        let largeWidth = largeArrow["PointsWide"] as? Double ?? 0

        #expect(baseWidth < midWidth)
        #expect(midWidth < largeWidth)
        #expect((baseArrow["HotSpotX"] as? Double ?? 0) < (midArrow["HotSpotX"] as? Double ?? 0))
        #expect((midArrow["HotSpotX"] as? Double ?? 0) < (largeArrow["HotSpotX"] as? Double ?? 0))
    }

    @MainActor
    @Test
    func exportPreservesBaseLogicalSizeForRetinaSizedCursor() throws {
        let image = NSImage(size: NSSize(width: 80, height: 80))
        image.lockFocus()
        NSColor.white.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 80, height: 80)).fill()
        image.unlockFocus()

        let animation = CursorAnimation(
            frames: [CursorFrame(image: image, delay: 0.2)],
            hotspot: CGPoint(x: 8, y: 10),
            canvasSize: CGSize(width: 80, height: 80)
        )
        let theme = CursorTheme(animations: [.arrow: animation])

        let baseURL = temporaryCapeURL()
        let largeURL = temporaryCapeURL()
        defer {
            try? FileManager.default.removeItem(at: baseURL)
            try? FileManager.default.removeItem(at: largeURL)
        }

        try CapeExporter().exportCape(name: "Base", author: "Tester", identifier: "local.test.retina.base", theme: theme, sizeMultiplier: 1.0, to: baseURL)
        try CapeExporter().exportCape(name: "Large", author: "Tester", identifier: "local.test.retina.large", theme: theme, sizeMultiplier: 1.5, to: largeURL)

        let baseArrow = try exportedArrow(at: baseURL)
        let largeArrow = try exportedArrow(at: largeURL)

        #expect((baseArrow["PointsWide"] as? Double ?? 0) == 40)
        #expect((baseArrow["PointsHigh"] as? Double ?? 0) == 40)
        #expect((largeArrow["PointsWide"] as? Double ?? 0) == 60)
        #expect((largeArrow["PointsHigh"] as? Double ?? 0) == 60)
    }

    @MainActor
    @Test
    func previewDisplaySizeMatchesExportedCapePointSize() throws {
        let image = NSImage(size: NSSize(width: 80, height: 80))
        image.lockFocus()
        NSColor.white.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 80, height: 80)).fill()
        image.unlockFocus()

        let animation = CursorAnimation(
            frames: [CursorFrame(image: image, delay: 0.2)],
            hotspot: CGPoint(x: 8, y: 10),
            canvasSize: CGSize(width: 80, height: 80)
        )
        let theme = CursorTheme(animations: [.arrow: animation])
        let exportURL = temporaryCapeURL()
        defer { try? FileManager.default.removeItem(at: exportURL) }

        try CapeExporter().exportCape(
            name: "Preview Match",
            author: "Tester",
            identifier: "local.test.preview-match",
            theme: theme,
            sizeMultiplier: 2.3,
            to: exportURL
        )

        let arrow = try exportedArrow(at: exportURL)
        let previewSize = CapeExporter.previewDisplaySize(for: animation, sizeMultiplier: 2.3)
        let exportedWidth = arrow["PointsWide"] as? Double ?? 0
        let exportedHeight = arrow["PointsHigh"] as? Double ?? 0

        #expect(abs(exportedWidth - previewSize.width) < 0.001)
        #expect(abs(exportedHeight - previewSize.height) < 0.001)
    }

    @MainActor
    @Test
    func exportsCapeFromEnvironmentWhenRequested() throws {
        guard
            let folderPath = ProcessInfo.processInfo.environment["MAC_MOUSE_CURSOR_EXPORT_FOLDER"],
            let exportPath = ProcessInfo.processInfo.environment["MAC_MOUSE_CURSOR_EXPORT_PATH"],
            !folderPath.isEmpty,
            !exportPath.isEmpty
        else {
            return
        }

        let folderURL = URL(fileURLWithPath: folderPath, isDirectory: true)
        let exportURL = URL(fileURLWithPath: exportPath, isDirectory: false)

        let resolver = ThemeResolver()
        let parser = AniParser()
        let resolved = try resolver.resolveTheme(in: folderURL)
        var animations: [CursorRole: CursorAnimation] = [:]
        for (role, fileURL) in resolved.filesByRole {
            animations[role] = try parser.parseCursorFile(at: fileURL)
        }
        let theme = CursorTheme(animations: animations)

        try CapeExporter().exportCape(
            name: "Codex Integration Export",
            author: "Codex",
            identifier: "local.codex.integration",
            theme: theme,
            to: exportURL
        )

        #expect(FileManager.default.fileExists(atPath: exportURL.path))
        print("EXPORTED_CAPE_PATH=\(exportURL.path)")
    }
}

private func temporaryCapeURL() -> URL {
    URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("cape")
}

private func exportedArrow(at url: URL) throws -> [String: Any] {
    let data = try Data(contentsOf: url)
    let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
    return ((plist?["Cursors"] as? [String: Any])?["com.apple.coregraphics.Arrow"] as? [String: Any]) ?? [:]
}
