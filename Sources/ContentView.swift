import SwiftUI

struct ContentView: View {
    @ObservedObject var controller: CursorController

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Mac Mouse Cursor")
                .font(.headline)

            Text(controller.selectedFolderURL?.lastPathComponent ?? "커서 폴더를 선택하세요")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Label(
                controller.selectedFolderIsValid
                    ? "\(controller.resolvedRoleCount)개 역할 준비됨"
                    : "폴더 확인 필요",
                systemImage: controller.selectedFolderIsValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
            )
            .font(.footnote)
            .foregroundStyle(controller.selectedFolderIsValid ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.orange))

            HStack(spacing: 8) {
                Button("설정 열기") {
                    (NSApp.delegate as? AppDelegate)?.openSettingsWindow()
                }
                Button("다시 불러오기") {
                    controller.reload()
                }
            }

            Divider()

            Text(controller.statusText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button("종료") {
                NSApp.terminate(nil)
            }
        }
        .padding(14)
        .frame(width: 280)
    }
}

struct SettingsView: View {
    @ObservedObject var controller: CursorController
    @State private var selection: CursorRole? = .arrow

    var body: some View {
        NavigationSplitView {
            List(CursorRole.allCases, selection: $selection) { role in
                if let assignment = controller.assignment(for: role) ?? controller.placeholderAssignment(for: role) {
                    CursorRoleRow(assignment: assignment)
                        .tag(role)
                }
            }
            .navigationTitle("커서")
            .frame(minWidth: 230)
        } detail: {
            if let role = selection, let assignment = controller.assignment(for: role) ?? controller.placeholderAssignment(for: role) {
                CursorRoleDetailView(controller: controller, assignment: assignment)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "cursorarrow")
                        .font(.system(size: 30))
                        .foregroundStyle(.secondary)
                    Text("커서를 선택하세요")
                        .font(.headline)
                    Text("왼쪽 목록에서 역할을 고르면 상세 설정과 미리보기를 볼 수 있습니다.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 860, minHeight: 620)
    }
}

struct CursorRoleRow: View {
    let assignment: CursorAssignment

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: statusSymbolName)
                .foregroundStyle(statusColor)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(assignment.role.displayName)
                Text(assignment.role.englishName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
    }

    private var statusSymbolName: String {
        if !assignment.isResolved { return "exclamationmark.triangle.fill" }
        if assignment.usesArrowFallback { return "exclamationmark.triangle.fill" }
        if assignment.isOverride { return "slider.horizontal.3" }
        return "checkmark.circle.fill"
    }

    private var statusColor: Color {
        if !assignment.isResolved { return .orange }
        if assignment.usesArrowFallback { return .orange }
        if assignment.isOverride { return .accentColor }
        return .secondary
    }

    private var subtitle: String {
        if !assignment.isResolved { return "자동 매핑 실패" }
        if assignment.usesArrowFallback { return "자동 매핑 실패 · 일반 커서 대체" }
        if assignment.isOverride { return assignment.sourceURL?.lastPathComponent ?? "수동 지정" }
        return assignment.sourceURL?.lastPathComponent ?? "자동 매핑"
    }
}

struct CursorRoleDetailView: View {
    @ObservedObject var controller: CursorController
    let assignment: CursorAssignment

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsHeader(controller: controller)

                VStack(alignment: .leading, spacing: 12) {
                    Text(assignment.role.displayName)
                        .font(.title2)
                    Text(assignment.role.englishName)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("기본 커서와 현재 적용 중인 커서를 비교하고, 필요하면 이 역할만 별도로 지정할 수 있습니다.")
                        .foregroundStyle(.secondary)
                }

                HStack(alignment: .top, spacing: 20) {
                    PreviewGroup(
                        title: "현재 시스템 커서",
                        subtitle: "지금 시스템에 등록된 포인터 미리보기",
                        animation: assignment.defaultPreview
                    )
                    PreviewGroup(
                        title: "적용 커서",
                        subtitle: assignment.sourceURL?.lastPathComponent ?? "폴더에서 자동 매핑된 파일",
                        animation: assignment.appliedPreview ?? assignment.defaultPreview
                    )
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 14) {
                        if assignment.usesArrowFallback {
                            Label("자동 매칭되는 전용 커서를 찾지 못해 이 테마의 일반 커서로 대체했습니다.", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                        LabeledContent("역할") {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(assignment.role.displayName)
                                Text(assignment.role.englishName)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        LabeledContent("자동 파일명") {
                            Text(assignment.role.themeFileName)
                                .textSelection(.enabled)
                        }
                        LabeledContent("현재 소스") {
                            Text(assignment.sourceURL?.path ?? "선택한 폴더 안에서 자동 매핑")
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                                .textSelection(.enabled)
                        }
                        if assignment.usesArrowFallback {
                            LabeledContent("상태") {
                                Text("자동 매핑 실패 (일반 커서 대체)")
                                    .foregroundStyle(.orange)
                            }
                        }
                        Divider()
                        HStack {
                            Button("커서 파일 변경…") {
                                controller.chooseOverride(for: assignment.role)
                            }
                            if assignment.sourceURL != nil {
                                Button("자동 매핑으로 되돌리기") {
                                    controller.clearOverride(for: assignment.role)
                                }
                            }
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("할당")
                }

                Text(controller.statusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct SettingsHeader: View {
    @ObservedObject var controller: CursorController

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("커서 폴더")
                            .font(.headline)
                        Text(controller.selectedFolderURL?.path ?? "선택된 폴더 없음")
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    Spacer()
                    Button("폴더 선택…") {
                        controller.chooseThemeFolder()
                    }
                }

                HStack(spacing: 12) {
                    Label(
                        controller.selectedFolderIsValid
                            ? "\(controller.resolvedRoleCount)개 역할을 사용할 수 있습니다"
                            : "선택한 폴더를 확인해야 합니다",
                        systemImage: controller.selectedFolderIsValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(controller.selectedFolderIsValid ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.orange))

                    if controller.selectedFolderIsValid {
                        Text("자동 매핑 후 필요한 역할만 개별적으로 재지정할 수 있습니다.")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.footnote)

                HStack(spacing: 18) {
                    Spacer()
                    Button("Mousecape로 내보내기…") {
                        controller.exportMousecapeCape()
                    }
                    Button("다시 불러오기") {
                        controller.reload()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct PreviewGroup: View {
    let title: String
    let subtitle: String
    let animation: CursorAnimation

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                CursorPreviewView(animation: animation)
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        } label: {
            Text(title)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CursorPreviewView: View {
    let animation: CursorAnimation

    var body: some View {
        TimelineView(.animation) { context in
            let index = currentIndex(at: context.date)
            Image(nsImage: animation.frames[index].image)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .padding(24)
        }
    }

    private func currentIndex(at date: Date) -> Int {
        guard animation.frames.count > 1 else { return 0 }
        let total = animation.frames.reduce(0.0) { $0 + $1.delay }
        guard total > 0 else { return 0 }
        let elapsed = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: total)
        var running = 0.0
        for (index, frame) in animation.frames.enumerated() {
            running += frame.delay
            if elapsed < running {
                return index
            }
        }
        return animation.frames.count - 1
    }
}
