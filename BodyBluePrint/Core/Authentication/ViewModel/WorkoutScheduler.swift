
import Foundation
import FirebaseFirestore
import Firebase
import FirebaseAuth

// MARK: - Exercise Model
struct Exercise: Codable, Identifiable {
    let id: String
    let name: String
    let bodyPart: String
    let target: String
    let equipment: String
    let gifUrl: String
    var category: String?
}

// MARK: - Goal Enum
enum FitnessGoal: String {
    case weightLoss = "Weight Loss"
    case muscleGain = "Muscle Gain"
    case generalFitness = "General Fitness"
}

// MARK: - Exercise Lists by Goal and Muscle Group
private let goalBasedMuscleGroups: [FitnessGoal: [String]] = [
    .weightLoss: ["cardio", "upper legs", "lower legs", "waist", "chest", "back"],
    .muscleGain: ["chest", "back", "upper legs", "lower legs", "upper arms", "shoulders"],
    .generalFitness: ["waist", "upper legs", "lower legs", "chest", "back", "cardio"]
]

// MARK: - Workout Scheduler
class WorkoutScheduler {
    static let shared = WorkoutScheduler()
    
    private let baseURL = "https://exercisedb.p.rapidapi.com/exercises/bodyPart/"
    private let apiKey = "2097401675mshad9f13074f596afp12d943jsn7b7d20b1d81b"
    
    private init() {}
    
