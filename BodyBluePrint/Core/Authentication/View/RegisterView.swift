

import SwiftUI

struct RegisterView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var fullname = ""
    @State private var confirmPassword = ""
    @Environment(\.dismiss) var dismiss
    @State private var showProfileSetup = false
    @EnvironmentObject var viewModel: AuthViewModel
    var body: some View {
        VStack{
            Image("Logo")
                .resizable()
                .scaledToFill()
                .frame(width: 150 , height: 150)
                .padding(.vertical, 32)
            
            VStack(spacing: 24){
                InputView(text: $email,
                          title: "Email Address",
                          placeholder: "name@example.com")
                .autocapitalization(.none)
                
                InputView(text: $fullname,
                          title: "Full Name",
                          placeholder: "Enter your name")
                
                InputView(text: $password,
                          title: "Password",
                          placeholder: "Enter your password",
                          isSecureField: true)
                
                ZStack(alignment: .trailing){
                    InputView(text: $confirmPassword,
                              title: "Confirm Password",
                              placeholder: "Re-type your password",
                              isSecureField: true)
                    
                    if !password.isEmpty && !confirmPassword.isEmpty{
                        if password == confirmPassword{
                            Image(systemName: "checkmark.circle.fill")
                                .imageScale(.large)
                                .fontWeight(.bold)
                                .foregroundColor(Color(.systemGreen))
                        }
                        else{
                            Image(systemName: "xmark.circle.fill")
                                .imageScale(.large)
                                .fontWeight(.bold)
                                .foregroundColor(Color(.systemRed))
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            Button{
                Task{
                    do{
                        try await viewModel.createUser(withEmail: email, password: password,fullname: fullname)
                        showProfileSetup  = true
                    }catch{
                        print("Error creating user: \(error.localizedDescription)")
                    }
                }
            }label: {
                HStack{
                    Text("SIGN UP")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .frame(width: UIScreen.main.bounds.width - 32, height: 48)
            }
            .background(Color.blue)
            .disabled(!FormIsValid)
            .opacity(FormIsValid ? 1.0: 0.5)
            .cornerRadius(10)
            .padding(.top, 30)
            
            Spacer()
            
            Button {
                dismiss()
                
            }label: {
                    HStack(spacing: 2){
                        Text("Already have an account?")
                        Text("Sign In")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 14))
                    
                }
        
        }
        .fullScreenCover(isPresented: $showProfileSetup) {
            UserProfileSetupView()
                .environmentObject(viewModel)
        }
        
    }
}

// Authentiation
extension RegisterView: AuthenticationFormProtocol{
    var FormIsValid: Bool{
        return !email.isEmpty
        && email.contains("@")
        && !password.isEmpty
        && confirmPassword == password
        && password.count > 7
        && !fullname.isEmpty
    }
}


#Preview {
    RegisterView()
        .environmentObject(AuthViewModel())
}
