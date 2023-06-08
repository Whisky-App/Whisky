//
//  RegistrySectionContentView.swift
//  Whisky
//
//  Created by Amrit Bhogal on 08/06/2023.
//

import SwiftUI

struct RegistrySectionContentView: View {
    let viewModel: RegistrySectionVM

    var body: some View {
        VStack {
            Text(viewModel.name)
                .font(.title)
                .padding(.bottom, 20)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    
                    if let values = viewModel.values {
                        ForEach(values.keys.sorted(), id: \.self) { key in
                            HStack {
                                Text(key).bold()
                                Spacer()
                                RegistryValueView(value: values[key]!)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
                .padding()
            }
        }
    }
}
