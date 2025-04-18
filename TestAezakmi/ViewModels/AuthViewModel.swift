import Foundation
import Combine
import Firebase
import FirebaseAuth
import GoogleSignIn
import SwiftUI // Needed for Color

class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var alertMessage: String?
    @Published var showAlert = false
    @Published var isSuccess = false // For alerts

    // Validation states
    @Published var isEmailValid = true
    @Published var isPasswordValid = true
    @Published var doPasswordsMatch = true
    @Published var isEmailUnique = true
    @Published var isCheckingEmail = false
    
    // Combine for email check
    private var emailCheckSubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    // Dependencies
    private weak var appStateManager: AppStateManager?

    var isLoginFormValid: Bool {
        isValidEmail(email) && password.count >= 8
    }
    
    var isRegistrationFormValid: Bool {
        isValidEmail(email) &&
        password.count >= 8 &&
        password == confirmPassword &&
        isEmailUnique &&
        !isCheckingEmail
    }
    
    var isPasswordResetFormValid: Bool {
        isValidEmail(email)
    }

    init(appStateManager: AppStateManager) {
        self.appStateManager = appStateManager
        setupEmailCheckSubscription()
    }
    
    // MARK: - Validation Logic
    
    func validateEmail() {
        isEmailValid = email.isEmpty || isValidEmail(email)
        if isEmailValid && !email.isEmpty {
            // Trigger uniqueness check only if format is valid
            checkEmailUniqueness(email)
        }
    }
    
    func validatePasswordLength() {
        isPasswordValid = password.count >= 8
    }
    
    func validatePasswordMatch() {
        doPasswordsMatch = password == confirmPassword
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    // MARK: - Email Uniqueness Check
    
    private func setupEmailCheckSubscription() {
        emailCheckSubject
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] email in
                self?.performEmailUniquenessCheck(email)
            }
            .store(in: &cancellables)
    }
    
    func checkEmailUniqueness(_ email: String) {
        // Only trigger if email is valid format and not empty
        if isValidEmail(email) && !email.isEmpty {
            isCheckingEmail = true
            isEmailUnique = true // Assume unique until check completes
            emailCheckSubject.send(email) // Send to the debounced pipeline
        } else {
            isCheckingEmail = false
            isEmailUnique = false // Invalid format is not unique
        }
    }
    
    private func performEmailUniquenessCheck(_ email: String) {
        // Actual check happens here after debounce
        Auth.auth().fetchSignInMethods(forEmail: email) { [weak self] methods, error in
            DispatchQueue.main.async {
                self?.isCheckingEmail = false
                if let error = error {
                    print("Error checking email uniqueness: \(error.localizedDescription)")
                    // Handle error case appropriately, maybe assume unique or show error?
                    self?.isEmailUnique = true 
                    return
                }
                self?.isEmailUnique = methods == nil || methods?.isEmpty == true
            }
        }
    }

    // MARK: - Authentication Actions
    
    func signIn() {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                self?.appStateManager?.moveToMain()
            }
        }
    }
    
    func signInWithGoogle() {
        errorMessage = nil
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Firebase Client ID not found."
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Could not find root view controller for Google Sign In."
            return
        }
        
        isLoading = true
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] signInResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.isLoading = false
                    self?.errorMessage = "Google Sign In failed: \(error.localizedDescription)"
                    return
                }
                
                guard let user = signInResult?.user,
                      let idToken = user.idToken?.tokenString else {
                    self?.isLoading = false
                    self?.errorMessage = "Failed to get Google ID token."
                    return
                }
                
                let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                              accessToken: user.accessToken.tokenString)
                
                Auth.auth().signIn(with: credential) { [weak self] _, error in
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = "Firebase sign in with Google credential failed: \(error.localizedDescription)"
                        return
                    }
                    self?.appStateManager?.moveToMain()
                }
            }
        }
    }
    
    func register() {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                result?.user.sendEmailVerification { [weak self] error in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if let error = error {
                            self?.errorMessage = "Account created, but failed to send verification email: \(error.localizedDescription)"
                        } else {
                            // Optionally show a "Verification Sent" message or navigate back
                            self?.alertMessage = "Registration successful! Please check your email (\(self?.email ?? "")) to verify your account."
                            self?.isSuccess = true
                            self?.showAlert = true
                            // Consider navigating back to login after showing alert
                            // self?.appStateManager?.currentState = .auth // Or handle via alert dismissal
                        }
                    }
                }
            }
        }
    }
    
    func resetPassword() {
        isLoading = true
        errorMessage = nil
        alertMessage = nil
        showAlert = false
        
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.alertMessage = "Failed to send password reset email: \(error.localizedDescription)"
                    self?.isSuccess = false
                } else {
                    self?.alertMessage = "Password reset email sent to \(self?.email ?? "")"
                    self?.isSuccess = true
                }
                self?.showAlert = true
            }
        }
    }
    
    // MARK: - Reset State
    // Call this when navigating away or dismissing a view
    func resetAuthFields() {
        email = ""
        password = ""
        confirmPassword = ""
        isLoading = false
        errorMessage = nil
        alertMessage = nil
        showAlert = false
        isSuccess = false
        isEmailValid = true
        isPasswordValid = true
        doPasswordsMatch = true
        isEmailUnique = true
        isCheckingEmail = false
        // Cancel ongoing checks if necessary
        // emailCheckSubject.send(completion: .finished) // Might be too aggressive
    }
} 
