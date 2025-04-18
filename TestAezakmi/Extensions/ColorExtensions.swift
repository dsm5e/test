import SwiftUI

extension Color {
    static let primaryColorToken = Color("PrimaryColor")
    static let secondaryColorToken = Color("SecondaryColor")
    static let accentColorToken = Color("AccentColor")
    static let backgroundColorToken = Color("BackgroundColor")
    static let textColorToken = Color("TextColor")
}

struct AnimatedGradientBackground: View {
    @State private var start = UnitPoint(x: 0, y: 0)
    @State private var end = UnitPoint(x: 1, y: 1)
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.backgroundColorToken,
                Color.primaryColorToken.opacity(0.5)
            ]),
            startPoint: start,
            endPoint: end
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: true)) {
                self.start = UnitPoint(x: 1, y: 0)
                self.end   = UnitPoint(x: 0, y: 1)
            }
        }
    }
}

struct ParticleBackgroundView: View {
    let particleCount = 30
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.backgroundColorToken
                    .ignoresSafeArea()
                
                ForEach(0..<particleCount, id: \.self) { index in
                    ParticleView(parentSize: geometry.size)
                }
            }
            .frame(width: geometry.size.width,
                   height: geometry.size.height)
        }
    }
}

struct ParticleView: View {
    let parentSize: CGSize
    
    @State private var position: CGPoint = .zero
    @State private var size     = CGFloat.random(in: 5...15)
    @State private var opacity  = Double.random(in: 0.1...0.3)
    @State private var speed    = Double.random(in: 5...15)
    
    var body: some View {
        Circle()
            .fill(Color.primaryColorToken)
            .frame(width: size, height: size)
            .position(position)
            .opacity(opacity)
            .onAppear {
                // start at a random point inside the parent
                position = CGPoint(
                    x: CGFloat.random(in: 0...parentSize.width),
                    y: CGFloat.random(in: 0...parentSize.height)
                )
                animate()
            }
    }
    
    private func animate() {
        let newX = CGFloat.random(in: 0...parentSize.width)
        let newY = CGFloat.random(in: 0...parentSize.height)
        
        withAnimation(.linear(duration: speed).repeatForever(autoreverses: true)) {
            position = CGPoint(x: newX, y: newY)
            opacity  = Double.random(in: 0.1...0.3)
            size     = CGFloat.random(in: 5...15)
        }
    }
}

// Example Preview

struct Backgrounds_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AnimatedGradientBackground()
            ParticleBackgroundView()
        }
        .previewDevice("iPhone SE (2nd generation)")
    }
}
