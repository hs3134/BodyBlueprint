

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }

            MyWorkoutView()
                .tabItem {
                    Label("My Workout", systemImage: "figure.strengthtraining.traditional")
                }

            StatisticsView()
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar.fill")
                }

            RankingView()
                .tabItem {
                    Label("Ranking", systemImage: "list.number")
                }
        }
    }
}



#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}
