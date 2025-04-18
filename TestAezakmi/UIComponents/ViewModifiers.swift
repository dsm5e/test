import SwiftUI

struct PrimaryButtonStyle: ViewModifier {
    var isDisabled: Bool = false
    
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(isDisabled ? Color.gray : Color.accentColorToken)
            .cornerRadius(12)
            .padding(.horizontal)
            .opacity(isDisabled ? 0.6 : 1.0)
    }
}

struct SecondaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(Color.accentColorToken)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.secondaryColorToken)
            .cornerRadius(12)
            .padding(.horizontal)
    }
}

struct TextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.backgroundColorToken.opacity(0.8))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primaryColorToken.opacity(0.5), lineWidth: 1)
            )
            .padding(.horizontal)
    }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.secondaryColorToken.opacity(0.2))
            .cornerRadius(12)
            .shadow(color: Color.primaryColorToken.opacity(0.1), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
    }
}

struct KeyboardToolbar: ToolbarContent {
    let dismissAction: () -> Void
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Done") {
                dismissAction()
            }
            .foregroundColor(Color.accentColorToken)
        }
    }
}

extension View {
    func primaryButtonStyle(isDisabled: Bool = false) -> some View {
        self.modifier(PrimaryButtonStyle(isDisabled: isDisabled))
    }
    
    func secondaryButtonStyle() -> some View {
        self.modifier(SecondaryButtonStyle())
    }
    
    func customTextField() -> some View {
        self.modifier(TextFieldModifier())
    }
    
    func cardStyle() -> some View {
        self.modifier(CardModifier())
    }
    
    func withKeyboardDismissButton(_ dismissAction: @escaping () -> Void) -> some View {
        self.toolbar {
            KeyboardToolbar(dismissAction: dismissAction)
        }
    }
} 