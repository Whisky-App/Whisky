//
//  RegistryValueView.swift
//  Whisky
//
//  Created by Amrit Bhogal on 08/06/2023.
//

import SwiftUI

struct RegistryValueView: View {
    let value: RegistryValue

    var body: some View {
        Group {
            switch value {
            case .string(let string):
                Text(string)

            case .dword(let dword):
                Text(String(dword))

            case .qword(let qword):
                Text(String(qword))

            case .hex(let array):
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(array, id: \.self) { row in
                        HStack {
                            ForEach(row, id: \.self) { item in
                                Text(String(format: "%02X", item))
                            }
                        }
                    }
                }
            }
        }
        .font(.subheadline)
        .padding(5)
        .background(value.backgroundColor.opacity(0.2))
        .cornerRadius(5)
    }
}

extension RegistryValue {
    @ViewBuilder
    func displayView() -> some View {
        Group {
            switch self {
            case .string(let string):
                Text(string)
                    .font(.subheadline)
                    .padding(5)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(5)
            case .dword(let dword):
                Text(String(dword))
                    .font(.subheadline)
                    .padding(5)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(5)
            case .qword(let qword):
                Text(String(qword))
                    .font(.subheadline)
                    .padding(5)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(5)
            case .hex(let array):
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(array, id: \.self) { row in
                        HStack {
                            ForEach(row, id: \.self) { item in
                                Text(String(format: "%02X", item))
                            }
                        }
                    }
                }
                .font(.subheadline)
                .padding(5)
                .background(Color.purple.opacity(0.2))
                .cornerRadius(5)
            }
        }
    }
}

extension RegistryValue {
    var backgroundColor: Color {
        switch self {
        case .string: return Color.green
        case .dword: return Color.blue
        case .qword: return Color.red
        case .hex: return Color.purple
        }
    }
}

struct RegistryValueView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RegistryValueView(value: .string("Example String"))
                .previewDisplayName("String")
                .padding()

            RegistryValueView(value: .dword(12345))
                .previewDisplayName("DWORD")
                .padding()

            RegistryValueView(value: .qword(6789012345))
                .previewDisplayName("QWORD")
                .padding()

            RegistryValueView(value: .hex([[0x1A, 0x2B, 0x3C, 0x4D], [0x5E, 0x6F]]))
                .previewDisplayName("Hex")
                .padding()
        }
    }
}
