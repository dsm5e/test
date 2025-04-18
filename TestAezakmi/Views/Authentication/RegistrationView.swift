import SwiftUI
import Firebase
import FirebaseAuth
import Combine

struct RegistrationView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: AuthViewModel
    
    @FocusState private var focusedField: FocusField?
    
    enum FocusField {
        case email, password, confirmPassword
    }
    
    var body: some View {
        ScrollView {
            ZStack {
                ParticleBackgroundView()
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.textColorToken)
                        .padding(.top, 30)
                    
                    VStack(spacing: 16) {
                        HStack {
                            TextField("Email", text: $viewModel.email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .customTextField()
                                .focused($focusedField, equals: .email)
                                .onChange(of: viewModel.email) { newValue in
                                    viewModel.checkEmailUniqueness(newValue)
                                }
                            
                            if viewModel.isCheckingEmail {
                                ProgressView()
                                    .padding(.trailing)
                            } else if !viewModel.email.isEmpty {
                                Image(systemName: viewModel.isEmailUnique && viewModel.isEmailValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(viewModel.isEmailUnique && viewModel.isEmailValid ? .green : .red)
                                    .padding(.trailing)
                            }
                        }
                        
                        if !viewModel.isEmailValid {
                            Text("Please enter a valid email address")
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                        } else if !viewModel.isEmailUnique {
                            Text("This email is already in use")
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                        }
                        
                        SecureField("Password (min 8 characters)", text: $viewModel.password)
                            .customTextField()
                            .focused($focusedField, equals: .password)
                            .textContentType(.newPassword)
                            .onChange(of: viewModel.password) { _ in
                                viewModel.validatePasswordLength()
                                viewModel.validatePasswordMatch()
                            }
                        
                        if !viewModel.password.isEmpty && !viewModel.isPasswordValid {
                            Text("Password must be at least 8 characters")
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                        }
                        
                        SecureField("Confirm Password", text: $viewModel.confirmPassword)
                            .customTextField()
                            .focused($focusedField, equals: .confirmPassword)
                            .textContentType(.newPassword)
                            .onChange(of: viewModel.confirmPassword) { _ in
                                viewModel.validatePasswordMatch()
                            }
                        
                        if !viewModel.password.isEmpty && !viewModel.confirmPassword.isEmpty && !viewModel.doPasswordsMatch {
                            Text("Passwords don't match")
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                        }
                        
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                        }
                        
                        Button(action: viewModel.register) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Register")
                            }
                        }
                        .primaryButtonStyle(isDisabled: !viewModel.isRegistrationFormValid || viewModel.isLoading)
                        .disabled(!viewModel.isRegistrationFormValid || viewModel.isLoading)
                        
                        Button("Already have an account? Sign In") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.accentColorToken)
                        .padding(.top)
                    }
                    .padding(.vertical)
                }
                .padding()
            }
        }
        .withKeyboardDismissButton {
            focusedField = nil
        }
        .onAppear {
            viewModel.resetAuthFields()
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
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
    }
} 
