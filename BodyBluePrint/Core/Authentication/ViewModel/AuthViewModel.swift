

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

protocol AuthenticationFormProtocol{
    var FormIsValid: Bool {get}
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var userSession:FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var userId: String?
       
    
    init(){
        self.userSession = Auth.auth().currentUser
        if let user = Auth.auth().currentUser {
            self.userId = user.uid
        }
    }
    
    
    
    func signIn(withEmail email: String, password: String) async throws {
        do{
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            await fetchUser()
        }catch{
            print("DEBUG failed to login with error\(error.localizedDescription)")
        }
    }
    
    func createUser(withEmail email: String, password: String, fullname: String) async throws {
        do{
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            let user = User(id: result.user.uid, fullname: fullname, email: email)
            let encodedUser = try Firestore.Encoder().encode(user)
            try await Firestore.firestore().collection("users").document(user.id).setData(encodedUser)
            await fetchUser()
            
        }catch{
            print("DEBUG failed to create user with error \(error.localizedDescription)")
        }
    }
    
    func signout (){
        do{
            try Auth.auth().signOut() //signs out user on backend
            self.userSession = nil //allows system to know that there is no current session
            self.currentUser = nil //wipes out user data currenly used
        }catch{
            print("Debug failed to sign out with error \(error.localizedDescription)")
        }
        
    }
        
    func fetchUser () async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let snapshot = try? await Firestore.firestore().collection("users").document(uid).getDocument() else { return }
        self.currentUser = try? snapshot.data(as: User.self)
        
        await handleDailyLoginTracking()
        print ("DEBUG: Current user is \(self.currentUser)")
    }
    
    func saveUserProfile(height: String, weight: String, goal: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        guard let weightInt = Int(weight) else {
            print("DEBUG: Invalid weight value")
            return
        }


        let data: [String: Any] = [
            "height": height,
            "weight": weightInt,
            "goal": goal
        ]

        try await Firestore.firestore().collection("users").document(uid).setData(data, merge: true)
        await fetchUser() // Update local user data
        if let fitnessGoal = FitnessGoal(rawValue: goal) {
                Task {
                    print("🚀 Assigning workouts based on user goal: \(goal)")
                    let exercises = await WorkoutScheduler.shared.fetchExercises(for: fitnessGoal, userId: uid)
                    print("📦 Workouts assigned: \(exercises.count)")
                }
            } else {
                print("⚠️ Invalid fitness goal: \(goal)")
            }
    }
    
    func handleDailyLoginTracking() async {
        guard let uid = userSession?.uid else { return }

        // Make sure user data is fetched
        guard var user = currentUser else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastLogin = user.lastLoginDate.map { calendar.startOfDay(for: $0) }

        if lastLogin != today {
            let newCount = (user.daysLoggedIn ?? 0) + 1
            user.daysLoggedIn = newCount
            user.lastLoginDate = today

            do {
                try await Firestore.firestore().collection("users").document(uid).updateData([
                    "daysLoggedIn": newCount,
                    "lastLoginDate": Timestamp(date: today)
                ])
                await fetchUser()
            } catch {
                print("DEBUG: Failed to update daily login \(error.localizedDescription)")
            }
        }
    }
    
    func incrementWorkoutsCompleted() async {
        guard let uid = userSession?.uid else { return }
        
        // Get the new value
        let newCount = (currentUser?.workoutsCompleted ?? 0) + 1

        do {
            // Update Firestore
            try await Firestore.firestore().collection("users").document(uid).updateData([
                "workoutsCompleted": newCount
            ])
            
            // Refresh local user data
            await fetchUser()
        } catch {
            print("DEBUG: Failed to update workouts count: \(error.localizedDescription)")
        }
    }



    
}
