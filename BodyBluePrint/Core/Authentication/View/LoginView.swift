
import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @EnvironmentObject var viewModel: AuthViewModel
    var body: some View {
        NavigationStack{
            VStack{
                // image
                Image("Logo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150 , height: 150)
                    .padding(.vertical, 32)
                    
                //form fields
                VStack(spacing: 24){
                    InputView(text: $email,
                              title: "Email Address",
                              placeholder: "name@example.com")
                    .autocapitalization(.none)
                    
                    InputView(text: $password,
                              title: "Password",
                              placeholder: "Enter your password",
                              isSecureField: true)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                //login button
                
                Button{
                    Task{
                        try await viewModel.signIn(withEmail: email, password: password)
                    }
                }label: {
                    HStack{
                        Text("SIGN IN")
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
                //sign up button
                
                NavigationLink{
                    RegisterView()
                        .navigationBarBackButtonHidden(true)
                }label: {
                    HStack(spacing: 2){
                        Text("Dont have an account?")
                        Text("Sign Up")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 14))
                }
            }
        }
       
    }
}

// Authentiation
extension LoginView: AuthenticationFormProtocol{
    var FormIsValid: Bool{
        return !email.isEmpty
        && email.contains("@")
        && !password.isEmpty
        && password.count > 7
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
