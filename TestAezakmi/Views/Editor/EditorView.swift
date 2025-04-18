import SwiftUI
import PhotosUI

struct EditorView: View {
    @StateObject private var viewModel = EditorViewModel()
    
    var body: some View {
        ZStack {
            ParticleBackgroundView()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    if viewModel.selectedImage != nil {
                        NavigationLink(
                            destination: PhotoEditorView(viewModel: viewModel)
                        ) {
                            editPreviewCard
                        }
                    } else {
                        importToolbar
                        
                        recentEditsGrid
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Photo Editor")
        .sheet(isPresented: $viewModel.showingCamera) {
            CameraView(onImageCaptured: { image in
                let resized = EditorViewModel.resizeImage(image, maxDimension: 512)
                viewModel.selectedImage = resized
                viewModel.showingCamera = false
            }).ignoresSafeArea()
        }
        .onAppear {
            viewModel.loadRecentEdits()
        }
    }
    
    private var importToolbar: some View {
        VStack(spacing: 20) {
            Text("Import Image")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textColorToken)
            
            HStack(spacing: 30) {
                Button(action: {
                    viewModel.showingCamera = true
                }) {
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.accentColorToken)
                        
                        Text("Camera")
                            .foregroundColor(.textColorToken)
                    }
                    .frame(width: 120, height: 120)
                    .background(Color.secondaryColorToken.opacity(0.2))
                    .cornerRadius(16)
                }
                
                PhotosPicker(
                    selection: $viewModel.imageSelection,
                    matching: .images
                ) {
                    VStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 36))
                            .foregroundColor(.accentColorToken)
                        Text("Gallery")
                            .foregroundColor(.textColorToken)
                    }
                    .frame(width: 120, height: 120)
                    .background(Color.secondaryColorToken.opacity(0.2))
                    .cornerRadius(16)
                }
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color.secondaryColorToken.opacity(0.1))
        .cornerRadius(20)
    }
    
    private var editPreviewCard: some View {
        VStack(spacing: 15) {
            Text("Continue Editing")
                .font(.headline)
                .foregroundColor(.textColorToken)
            
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(12)
            }
            
            Text("Tap to continue")
                .font(.subheadline)
                .foregroundColor(.accentColorToken)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.secondaryColorToken.opacity(0.2))
        .cornerRadius(16)
    }
    
    private var recentEditsGrid: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recent Edits")
                .font(.headline)
                .foregroundColor(.textColorToken)
            
            if viewModel.recentEdits.isEmpty {
                Text("No recent edits")
                    .foregroundColor(.textColorToken.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(viewModel.recentEdits) { edit in
                        Button(action: {
                            viewModel.loadEdit(edit)
                        }) {
                            VStack {
                                Image(uiImage: edit.thumbnail)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 150)
                                    .clipped()
                                    .cornerRadius(12)
                                
                                Text(edit.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.textColorToken.opacity(0.8))
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.secondaryColorToken.opacity(0.1))
        .cornerRadius(16)
    }
}

struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCaptured: onImageCaptured)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImageCaptured: (UIImage) -> Void
        
        init(onImageCaptured: @escaping (UIImage) -> Void) {
            self.onImageCaptured = onImageCaptured
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImageCaptured(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
