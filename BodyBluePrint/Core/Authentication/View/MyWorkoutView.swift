

import SwiftUI

struct MyWorkoutView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    let daysOfWeek = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea() // Full-screen black background
                VStack(alignment: .leading, spacing: 16) {
                    if let goal = viewModel.currentUser?.goal {
                        let schedule = workoutSchedule(for: viewModel.currentUser?.goal ?? "")
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2)) // Slightly brighter for visibility
                            .overlay(
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(daysOfWeek, id: \.self) { day in
                                        HStack {
                                            Text(day)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Spacer()
                                            Text(schedule[day] ?? "—")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                                    .padding(10)
                            )
                    } else {
                        ProgressView("Loading Schedule...")
                            .foregroundColor(.white)
                    }
                    
                    
                    HStack(spacing: 12) {
                        NavigationLink(destination: WorkoutsView()) {
                            Text("View Workouts")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            // TODO: Change workouts
                        }) {
                            Text("Change Workouts")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("My Workout")
            .withProfileToolbar()
        }
    }
}

#Preview {
    MyWorkoutView()
        .environmentObject(AuthViewModel())
}
