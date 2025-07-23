
import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @StateObject private var statsViewModel = StatisticsViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                if statsViewModel.entriesByGroup.isEmpty {
                    ProgressView("Loading stats...")
                        .padding()
                } else {
                    Picker("Select Group", selection: $statsViewModel.selectedGroup) {
                        ForEach(statsViewModel.entriesByGroup.keys.sorted(), id: \.self) { group in
                            Text(group).tag(group)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    if let entries = statsViewModel.entriesByGroup[statsViewModel.selectedGroup] {
                        Chart {
                            ForEach(entries) { entry in
                                LineMark(
                                    x: .value("Date", entry.date),
                                    y: .value("Weight", entry.weight)
                                )
                                .foregroundStyle(by: .value("Exercise", entry.exerciseName))
                                .symbol(by: .value("Exercise", entry.exerciseName))
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .frame(height: 300)
                        .padding(.horizontal)
                    } else {
                        Text("No data available.")
                            .padding()
                    }
                }
            }
            .navigationTitle("Statistics")
            .withProfileToolbar()
            .onAppear {
                Task {
                    if let userId = viewModel.currentUser?.id {
                        await statsViewModel.loadAllExerciseData(userId: userId)
                    }
                }
            }
        }
    }
}


#Preview {
    StatisticsView()
        .environmentObject(AuthViewModel())

}
