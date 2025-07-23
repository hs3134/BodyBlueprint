

import SwiftUI

struct UserProfileSetupView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var height = ""
    @State private var weight = ""
    @State private var goal = "Weight Loss"
    @State private var isDone = false
    
    let goals = ["Weight Loss", "Muscle Gain", "General Fitness"]
    
    var body: some View {
        VStack {
            Text("Set Up Your Profile")
                .font(.title)
                .padding()

            Form {
                Section(header: Text("Physical Info")) {
                    TextField("Height (cm)", text: $height)
                        .keyboardType(.numberPad)
                    TextField("Weight (kg)", text: $weight)
                        .keyboardType(.numberPad)
                }
                .padding(.top, 7)

                Section(header: Text("Workout Goal")) {
                    Picker("Goal", selection: $goal) {
                        ForEach(goals, id: \.self) { goal in
                            Text(goal)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }

            Button("Continue") {
                Task {
                    do {
                        try await viewModel.saveUserProfile(height: height, weight: weight, goal: goal)
                        isDone = true
                    } catch {
                        print("Failed to save profile: \(error.localizedDescription)")
                    }
                }
            }
            .disabled(height.isEmpty || weight.isEmpty)
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .fullScreenCover(isPresented: $isDone) {
            HomeView()
                .environmentObject(viewModel)
        }
    }
}

#Preview {
    UserProfileSetupView()
        .environmentObject(AuthViewModel())
}