    // Fetch exercises by muscle group (body part)
    func fetchExercisesByBodyPart(_ bodyPart: String) async throws -> [Exercise] {
        guard let url = URL(string: "\(baseURL)\(bodyPart.lowercased().replacingOccurrences(of: " ", with: "%20"))") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-RapidAPI-Key")
        request.setValue("exercisedb.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode([Exercise].self, from: data)
    }
    
    
    
    // Fetch exercises for a given goal, and persist to Firestore if not already saved
    func fetchExercises(for goal: FitnessGoal, userId: String) async -> [Exercise] {
        let db = Firestore.firestore()
        let docRef = db.collection("Workouts").document(userId)
        
        do {
            let snapshot = try await docRef.getDocument()
            if snapshot.exists, let data = try? snapshot.data(as: [String: [Exercise]].self) {
                return data["exercises"] ?? []
            }
        } catch {
            print("⚠️ Firestore read failed: \(error.localizedDescription)")
        }
        
        // Otherwise, fetch new exercises
        guard let muscleGroups = goalBasedMuscleGroups[goal] else { return [] }
        
        var allExercises: [Exercise] = []
        var pushExercises: [Exercise] = []
        var pullExercises: [Exercise] = []
        var legExercises: [Exercise] = []
        var upperBody: [Exercise] = []
        var lowerBody: [Exercise] = []
        var Cardio: [Exercise] = []
        var abs: [Exercise] = []
        
        
        let validEquipments = ["dumbbell", "barbell", "cable"]
        
        for muscleGroup in muscleGroups {
            do {
                let exercises = try await fetchExercisesByBodyPart(muscleGroup)
                let filteredExercises: [Exercise]
                
                if ["cardio", "waist"].contains(muscleGroup.lowercased()) {
                    filteredExercises = exercises
                } else {
                    filteredExercises = exercises.filter { validEquipments.contains($0.equipment.lowercased()) }
                }
                
                var selected: [Exercise] = []
                
                switch muscleGroup.lowercased() {
                case "upper arms":
                    let biceps = filteredExercises.filter { $0.target.lowercased() == "biceps" }.prefix(2)
                    let triceps = filteredExercises.filter { $0.target.lowercased() == "triceps" }.prefix(2)
                    selected = Array(biceps + triceps)
                    pullExercises.append(contentsOf: biceps)
                    pushExercises.append(contentsOf: triceps)
                    
                case "back":
                    let lats = filteredExercises.filter { $0.target.lowercased() == "lats" }.prefix(2)
                    let upperBack = filteredExercises.filter { $0.target.lowercased() == "upper back" }.prefix(2)
                    allExercises.append(contentsOf: lats + upperBack)
                    selected = Array(lats + upperBack)
                    pullExercises.append(contentsOf: selected)
                    upperBody.append(contentsOf: selected)
                    
                case "upper legs", "lower legs":
                    let hamstrings = filteredExercises.filter { $0.target.lowercased() == "hamstrings" }.prefix(2)
                    let quads = filteredExercises.filter { $0.target.lowercased() == "quads" }.prefix(2)
                    let glutes = filteredExercises.filter { $0.target.lowercased() == "glutes" }.prefix(2)
                    allExercises.append(contentsOf: hamstrings + quads + glutes)
                    selected = Array(hamstrings + quads + glutes)
                    legExercises.append(contentsOf: selected)
                    lowerBody.append(contentsOf: selected)
                    
                case "chest", "shoulders":
                    selected = Array(filteredExercises.prefix(2))
                    pushExercises.append(contentsOf: selected)
                    upperBody.append(contentsOf: selected)
                    
                case "cardio":
                    selected = Array(filteredExercises.prefix(2))
                    Cardio.append(contentsOf: selected)
                    
                case "waist":
                    selected = Array(filteredExercises.prefix(2))
                    abs.append(contentsOf: selected)
                    
                    
                default:
                    selected = Array(filteredExercises.prefix(2))
                }
                allExercises.append(contentsOf: selected)
                
                
            } catch {
                print("⚠️ Failed to fetch exercises for '\(muscleGroup)': \(error.localizedDescription)")
            }
        }
        
        let categorizedExercises = [
                "allExercises": allExercises,
                "pushExercises": pushExercises,
                "pullExercises": pullExercises,
                "legExercises": legExercises,
                "upper body": upperBody,
                "lower body": lowerBody,
                "abs": abs,
                "cardio": Cardio
        ]
        
        var categorizedData: [String: [[String: Any]]] = [:]

        for (key, exercises) in categorizedExercises {
            categorizedData[key] = exercises.map { exercise in
                return [
                    "id": exercise.id,
                    "name": exercise.name,
                    "bodyPart": exercise.bodyPart,
                    "target": exercise.target,
                    "equipment": exercise.equipment,
                    "gifUrl": exercise.gifUrl
                ]
            }
        }
        
        
        // Save to Firestore
        let batch = db.batch()

        // Add data to the batch
        batch.setData(["exercises": categorizedData], forDocument: docRef)

        do {
            // Commit the batch write
            try await batch.commit()
            print("✅ Exercises successfully saved to Firestore.")
        } catch {
            print("⚠️ Failed to commit batch: \(error.localizedDescription)")
        }
        
        
        return allExercises
    }
    
    // Clear user's stored exercises
    func clearUserExercises(userId: String) async {
        let db = Firestore.firestore()
        do {
            try await db.collection("userExercises").document(userId).delete()
        } catch {
            print("⚠️ Failed to delete user's exercises: \(error.localizedDescription)")
        }
    }
    
        

}

let daysOfWeek = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

func workoutSchedule(for goal: String) -> [String: String] {
    switch goal {
    case "Muscle Gain":
        return [
            "Monday": "Push Day",
            "Tuesday": "Pull Day",
            "Wednesday": "Leg Day",
            "Thursday": "Rest",
            "Friday": "Push Day",
            "Saturday": "Pull Day",
            "Sunday": "Rest"
        ]
    case "Weight Loss":
        return [
            "Monday": "Upper Body + Cardio",
            "Tuesday": "Cardio",
            "Wednesday": "Lower Body",
            "Thursday": "Rest",
            "Friday": "Upper body + Cardio",
            "Saturday": "Abs/core",
            "Sunday": "Rest"
        ]
    case "General Fitness":
        return [
            "Monday": "Cardio",
            "Tuesday": "Upper body",
            "Wednesday": "Lower Body",
            "Thursday": "Rest",
            "Friday": "Cardio",
            "Saturday": "Upper body",
            "Sunday": "Lower body"
        ]
    default:
        return Dictionary(uniqueKeysWithValues: daysOfWeek.map { ($0, "—") })
    }
}
    

    
    





