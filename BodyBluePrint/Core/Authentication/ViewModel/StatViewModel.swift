import Foundation
import FirebaseFirestore
import FirebaseAuth

struct WeightEntry: Identifiable {
    let id = UUID()
    let exerciseName: String
    let group: String // e.g., "Push", "Pull"
    let date: Date
    let weight: Double
}

class StatisticsViewModel: ObservableObject {
    @Published var entriesByGroup: [String: [WeightEntry]] = [:]
    @Published var selectedGroup: String = "Push"

    func loadAllExerciseData(userId: String) async {
        let db = Firestore.firestore()
        let snapshot = try? await db
            .collection("WeightProgress")
            .document(userId)
            .collection("entries")
            .getDocuments()

        var grouped: [String: [WeightEntry]] = [:]

        snapshot?.documents.forEach { doc in
            let data = doc.data()
            let name = data["exerciseName"] as? String ?? ""
            let weight = data["weight"] as? Double ?? 0.0
            let timestamp = data["timestamp"] as? Timestamp
            let date = timestamp?.dateValue() ?? Date()

            // 🔍 Categorize exercises
            let group: String
            if name.lowercased().contains("press") || name.lowercased().contains("push") {
                group = "Push"
            } else if name.lowercased().contains("row") || name.lowercased().contains("curl") || name.lowercased().contains("pull") {
                group = "Pull"
            } else if name.lowercased().contains("squat") || name.lowercased().contains("deadlift") || name.lowercased().contains("leg") {
                group = "Leg"
            } else {
                group = "Other"
            }

            let entry = WeightEntry(exerciseName: name, group: group, date: date, weight: weight)
            grouped[group, default: []].append(entry)
        }

        await MainActor.run {
            self.entriesByGroup = grouped
        }
    }
}

