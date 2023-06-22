//
//  BottleIcon.swift
//  Whisky
//
//  Created by Josh on 6/22/23.
//

import SwiftUI

struct BottleIcon: View {
    var color: Color
    var icon: Icon
    var size: CGFloat
    var body: some View {
        VStack {
            switch icon {
            case .emoji(let emoji):
                Text(emoji)
                .font(.system(size: 1000))
                .minimumScaleFactor(0.005)
                .lineLimit(1)
                .frame(width: size * 0.6, height: size * 0.6)
                .padding(.top, size * -0.07)
            case .symbol(let symbol):
                Image(systemName: symbol.name)
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.5, height: size * 0.5)
            }
        }
        .frame(width: size, height: size)
        .background(color.toUIColor())
        .foregroundStyle(shouldAppearDark() ? .black : .white)
        .border(color.toUIColor())
        .clipShape(.rect(cornerSize: .init(
            width: 0.2 * self.size,
            height: 0.2 * self.size
        )))
    }
    func shouldAppearDark() -> Bool {
        let lightRed = Float(color.red) / 255 > 0.65
        let lightGreen = Float(color.green) / 255 > 0.65
        let lightBlue = Float(color.blue) / 255 > 0.65

        let lightness = [lightRed, lightGreen, lightBlue].reduce(0) { $1 ? $0 + 1 : $0 }
        return lightness >= 2
    }
}

struct BottleIcon_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            BottleIcon(color: .init(red: 4, green: 120, blue: 87), icon: .symbol(.wineglass), size: 100)
            BottleIcon(color: .init(red: 196, green: 181, blue: 253), icon: .symbol(.airplane), size: 100)
            BottleIcon(color: .init(red: 251, green: 146, blue: 60), icon: .emoji("🎮"), size: 50)
            BottleIcon(color: .init(red: 245, green: 208, blue: 254), icon: .symbol(.gamecontrollerFill), size: 100)
        }
        .padding(20)
    }
}
