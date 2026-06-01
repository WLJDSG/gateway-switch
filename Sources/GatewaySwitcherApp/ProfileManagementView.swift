import SwiftUI
import SharedKit

struct ProfileManagementView: View {
    @EnvironmentObject private var appState: AppState
    @State private var editingProfile: GatewayProfile?
    @State private var isAddingNew = false
    @State private var showDeleteConfirmation: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("网关配置")
                    .font(.title2.weight(.bold))
                Spacer()
                Button {
                    isAddingNew = true
                } label: {
                    Label("新增网关", systemImage: "plus")
                }
            }

            if appState.profiles.isEmpty {
                Text("暂无网关配置，点击「新增网关」添加。")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                List(appState.profiles) { profile in
                    HStack(spacing: 12) {
                        Image(systemName: profile.symbolName)
                            .font(.title3)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile.title)
                                .font(.headline)
                            Text(profile.gateway)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if appState.activeProfile?.id == profile.id {
                            Text("使用中")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.green)
                        }

                        Button {
                            editingProfile = profile
                        } label: {
                            Image(systemName: "pencil.circle")
                        }
                        .buttonStyle(.borderless)

                        Button {
                            showDeleteConfirmation = profile.id
                        } label: {
                            Image(systemName: "trash.circle")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 4)
                }
                .frame(minHeight: 200)
            }
        }
        .padding(24)
        .frame(minWidth: 500, minHeight: 400)
        .sheet(isPresented: $isAddingNew) {
            ProfileEditorView(isNew: true, profile: GatewayProfile(title: "", gateway: "", description: ""))
                .environmentObject(appState)
        }
        .sheet(item: $editingProfile) { profile in
            ProfileEditorView(isNew: false, profile: profile)
                .environmentObject(appState)
        }
        .alert("确认删除", isPresented: Binding(
            get: { showDeleteConfirmation != nil },
            set: { if !$0 { showDeleteConfirmation = nil } }
        )) {
            Button("删除", role: .destructive) {
                if let id = showDeleteConfirmation {
                    appState.deleteProfile(id: id)
                }
                showDeleteConfirmation = nil
            }
            Button("取消", role: .cancel) {
                showDeleteConfirmation = nil
            }
        } message: {
            Text("删除后无法恢复，确定要删除此网关配置吗？")
        }
    }
}