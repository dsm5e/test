import SwiftUI
import FirebaseAuth
import Firebase

struct SettingsView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            ScrollView {
                ParticleBackgroundView()
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    userProfileSection
                    
                    settingsSection
                }
                .padding()
            }
        }
        .navigationTitle("Settings")
        .alert("Message", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var userProfileSection: some View {
        VStack(spacing: 15) {
            if let user = Auth.auth().currentUser {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.accentColorToken)
                
                Text(user.displayName ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textColorToken)
                
                Text(user.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.textColorToken.opacity(0.8))
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.secondaryColorToken.opacity(0.2))
        .cornerRadius(16)
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Preferences")
                .font(.headline)
                .foregroundColor(.textColorToken)
            
            Toggle(isOn: $isDarkMode) {
                HStack {
                    Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                        .foregroundColor(isDarkMode ? .purple : .orange)
                    
                    Text("Dark Mode")
                        .foregroundColor(.textColorToken)
                }
            }
            .padding()
            .background(Color.secondaryColorToken.opacity(0.1))
            .cornerRadius(10)
            
            // Add more settings options as needed
            
            Button(action: {
                signOut()
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                    
                    Text("Sign Out")
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundColor(.textColorToken.opacity(0.5))
                }
            }
            .padding()
            .background(Color.secondaryColorToken.opacity(0.1))
            .cornerRadius(10)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondaryColorToken.opacity(0.2))
        .cornerRadius(16)
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("About")
                .font(.headline)
                .foregroundColor(.textColorToken)
            
            HStack {
                Text("App Version")
                    .foregroundColor(.textColorToken)
                
                Spacer()
                
                Text("1.0.0")
                    .foregroundColor(.textColorToken.opacity(0.8))
            }
            .padding()
            .background(Color.secondaryColorToken.opacity(0.1))
            .cornerRadius(10)
            
            HStack {
                Text("Terms of Service")
                    .foregroundColor(.textColorToken)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundColor(.textColorToken.opacity(0.5))
            }
            .padding()
            .background(Color.secondaryColorToken.opacity(0.1))
            .cornerRadius(10)
            .onTapGesture {
                alertMessage = "This would open the Terms of Service"
                showingAlert = true
            }
            
            HStack {
                Text("Privacy Policy")
                    .foregroundColor(.textColorToken)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundColor(.textColorToken.opacity(0.5))
            }
            .padding()
            .background(Color.secondaryColorToken.opacity(0.1))
            .cornerRadius(10)
            .onTapGesture {
                alertMessage = "This would open the Privacy Policy"
                showingAlert = true
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondaryColorToken.opacity(0.2))
        .cornerRadius(16)
    }
    
    private func signOut() {
        appStateManager.signOut()
    }
}
