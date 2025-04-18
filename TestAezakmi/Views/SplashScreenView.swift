import SwiftUI

struct SplashScreenView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            VStack {
                Image(systemName: "chart.bar.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.accentColorToken)
                
                Text("FinPhoto")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.textColorToken)
                    .padding(.top)
            }
            .scaleEffect(1.2)
        }
    }
} 