

import Foundation
import SwiftUI

struct ProfileToolbarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "gearshape.fill")
                            .imageScale(.large)
                    }
                }
            }
    }
}

extension View {
    func withProfileToolbar() -> some View {
        self.modifier(ProfileToolbarModifier())
    }
}

