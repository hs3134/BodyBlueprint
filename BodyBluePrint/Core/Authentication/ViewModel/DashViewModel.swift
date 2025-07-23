
import Foundation
import FirebaseFirestore
import FirebaseAuth

class DashboardViewModel: ObservableObject {
    @Published var todayExercises: [Exercise] = []
    @Published var currentExerciseIndex: Int = 0
    @Published var workoutStarted = false
    @Published var workoutFinished = false
    @Published var todayWorkoutType: String = ""
    @Published var savedInputs: [String: ExerciseInput] = [:]

    
    func loadTodayWorkout(goal: FitnessGoal, userId: String) async {
        let weekday = Calendar.current.weekdaySymbols[Calendar.current.component(.weekday, from: Date()) - 1]
        let schedule = workoutSchedule(for: goal.rawValue)
        let workoutType = schedule[weekday] ?? ""
        
        await MainActor.run {
            self.todayWorkoutType = workoutType
        }
        
        do {
            let db = Firestore.firestore()
            let snapshot = try await db.collection("Workouts").document(userId).getDocument()
            if let data = snapshot.data(), let categorized = data["exercises"] as? [String: [[String: Any]]] {
                let exercises: [Exercise]
                
                switch workoutType {
                    case "Push Day": exercises = decodeExercises(from: categorized["pushExercises"] ?? [])
                    case "Pull Day": exercises = decodeExercises(from: categorized["pullExercises"] ?? [])
                    case "Leg Day": exercises = decodeExercises(from: categorized["legExercises"] ?? [])
                    case "Upper Body + Cardio": exercises = decodeExercises(from: categorized["upper body"] ?? []) + decodeExercises(from: categorized["cardio"] ?? [])
                    case "Upper body": exercises = decodeExercises(from: categorized["upper body"] ?? [])
                    case "Lower Body": exercises = decodeExercises(from: categorized["lower body"] ?? [])
                    case "Cardio": exercises = decodeExercises(from: categorized["cardio"] ?? [])
                    case "Abs/core": exercises = decodeExercises(from: categorized["abs"] ?? [])
                    default: exercises = []
                }

                await MainActor.run {
                    self.todayExercises = exercises
                    self.currentExerciseIndex = 0
                }
            }
        } catch {
            print("⚠️ Error loading exercises: \(error.localizedDescription)")
        }
    }
    
    func loadSavedInputs(userId: String) async {
        let db = Firestore.firestore()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())

        do {
            let snapshot = try await db
                .collection("WeightProgress")
                .document(userId)
                .collection("entries")
                .getDocuments()

            // Step 1: Use a temporary array
            var entries: [(String, ExerciseInput)] = []

            for document in snapshot.documents {
                let data = document.data()
                let exerciseId = data["exerciseId"] as? String ?? ""
                let weight = data["weight"] as? Double ?? 5.0
                let reps = data["reps"] as? Int ?? 0
                let sets = data["sets"] as? Int ?? 0

                entries.append((exerciseId, ExerciseInput(weight: weight, reps: reps, sets: sets)))
            }

            // Step 2: Build the dictionary after the loop
            let inputs = Dictionary(uniqueKeysWithValues: entries)

            await MainActor.run {
                self.savedInputs = inputs
            }

        } catch {
            print("⚠️ Error loading saved inputs: \(error.localizedDescription)")
        }
    }


    private func decodeExercises(from array: [[String: Any]]) -> [Exercise] {
        array.compactMap { dict in
            guard let id = dict["id"] as? String,
                  let name = dict["name"] as? String,
                  let bodyPart = dict["bodyPart"] as? String,
                  let target = dict["target"] as? String,
                  let equipment = dict["equipment"] as? String,
                  let gifUrl = dict["gifUrl"] as? String else { return nil }
            return Exercise(id: id, name: name, bodyPart: bodyPart, target: target, equipment: equipment, gifUrl: gifUrl)
        }
    }
    

    func nextExercise() {
        if currentExerciseIndex + 1 < todayExercises.count {
            currentExerciseIndex += 1
        } else {
            workoutFinished = true
        }
    }
    
    struct ExerciseInput {
        var weight: Double = 5.0
        var reps: Int = 0
        var sets: Int = 0
    }
}


extension DashboardViewModel {
    func saveWeightEntry(for exercise: Exercise, weight: Double, reps: Int, sets: Int) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ User not logged in")
            return
        }

        let db = Firestore.firestore()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())

        let data: [String: Any] = [
            "exerciseId": exercise.id,
            "exerciseName": exercise.name,
            "weight": weight,
            "reps": reps,
            "sets": sets,
            "timestamp": Timestamp(date: Date())
        ]

        do {
            try await db
                .collection("WeightProgress")
                .document(userId)
                .collection("entries")
                .document("\(exercise.id)_\(today)")
                .setData(data)

            print("✅ Weight entry saved for \(exercise.name) on \(today)")
        } catch {
            print("⚠️ Error saving weight entry: \(error.localizedDescription)")
        }
    }
}
