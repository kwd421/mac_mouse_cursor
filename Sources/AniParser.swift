import AppKit
import Foundation

struct AniParser {
    func parseCursorFile(at url: URL) throws -> CursorAnimation {
        switch url.pathExtension.lowercased() {
        case "ani":
            return try parseANI(at: url)
        case "cur":
            let data = try Data(contentsOf: url)
            return try parseCUR(data: data)
        default:
            throw CursorError.invalidANI("지원하지 않는 확장자입니다: \(url.pathExtension)")
        }
    }

    func parseANI(at url: URL) throws -> CursorAnimation {
        let data = try Data(contentsOf: url)
        return try parseANI(data: data)
    }

    func parseANI(data: Data) throws -> CursorAnimation {
        guard data.count >= 12, data[0..<4] == Data("RIFF".utf8), data[8..<12] == Data("ACON".utf8) else {
            throw CursorError.invalidANI("RIFF ACON 헤더가 아닙니다.")
        }

        var jiffies = 6
        var cursorChunks: [Data] = []
        var offset = 12

        while offset + 8 <= data.count {
            let chunkID = fourCC(data, offset)
            let chunkSize = Int(readUInt32LE(data, offset + 4))
            let chunkDataStart = offset + 8
            let chunkDataEnd = chunkDataStart + chunkSize
            guard chunkDataEnd <= data.count else {
                throw CursorError.invalidANI("청크 길이가 잘못되었습니다.")
            }

            if chunkID == "anih", chunkSize >= 36 {
                jiffies = Int(readUInt32LE(data, chunkDataStart + 28))
            } else if chunkID == "LIST", chunkSize >= 4 {
                let listType = fourCC(data, chunkDataStart)
                if listType == "fram" {
                    cursorChunks.append(contentsOf: try extractIconChunks(from: Data(data[chunkDataStart + 4..<chunkDataEnd])))
                }
            } else if chunkID == "rate", chunkSize >= 4 {
                jiffies = Int(readUInt32LE(data, chunkDataStart))
            }

            offset = chunkDataEnd + (chunkSize & 1)
        }

        let frames = try cursorChunks.map { chunk in
            try decodeFrame(from: chunk, defaultDelay: TimeInterval(max(jiffies, 1)) / 60.0)
        }
        guard let first = frames.first else {
            throw CursorError.invalidANI("프레임이 없습니다.")
        }

        return CursorAnimation(
            frames: frames.map { CursorFrame(image: $0.image, delay: $0.delay) },
            hotspot: first.hotspot,
            canvasSize: first.size
        )
    }

    func parseCUR(data: Data) throws -> CursorAnimation {
        let frame = try decodeFrame(from: data, defaultDelay: 1.0)
        return CursorAnimation(
            frames: [CursorFrame(image: frame.image, delay: 1.0)],
            hotspot: frame.hotspot,
            canvasSize: frame.size
        )
    }

    private func extractIconChunks(from data: Data) throws -> [Data] {
        var chunks: [Data] = []
        var offset = data.startIndex
        while offset + 8 <= data.endIndex {
            let chunkID = fourCC(data, offset)
            let chunkSize = Int(readUInt32LE(data, offset + 4))
            let start = offset + 8
            let end = start + chunkSize
            guard end <= data.endIndex else {
                throw CursorError.invalidANI("icon 청크 길이가 잘못되었습니다.")
            }
            if chunkID == "icon" {
                chunks.append(data[start..<end])
            }
            offset = end + (chunkSize & 1)
        }
        return chunks
    }

    private func decodeFrame(from data: Data, defaultDelay: TimeInterval) throws -> (image: NSImage, hotspot: CGPoint, size: CGSize, delay: TimeInterval) {
        let data = Data(data)
        guard data.count >= 22 else {
            throw CursorError.invalidANI("CUR 데이터가 너무 짧습니다.")
        }
        let type = readUInt16LE(data, 2)
        let count = readUInt16LE(data, 4)
        guard type == 2, count >= 1 else {
            throw CursorError.invalidANI("CUR 헤더가 아닙니다.")
        }

        let widthByte = Int(data[6])
        let heightByte = Int(data[7])
        let hotspotX = Int(readUInt16LE(data, 10))
        let hotspotY = Int(readUInt16LE(data, 12))
        let imageBytes = Int(readUInt32LE(data, 14))
        let imageOffset = Int(readUInt32LE(data, 18))
        guard imageOffset + imageBytes <= data.count else {
            throw CursorError.invalidANI("CUR 내부 이미지 범위가 잘못되었습니다.")
        }

        let imagePayload = Data(data[imageOffset..<(imageOffset + imageBytes)])
        guard let image = NSImage(data: data) ?? NSImage(data: imagePayload) else {
            throw CursorError.unsupportedCursorPayload
        }

        let rep = image.representations.compactMap { $0 as? NSBitmapImageRep }.max {
            ($0.pixelsWide * $0.pixelsHigh) < ($1.pixelsWide * $1.pixelsHigh)
        }
        let width = rep?.pixelsWide ?? max(widthByte, 32)
        let height = rep?.pixelsHigh ?? max(heightByte, 32)

        return (
            image: image,
            hotspot: CGPoint(x: hotspotX, y: hotspotY),
            size: CGSize(width: width, height: height),
            delay: defaultDelay
        )
    }

    private func fourCC(_ data: Data, _ offset: Int) -> String {
        String(decoding: data[offset..<(offset + 4)], as: UTF8.self)
    }

    private func readUInt16LE(_ data: Data, _ offset: Int) -> UInt16 {
        let range = offset..<(offset + 2)
        return data.withUnsafeBytes { rawBuffer in
            let base = rawBuffer.baseAddress!.advanced(by: range.lowerBound)
            return base.loadUnaligned(as: UInt16.self).littleEndian
        }
    }

    private func readUInt32LE(_ data: Data, _ offset: Int) -> UInt32 {
        let range = offset..<(offset + 4)
        return data.withUnsafeBytes { rawBuffer in
            let base = rawBuffer.baseAddress!.advanced(by: range.lowerBound)
            return base.loadUnaligned(as: UInt32.self).littleEndian
        }
    }
}
