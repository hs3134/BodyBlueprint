

import SwiftUI
import FirebaseAuth


struct WorkoutsView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var exercises: [Exercise] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ScrollView {
            VStack {
                Text("Your Workouts")
                    .font(.largeTitle)
                    .padding()
                
                if isLoading {
                    ProgressView("Loading workouts...")
                        .padding()
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else if exercises.isEmpty {
                    Text("No exercises available for your goal.")
                        .foregroundColor(.white)
                        .padding()
                } else {
                    ForEach(exercises) { exercise in
                        VStack {
                            Text(exercise.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            AsyncImage(url: URL(string: exercise.gifUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                            } placeholder: {
                                ProgressView()
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            print("DEBUG: Current user session: \(String(describing: viewModel.userSession))")
            fetchWorkouts()
        }
    }
    
    func fetchWorkouts() {
        guard let goalString = viewModel.currentUser?.goal else {
            print("No goal found for user")
            return
        }

        guard let goal = FitnessGoal(rawValue: goalString) else {
            print("Invalid goal value: \(goalString)")
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            if let userId = viewModel.userId {
                // Fetch exercises and handle Firestore data
                let fetchedExercises = await WorkoutScheduler.shared.fetchExercises(for: goal, userId: userId)
                
                // Ensure you are updating UI on the main thread
                DispatchQueue.main.async {
                    if fetchedExercises.isEmpty {
                        errorMessage = "No exercises available for your goal."
                    } else {
                        exercises = fetchedExercises
                    }
                    isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    errorMessage = "User not logged in."
                    isLoading = false
                }
            }
        }
    }

}


#Preview {
    WorkoutsView()
        .environmentObject(AuthViewModel())
}

