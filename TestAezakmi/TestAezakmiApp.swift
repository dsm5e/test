//
//  TestAezakmiApp.swift
//  TestAezakmi
//
//  Created by dsm 5e on 18.04.2025.
//

import SwiftUI
import Combine
import Firebase
import FirebaseAuth
import GoogleSignIn


enum AppState {
    case splash
    case onboarding
    case auth
    case main
}

@main
struct TestAezakmiApp: App {
    @StateObject private var appStateManager = AppStateManager()
    
    init() {
        FirebaseApp.configure()
        setupAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                switch appStateManager.currentState {
                case .splash:
                    SplashScreenView()
                        .environmentObject(appStateManager)
                        .transition(.opacity)
                case .onboarding:
                    OnboardingView()
                        .environmentObject(appStateManager)
                        .transition(.opacity)
                case .auth:
                    NavigationView {
                        LoginView(appStateManager: appStateManager)
                            .environmentObject(appStateManager)
                    }
                    .transition(.opacity)
                case .main:
                    MainTabView()
                        .environmentObject(appStateManager)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: appStateManager.currentState)
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
    
    private func setupAppearance() {
        UITabBar.appearance().backgroundColor = UIColor(Color.backgroundColorToken)
        UINavigationBar.appearance().backgroundColor = UIColor(Color.backgroundColorToken)
        UITextField.appearance().backgroundColor = UIColor(Color.backgroundColorToken.opacity(0.8))
    }
}

class AppStateManager: ObservableObject {
    @Published var currentState: AppState = .splash
    @Published var isLoggedIn: Bool = false
    @Published var showLoading: Bool = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isLoggedIn = user != nil
            if self?.currentState == .splash {
                Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                    withAnimation {
                        if UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                            self?.currentState = user != nil ? .main : .auth
                        } else {
                            self?.currentState = .onboarding
                        }
                    }
                }
            }
        }
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        withAnimation {
            currentState = isLoggedIn ? .main : .auth
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            withAnimation {
                currentState = .auth
            }
        } catch {
            errorMessage = "Error signing out: \(error.localizedDescription)"
        }
    }
    
    func moveToMain() {
        withAnimation {
            currentState = .main
        }
    }
}
