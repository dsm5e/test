import SwiftUI

struct TextOverlayEditor: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var text: String
    @State private var selectedFont: UIFont
    @State private var selectedColor: Color
    @State private var fontSize: CGFloat
    @FocusState private var isTextFieldFocused: Bool
    
    let onSave: (String, UIFont, Color) -> Void
    
    private let fontNames = [
        "Helvetica", "Avenir", "Georgia", 
        "Futura", "Arial", "Verdana",
        "Times New Roman", "Didot", "American Typewriter"
    ]
    
    private let colorOptions: [Color] = [
        .accentColorToken, .red, .orange, .yellow, .green, 
        .blue, .purple, .pink, .black, .white
    ]
    
    init(text: String, font: UIFont, color: Color, onSave: @escaping (String, UIFont, Color) -> Void) {
        self._text = State(initialValue: text)
        self._selectedFont = State(initialValue: font)
        self._selectedColor = State(initialValue: color)
        self._fontSize = State(initialValue: font.pointSize)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AnimatedGradientBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    TextField("Enter text", text: $text)
                        .font(Font(selectedFont))
                        .foregroundColor(selectedColor)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.secondaryColorToken.opacity(0.2))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .focused($isTextFieldFocused)
                    
                    HStack {
                        Text("Font:")
                            .foregroundColor(.textColorToken)
                        
                        Picker("Font", selection: $selectedFont) {
                            ForEach(fontNames, id: \.self) { fontName in
                                Text(fontName)
                                    .font(Font(UIFont(name: fontName, size: 16) ?? .systemFont(ofSize: 16)))
                                    .tag(UIFont(name: fontName, size: fontSize) ?? .systemFont(ofSize: fontSize))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .accentColor(.accentColorToken)
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading) {
                        Text("Font Size: \(Int(fontSize))")
                            .foregroundColor(.textColorToken)
                        
                        Slider(value: $fontSize, in: 10...72, step: 1) { _ in
                            updateFont()
                        }
                        .accentColor(.accentColorToken)
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading) {
                        Text("Color:")
                            .foregroundColor(.textColorToken)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                            ForEach(colorOptions, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    Button(action: {
                        onSave(text, selectedFont, selectedColor)
                    }) {
                        Text("Apply")
                    }
                    .primaryButtonStyle(isDisabled: text.isEmpty)
                    .disabled(text.isEmpty)
                    .padding()
                }
            }
            .navigationBarTitle("Edit Text", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    onSave(text, selectedFont, selectedColor)
                }
                .disabled(text.isEmpty)
            )
            .withKeyboardDismissButton {
                isTextFieldFocused = false
            }
        }
    }
    
    private func updateFont() {
        selectedFont = UIFont(name: selectedFont.fontName, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
    }
} 