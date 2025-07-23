

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    var body: some View {
        if let user = viewModel.currentUser{
            List{
                Section{
                    HStack{
                        VStack(alignment: .leading, spacing:4 ){
                            Text(user.fullname)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.top, 4)
                            Text(user.email)
                                .font(.footnote)
                                .foregroundColor(.gray)
                            
                            
                        }
                        
                    }
                    
                }
                Section ("General"){
                    HStack{
                        SettingsSecView(imageName: "gear",
                                        title: "Height",
                                        BackColour: Color(.systemGray))
                        
                        Spacer()
                        Text(user.height!)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    
                    
                }
                Section("Account"){
                    
                    Button {
                        viewModel.signout()
                    }label: {
                        SettingsSecView(
                            imageName: "arrow.left.circle.fill",
                            title: "Sign Out",
                            BackColour: .red)
                    }
                    .foregroundColor(.white)
                    
                }
                
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
