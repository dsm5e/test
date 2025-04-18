import SwiftUI
import Firebase
import GoogleSignIn

struct LoginView: View {
    @StateObject private var viewModel: AuthViewModel
    @EnvironmentObject var appStateManager: AppStateManager
    @FocusState private var focusedField: FocusField?
    
    enum FocusField {
        case email, password
    }
    
    init(appStateManager: AppStateManager) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(appStateManager: appStateManager))
    }
    
    var body: some View {
        let registrationView = RegistrationView().environmentObject(viewModel)
        let passwordResetView = PasswordResetView().environmentObject(viewModel)
        
        ScrollView {
            ZStack {
                ParticleBackgroundView()
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "chart.bar.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.accentColorToken)
                        .padding(.top, 50)
                    
                    Text("Welcome Back")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.textColorToken)
                    
                    VStack(spacing: 16) {
                        TextField("Email", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .customTextField()
                            .focused($focusedField, equals: .email)
                            .onChange(of: viewModel.email) { _ in
                                viewModel.validateEmail()
                            }
                        
                        if !viewModel.isEmailValid {
                            Text("Please enter a valid email address")
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                        }
                        
                        SecureField("Password", text: $viewModel.password)
                            .customTextField()
                            .focused($focusedField, equals: .password)
                        
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                        }
                        
                        Button(action: viewModel.signIn) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign In")
                            }
                        }
                        .primaryButtonStyle(isDisabled: !viewModel.isLoginFormValid || viewModel.isLoading)
                        .disabled(!viewModel.isLoginFormValid || viewModel.isLoading)
                        
                        Button(action: viewModel.signInWithGoogle) {
                            HStack {
                                Image(systemName: "g.circle.fill")
                                    .foregroundColor(.accentColorToken)
                                Text("Sign in with Google")
                            }
                        }
                        .secondaryButtonStyle()
                        .disabled(viewModel.isLoading)
                        
                        HStack {
                            NavigationLink("Forgot Password?", destination: passwordResetView)
                                .foregroundColor(.accentColorToken)
                            
                            Spacer()
                            
                            NavigationLink("Register", destination: registrationView)
                                .foregroundColor(.accentColorToken)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .padding()
            }
        }
        .withKeyboardDismissButton {
            focusedField = nil
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .onDisappear {
            viewModel.resetAuthFields()
        }
    }
} 
