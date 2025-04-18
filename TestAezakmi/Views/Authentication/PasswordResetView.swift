import SwiftUI
import Firebase
import FirebaseAuth

struct PasswordResetView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: AuthViewModel
    @FocusState private var emailFocused: Bool
    
    var body: some View {
        ScrollView {
            ZStack {
                AnimatedGradientBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Reset Password")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.textColorToken)
                        .padding(.top, 40)
                    
                    Text("Enter your email address and we'll send you a link to reset your password")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.textColorToken.opacity(0.8))
                        .padding(.horizontal)
                    
                    TextField("Email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .customTextField()
                        .focused($emailFocused)
                        .padding(.top)
                        .onChange(of: viewModel.email) { newValue in
                           // Optional: could add live validation feedback if desired
                           // viewModel.validateEmail() 
                        }
                    
                    Button(action: viewModel.resetPassword) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Send Reset Link")
                        }
                    }
                    .primaryButtonStyle(isDisabled: !viewModel.isPasswordResetFormValid || viewModel.isLoading)
                    .disabled(!viewModel.isPasswordResetFormValid || viewModel.isLoading)
                    .padding(.top)
                    
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.accentColorToken)
                    .padding(.top)
                }
                .padding()
                .frame(maxWidth: 400)
            }
        }
        .withKeyboardDismissButton {
            emailFocused = false
        }
        .alert(viewModel.isSuccess ? "Success" : "Error", isPresented: $viewModel.showAlert) {
            Button("OK") {
                if viewModel.isSuccess {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } message: {
            Text(viewModel.alertMessage ?? "An unknown error occurred.")
        }
        .navigationTitle("Password Reset")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
             viewModel.resetAuthFields()
        }
    }
} 
