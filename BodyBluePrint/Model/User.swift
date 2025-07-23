

import Foundation

struct User: Identifiable, Codable{
    let id: String
    var fullname: String
    var email: String
    var height: String?
    var weight: Int?
    var goal: String?
    var workoutsCompleted: Int?
    var daysLoggedIn: Int?
    var lastLoginDate: Date?
    
    var fitnessGoalEnum: FitnessGoal? {
        guard let goal = goal else { return nil }
        return FitnessGoal(rawValue: goal)
    }
}

extension User {
    static var Mock_user = User(id: NSUUID().uuidString, fullname: "Micheal jordan", email: "test@gmail.com")
}
