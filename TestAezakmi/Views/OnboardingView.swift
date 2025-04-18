import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            VStack {
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        title: "Welcome to FinPhoto",
                        description: "Your all-in-one financial analytics and photo editing application",
                        imageName: "chart.line.uptrend.xyaxis.circle"
                    )
                    .tag(0)
                    
                    OnboardingPage(
                        title: "Photo Editor",
                        description: "Edit photos with professional tools, add text overlays, apply filters, and share your creations",
                        imageName: "photo.fill"
                    )
                    .tag(1)
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                HStack {
                    if currentPage < 1 {
                        Button("Skip") {
                            appStateManager.completeOnboarding()
                        }
                        .foregroundColor(.accentColorToken)
                        .padding()
                        
                        Spacer()
                        
                        Button("Next") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .primaryButtonStyle()
                    } else {
                        Button("Get Started") {
                            appStateManager.completeOnboarding()
                        }
                        .primaryButtonStyle()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
    }
}

struct OnboardingPage: View {
    let title: String
    let description: String
    let imageName: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .foregroundColor(.accentColorToken)
                .padding(.top, 50)
            
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.textColorToken)
                .padding(.horizontal)
            
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.textColorToken.opacity(0.8))
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
        }
    }
} 