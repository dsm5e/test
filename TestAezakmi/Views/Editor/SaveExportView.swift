import SwiftUI

struct SaveExportView: View {
    @Environment(\.presentationMode) var presentationMode
    let processedImage: UIImage
    let onSaveToPhotos: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                ParticleBackgroundView()
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Save or Share Your Creation")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textColorToken)
                        .padding(.top)
                    
                    Image(uiImage: processedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(16)
                        .padding()
                        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                    
                    VStack(spacing: 15) {
                        Button(action: onSaveToPhotos) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.headline)
                                Text("Save to Photos")
                                    .font(.headline)
                            }
                        }
                        .primaryButtonStyle()
                        
                        Button(action: onShare) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.headline)
                                Text("Share")
                                    .font(.headline)
                            }
                        }
                        .secondaryButtonStyle()
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitle("Save & Share", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
} 