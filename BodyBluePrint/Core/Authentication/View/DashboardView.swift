import SwiftUI
import SDWebImageSwiftUI

struct DashboardView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @StateObject private var dashboardVM = DashboardViewModel()
    
    @State private var weight = ""
    @State private var reps = ""
    @State private var sets = ""
    
    var workoutsCompleted: Int {
        viewModel.currentUser?.workoutsCompleted ?? 0
    }
    
    var daysLoggedIn: Int {
        viewModel.currentUser?.daysLoggedIn ?? 0
    }
    
    var recommendedWeight: String {
        "5"
    }
    
    var recommendedReps: String {
        switch viewModel.currentUser?.fitnessGoalEnum {
        case .weightLoss:
            return "12"
        case .generalFitness:
            return "10"
        case .muscleGain:
            return "8"
        default:
            return "10"
        }
    }
    
    var recommendedSets: String {
        "3"
    }
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    // Stats
                    if !dashboardVM.workoutStarted {
                        HStack(spacing: 16) {
                            StatCard(title: "Workouts Completed", value: workoutsCompleted)
                            StatCard(title: "Days Logged", value: daysLoggedIn)
                        }
                    }
                    
                    // Today's workout type
                    Text("Today's Workout: \(dashboardVM.todayWorkoutType)")
                        .font(.title2)
                        .padding(.horizontal)
                    
                    // Exercise view
                    if let exercise = dashboardVM.todayExercises[safe: dashboardVM.currentExerciseIndex] {
                        VStack(spacing: 12) {
                            Text(exercise.name)
                                .font(.headline)
                                .padding(.top)
                            
                            HStack {
                                Spacer()
                                WebImage(url: URL(string: exercise.gifUrl))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                Spacer()
                            }
                            
                            if dashboardVM.workoutStarted {
                                VStack {
                                    Text("Weight")
                                        .foregroundColor(.white)
                                    TextField("Weight", text: $weight)
                                        .keyboardType(.decimalPad)
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(8)
                                    
                                    Text("Reps")
                                        .foregroundColor(.white)
                                    TextField("Reps", text: $reps)
                                        .keyboardType(.numberPad)
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(8)
                                    
                                    Text("Sets")
                                        .foregroundColor(.white)
                                    TextField("Sets", text: $sets)
                                        .keyboardType(.numberPad)
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(8)
                                }
                                
                                if !dashboardVM.workoutFinished {
                                    HStack {
                                        Spacer()
                                        Button("Next Exercise") {
                                            Task {
                                                if let weightDouble = Double(weight), let repsInt = Int(reps), let setsInt = Int(sets) {
                                                    await dashboardVM.saveWeightEntry(
                                                        for: dashboardVM.todayExercises[dashboardVM.currentExerciseIndex],
                                                        weight: weightDouble,
                                                        reps: repsInt,
                                                        sets: setsInt
                                                    )
                                                }
                                                dashboardVM.nextExercise()
                                                if let exercise = dashboardVM.todayExercises[safe: dashboardVM.currentExerciseIndex],
                                                   let saved = dashboardVM.savedInputs[exercise.id] {
                                                    weight = String(saved.weight)
                                                    reps = recommendedReps
                                                    sets = recommendedSets
                                                } else {
                                                    weight = recommendedWeight
                                                }
                                            }
                                        }
                                        .buttonStyle(.borderedProminent)
                                        Spacer()
                                    }
                                    
                                    
                                } else {
                                    Button("Stop Workout") {
                                        dashboardVM.workoutStarted = false
                                        dashboardVM.workoutFinished = false
                                        weight = ""
                                        reps = ""
                                        sets = ""
                                        Task {
                                            await viewModel.incrementWorkoutsCompleted()
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal)
                                    .cornerRadius(12)
                                    .foregroundColor(.red)
                                }
                            } else {
                                HStack {
                                    Button("Start Workout") {
                                        dashboardVM.workoutStarted = true
                                        if let exercise = dashboardVM.todayExercises[safe: dashboardVM.currentExerciseIndex],
                                           let saved = dashboardVM.savedInputs[exercise.id] {
                                            weight = String(saved.weight)
                                            reps = recommendedReps
                                            sets = recommendedSets
                                        } else {
                                            weight = recommendedWeight
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal)
                                    .cornerRadius(12)
                                }
                                .frame(maxWidth: .infinity)

                                
                            }
                        }
                        .padding()
                    } else {
                        Text("No exercises scheduled today.")
                            .foregroundColor(.gray)
                            .padding()
                    }
                    
                    Spacer()
                }
                .foregroundColor(.white)
                .padding()
            }
            .navigationTitle("Dashboard")
            .withProfileToolbar()
        }
        .task {
            if let user = viewModel.currentUser {
                await dashboardVM.loadTodayWorkout(goal: user.fitnessGoalEnum!, userId: user.id)
                await dashboardVM.loadSavedInputs(userId: user.id)
                
                if let firstExercise = dashboardVM.todayExercises.first,
                   let saved = dashboardVM.savedInputs[firstExercise.id] {
                    weight = String(saved.weight)
                    reps = String(saved.reps)
                    sets = String(saved.sets)
                } else {
                    weight = recommendedWeight
                    reps = recommendedReps
                    sets = recommendedSets
                }
            }
        }
    }
}


struct StatCard: View {
    let title: String
    let value: Int

    var body: some View {
        VStack {
            Text("\(value)")
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
}

// Helper for safe array access
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}




#Preview {
    DashboardView()
        .environmentObject(AuthViewModel())
}

