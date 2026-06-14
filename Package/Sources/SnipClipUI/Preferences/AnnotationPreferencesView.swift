import SwiftUI

struct AnnotationPreferencesView: View {
    @ObservedObject var viewModel: SettingsViewModel

    private static let labelWidth: CGFloat = 72
    private static let controlWidth: CGFloat = 360
    private static let trailingWidth: CGFloat = 96
    private static let rowSpacing: CGFloat = 12

    var body: some View {
        Form {
            Section("默认标注样式") {
                preferenceRow("颜色") {
                    Spacer(minLength: 0)
                } trailing: {
                    ColorPicker("", selection: colorBinding)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                preferenceRow("线宽") {
                    Slider(value: Binding(
                        get: { viewModel.defaultLineWidth },
                        set: { viewModel.commitLineWidth($0) }
                    ), in: 1...8, step: 0.5)
                } trailing: {
                    Text(String(format: "%.1f", viewModel.defaultLineWidth))
                        .monospacedDigit()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                preferenceRow("文字字号") {
                    Slider(value: Binding(
                        get: { viewModel.defaultFontSize },
                        set: { viewModel.commitFontSize($0) }
                    ), in: 10...72, step: 2)
                } trailing: {
                    HStack(spacing: 6) {
                        TextField("", value: Binding(
                            get: { viewModel.defaultFontSize },
                            set: { viewModel.commitFontSizeInput($0) }
                        ), format: .number)
                            .frame(width: 44)
                            .multilineTextAlignment(.center)

                        Stepper("", value: Binding(
                            get: { viewModel.defaultFontSize },
                            set: { viewModel.commitFontSize($0) }
                        ), in: 10...72, step: 2)
                            .labelsHidden()
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .formStyle(.grouped)
        .padding(16)
    }

    private var colorBinding: Binding<Color> {
        Binding(
            get: {
                let hex = viewModel.defaultColorHex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
                guard hex.count == 6, let value = UInt32(hex, radix: 16) else { return .red }
                return Color(
                    red: Double((value >> 16) & 0xFF) / 255,
                    green: Double((value >> 8) & 0xFF) / 255,
                    blue: Double(value & 0xFF) / 255
                )
            },
            set: { newColor in
                let resolved = newColor.resolve(in: .init())
                let r = UInt8(resolved.red * 255)
                let g = UInt8(resolved.green * 255)
                let b = UInt8(resolved.blue * 255)
                viewModel.commitColor(String(format: "#%02X%02X%02X", r, g, b))
            }
        )
    }

    private func preferenceRow<Content: View, Trailing: View>(
        _ title: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: Self.rowSpacing) {
            Text(title)
                .frame(width: Self.labelWidth, alignment: .leading)

            content()
                .frame(width: Self.controlWidth, alignment: .trailing)

            trailing()
                .frame(width: Self.trailingWidth, alignment: .trailing)
        }
    }
}
