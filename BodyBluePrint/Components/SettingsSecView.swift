

import SwiftUI

struct SettingsSecView: View {
    let imageName : String
    let title: String
    let BackColour: Color
    var body: some View {
        HStack(spacing:12){
            Image(systemName: imageName)
                .imageScale(.small)
                .font(.title)
                .foregroundColor(BackColour)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.black)
            
        }
    }
}

#Preview {
    SettingsSecView(imageName: "gear", title: "Height", BackColour: Color(.systemGray))
}
