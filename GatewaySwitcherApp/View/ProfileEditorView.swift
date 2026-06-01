import SwiftUI
import Core

struct ProfileEditorView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var editorVM: ProfileEditorViewModel

    init(isNew: Bool, profile: GatewayProfile) {
        _editorVM = StateObject(wrappedValue: ProfileEditorViewModel(isNew: isNew, profile: profile))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(editorVM.isNew ? "新增网关" : "编辑网关")
                .font(.title2.weight(.bold))

            Form {
                TextField("标题", text: $editorVM.title)

                TextField("网关 IP", text: $editorVM.gateway)
                    .onChange(of: editorVM.gateway) { _, _ in
                        editorVM.validateGateway()
                    }

                if let gatewayError = editorVM.gatewayError {
                    Text(gatewayError)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                Toggle("DNS 与网关相同", isOn: $editorVM.dnsSameAsGateway)

                if !editorVM.dnsSameAsGateway {
                    TextField("DNS 服务器（逗号分隔）", text: $editorVM.customDNS)
                    Text("示例：8.8.8.8, 8.8.4.4")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                TextField("描述", text: $editorVM.description)

                SFSymbolPicker(selectedIndex: $editorVM.selectedSymbolIndex, options: ProfileEditorViewModel.symbolOptions)
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("取消") { dismiss() }
                Button("保存") {
                    let profile = editorVM.buildProfile()
                    if editorVM.isNew {
                        viewModel.addProfile(profile)
                    } else {
                        viewModel.updateProfile(profile)
                    }
                    dismiss()
                }
                .disabled(!editorVM.canSave)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(minWidth: 480, minHeight: 500)
    }
}

private struct SFSymbolPicker: View {
    @Binding var selectedIndex: Int
    let options: [(name: String, label: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("图标")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(48), spacing: 8), count: 5), spacing: 8) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    Button {
                        selectedIndex = index
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: option.name)
                                .font(.title3)
                                .frame(width: 40, height: 40)
                            Text(option.label)
                                .font(.system(size: 9))
                                .lineLimit(1)
                        }
                        .frame(width: 48, height: 56)
                        .background(selectedIndex == index ? Color.accentColor.opacity(0.2) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(selectedIndex == index ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: selectedIndex == index ? 2 : 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}