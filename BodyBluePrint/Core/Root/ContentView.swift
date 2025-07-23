

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AuthViewModel

    var body: some View {
        Group {
            if viewModel.userSession == nil {
                // User is not signed in
                LoginView()
            } else if let user = viewModel.currentUser {
                // User is signed in, check if profile setup is done
                if user.height == nil || user.weight == nil || user.goal == nil {
                    UserProfileSetupView()
                } else {
                    HomeView()
                }
            } else {
                // User session exists, but current user is still loading
                ProgressView()
                    .onAppear {
                        Task {
                            await viewModel.fetchUser()
                        }
                    }
            }
        }
    }
}


#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
