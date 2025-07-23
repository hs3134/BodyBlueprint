
import SwiftUI

struct RankingView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    var body: some View {
        NavigationStack {
            Text("Muscle Ranking")
                .navigationTitle("Ranking")
                .withProfileToolbar()
        }
    }
}

#Preview {
    RankingView()
        .environmentObject(AuthViewModel())

}
