import SwiftUI
import PencilKit

struct PhotoEditorView: View {
    @ObservedObject var viewModel: EditorViewModel
    @State private var showingTextEditor = false
    @State private var showingSaveOptions = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    @State private var dragOffset = CGSize.zero
    @State private var previousDragOffset = CGSize.zero
    
    @State private var currentScale: CGFloat = 1.0
    @State private var previousScale: CGFloat = 1.0
    
    @State private var currentRotation: Angle = .zero
    @State private var previousRotation: Angle = .zero
    
    @State private var isDragging = false
    @State private var imageToShare: UIImage?
    @State private var showingShareSheet = false
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {            
            VStack {
                ZStack {
                    // Image with transformations
                    if let image = viewModel.previewImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(currentScale * viewModel.scale)
                            .rotationEffect(currentRotation + viewModel.rotation)
                            .offset(dragOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        dragOffset = CGSize(
                                            width: previousDragOffset.width + value.translation.width,
                                            height: previousDragOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { value in
                                        previousDragOffset = dragOffset
                                    }
                            )
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        currentScale = value
                                    }
                                    .onEnded { value in
                                        viewModel.scale *= value
                                        currentScale = 1.0
                                    }
                            )
                            .gesture(
                                RotationGesture()
                                    .onChanged { value in
                                        currentRotation = value
                                    }
                                    .onEnded { value in
                                        viewModel.rotation += value
                                        currentRotation = .zero
                                    }
                            )
                    }
                    
                    // Drawing overlay
                    if viewModel.isDrawing {
                        DrawingCanvasView(
                            paths: $viewModel.drawingPaths,
                            currentPath: $viewModel.currentPath,
                            isDrawing: $viewModel.isDrawing
                        )
                        .scaleEffect(currentScale * viewModel.scale)
                        .rotationEffect(currentRotation + viewModel.rotation)
                        .offset(dragOffset)
                    }
                    
                    // Text overlays
                    ForEach(viewModel.textOverlays) { overlay in
                        TextOverlayView(
                            overlay: overlay,
                            isSelected: viewModel.selectedTextOverlay?.id == overlay.id,
                            onSelected: { 
                                viewModel.selectedTextOverlay = overlay 
                            },
                            onMoved: { newPosition in
                                var updatedOverlay = overlay
                                updatedOverlay.position = newPosition
                                viewModel.updateTextOverlay(updatedOverlay)
                            },
                            onEdit: {
                                viewModel.selectedTextOverlay = overlay
                                showingTextEditor = true
                            },
                            onDelete: {
                                viewModel.removeTextOverlay(overlay)
                            },
                            viewModel: viewModel
                        )
                        .scaleEffect(currentScale * viewModel.scale)
                        .rotationEffect(currentRotation + viewModel.rotation)
                        .offset(dragOffset)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: 400)
                .padding()
                .background(Color.black.opacity(0.1))
                .cornerRadius(16)
                
                // Filter strip
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(PhotoFilter.allCases, id: \.self) { filter in
                            FilterThumbnail(
                                filter: filter,
                                isSelected: viewModel.selectedFilter == filter,
                                image: viewModel.selectedImage,
                                onSelected: {
                                    viewModel.applyFilter(filter)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                // Toolbar
                HStack(spacing: 25) {
                    // Draw button
                    Button(action: {
                        viewModel.isDrawing.toggle()
                        if !viewModel.isDrawing {
                            viewModel.endDrawing()
                        }
                    }) {
                        Image(systemName: "pencil.tip")
                            .font(.title2)
                            .foregroundColor(viewModel.isDrawing ? .accentColorToken : .textColorToken)
                    }
                    
                    // Text button
                    Button(action: {
                        showingTextEditor = true
                    }) {
                        Image(systemName: "textformat")
                            .font(.title2)
                            .foregroundColor(.textColorToken)
                    }
                    
                    // Undo button
                    Button(action: {
                        viewModel.undo()
                    }) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.title2)
                            .foregroundColor(.textColorToken)
                    }
                    .disabled(viewModel.historyIndex <= 0)
                    
                    // Redo button
                    Button(action: {
                        viewModel.redo()
                    }) {
                        Image(systemName: "arrow.uturn.forward")
                            .font(.title2)
                            .foregroundColor(.textColorToken)
                    }
                    .disabled(viewModel.historyIndex >= viewModel.history.count - 1)
                    
                    // Done button
                    Button(action: {
                        showingSaveOptions = true
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accentColorToken)
                    }
                }
                .padding()
                .background(Color.secondaryColorToken.opacity(0.2))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationTitle("Photo Editor")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingTextEditor) {
            TextOverlayEditor(
                text: viewModel.selectedTextOverlay?.text ?? "",
                font: viewModel.selectedTextOverlay?.font ?? UIFont.systemFont(ofSize: 24),
                color: viewModel.selectedTextOverlay?.color ?? .accentColorToken,
                onSave: { text, font, color in
                    if let selectedOverlay = viewModel.selectedTextOverlay {
                        var updatedOverlay = selectedOverlay
                        updatedOverlay.text = text
                        updatedOverlay.font = font
                        updatedOverlay.color = color
                        viewModel.updateTextOverlay(updatedOverlay)
                    } else {
                        viewModel.addTextOverlay(text, font: font, color: color)
                    }
                    showingTextEditor = false
                }
            )
        }
        .sheet(isPresented: $showingSaveOptions) {
            SaveExportView(
                processedImage: viewModel.saveEditedImage() ?? UIImage(),
                onSaveToPhotos: {
                    viewModel.saveToPhotoLibrary { success in
                        isSuccess = success
                        alertMessage = success ? "Image saved successfully" : "Failed to save image"
                        showingAlert = true
                        if success {
                            showingSaveOptions = false
                            viewModel.resetState()
                            dismiss()
                        }
                    }
                },
                onShare: {
                    if let image = viewModel.shareImage() {
                        imageToShare = image
                        showingShareSheet = true
                        showingSaveOptions = false
                    } else {
                        isSuccess = false
                        alertMessage = "Failed to prepare image for sharing"
                        showingAlert = true
                    }
                }
            )
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = imageToShare {
                ActivityViewController(activityItems: [image])
            }
        }
        .alert(isSuccess ? "Success" : "Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}

struct DrawingCanvasView: View {
    @Binding var paths: [DrawingPath]
    @Binding var currentPath: DrawingPath
    @Binding var isDrawing: Bool
    
    var body: some View {
        ZStack {
            ForEach(paths) { path in
                DrawingPathView(path: path)
            }
            DrawingPathView(path: currentPath)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let point = value.location
                    currentPath.points.append(point)
                }
                .onEnded { _ in
                    if !currentPath.points.isEmpty {
                        paths.append(currentPath)
                    }
                    currentPath = DrawingPath(
                        points: [],
                        color: currentPath.color,
                        lineWidth: currentPath.lineWidth
                    )
                }
        )
    }
}

struct DrawingPathView: View {
    let path: DrawingPath
    
    var body: some View {
        Path { path in
            guard let firstPoint = self.path.points.first else { return }
            
            path.move(to: firstPoint)
            for point in self.path.points.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(path.color, style: StrokeStyle(lineWidth: path.lineWidth, lineCap: .round, lineJoin: .round))
    }
}

struct TextOverlayView: View {
    let overlay: TextOverlay
    let isSelected: Bool
    let onSelected: () -> Void
    let onMoved: (CGPoint) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let viewModel: EditorViewModel
    
    @State private var position: CGPoint
    @State private var isDragging = false
    @GestureState private var dragOffset = CGSize.zero
    
    init(overlay: TextOverlay, isSelected: Bool, onSelected: @escaping () -> Void, onMoved: @escaping (CGPoint) -> Void, onEdit: @escaping () -> Void, onDelete: @escaping () -> Void, viewModel: EditorViewModel) {
        self.overlay = overlay
        self.isSelected = isSelected
        self.onSelected = onSelected
        self.onMoved = onMoved
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.viewModel = viewModel
        self._position = State(initialValue: overlay.position)
    }
    
    var body: some View {
        Text(overlay.text)
            .font(Font(overlay.font))
            .foregroundColor(overlay.color)
            .position(x: position.x + dragOffset.width, y: position.y + dragOffset.height)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onChanged { _ in
                        // Only update the dragging state, don't perform calculations yet
                        isDragging = true
                    }
                    .onEnded { value in
                        // Apply the final position only on gesture end
                        isDragging = false
                        position = CGPoint(
                            x: position.x + value.translation.width,
                            y: position.y + value.translation.height
                        )
                        onMoved(position)
                        viewModel.addHistoryStep()
                    }
            )
            .onTapGesture(count: 2) {
                onEdit()
            }
            .overlay(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColorToken, lineWidth: 2)
                            .padding(-5)
                        
                        HStack {
                            Button(action: onEdit) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.white)
                                    .padding(5)
                                    .background(Color.accentColorToken)
                                    .clipShape(Circle())
                            }
                            
                            Button(action: onDelete) {
                                Image(systemName: "trash")
                                    .foregroundColor(.white)
                                    .padding(5)
                                    .background(Color.red)
                                    .clipShape(Circle())
                            }
                        }
                        .offset(y: -30)
                    }
                }
            )
    }
}

struct FilterThumbnail: View {
    let filter: PhotoFilter
    let isSelected: Bool
    let image: UIImage?
    let onSelected: () -> Void
    
    var body: some View {
        VStack {
            if let image = image {
                ZStack {
                    Image(uiImage: applyFilter(to: image, filter: filter))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipped()
                        .cornerRadius(8)
                        .overlay(
                            isSelected ? RoundedRectangle(cornerRadius: 8).stroke(Color.accentColorToken, lineWidth: 3) : nil
                        )
                }
            } else {
                Color.gray
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .overlay(
                        isSelected ? RoundedRectangle(cornerRadius: 8).stroke(Color.accentColorToken, lineWidth: 3) : nil
                    )
            }
            Text(filterName(filter))
                .font(.caption)
                .foregroundColor(.textColorToken)
        }
        .onTapGesture {
            onSelected()
        }
    }
    
    private func filterName(_ filter: PhotoFilter) -> String {
        switch filter {
        case .none: return "Original"
        case .mono: return "Mono"
        case .sepia: return "Sepia"
        case .vibrant: return "Vibrant"
        case .noir: return "Noir"
        case .vintage: return "Vintage"
        case .invert: return "Invert"
        case .blur: return "Blur"
        case .fuji: return "Fuji"
        case .kodak: return "Kodak"
        case .vsco: return "VSCO"
        case .portra: return "Portra"
        case .ektar: return "Ektar"
        case .polaroid: return "Polaroid"
        }
    }
    
    private func applyFilter(to image: UIImage, filter: PhotoFilter) -> UIImage {
        if filter == .none {
            return image
        }
        guard let ciImage = CIImage(image: image) else { return image }
        let context = CIContext()
        let filteredImage: CIImage
        switch filter {
        case .none:
            return image
        case .mono:
            let filter = CIFilter.photoEffectMono()
            filter.inputImage = ciImage
            guard let output = filter.outputImage else { return image }
            filteredImage = output
        case .sepia:
            let filter = CIFilter.sepiaTone()
            filter.inputImage = ciImage
            filter.intensity = 0.7
            guard let output = filter.outputImage else { return image }
            filteredImage = output
        case .vibrant:
            let filter = CIFilter.vibrance()
            filter.inputImage = ciImage
            filter.amount = 1.5
            guard let output = filter.outputImage else { return image }
            filteredImage = output
        case .noir:
            let filter = CIFilter.photoEffectNoir()
            filter.inputImage = ciImage
            guard let output = filter.outputImage else { return image }
            filteredImage = output
        case .vintage:
            let filter = CIFilter.sepiaTone()
            filter.inputImage = ciImage
            filter.intensity = 0.5
            guard let output = filter.outputImage else { return image }
            let vignetteFilter = CIFilter.vignette()
            vignetteFilter.inputImage = output
            vignetteFilter.intensity = 1.0
            vignetteFilter.radius = 1.5
            guard let finalOutput = vignetteFilter.outputImage else { return image }
            filteredImage = finalOutput
        case .invert:
            let filter = CIFilter.colorInvert()
            filter.inputImage = ciImage
            guard let output = filter.outputImage else { return image }
            filteredImage = output
        case .blur:
            let filter = CIFilter.gaussianBlur()
            filter.inputImage = ciImage
            filter.radius = 5.0
            guard let output = filter.outputImage else { return image }
            filteredImage = output
        case .fuji:
            let temp = CIFilter.temperatureAndTint()
            temp.inputImage = ciImage
            temp.neutral = CIVector(x: 6500, y: 0)
            temp.targetNeutral = CIVector(x: 5000, y: 0)
            guard let tempOut = temp.outputImage else { return image }
            let curve = CIFilter.toneCurve()
            curve.inputImage = tempOut
            curve.point0 = CGPoint(x: 0, y: 0)
            curve.point1 = CGPoint(x: 0.25, y: 0.18)
            curve.point2 = CGPoint(x: 0.5, y: 0.5)
            curve.point3 = CGPoint(x: 0.75, y: 0.82)
            curve.point4 = CGPoint(x: 1, y: 1)
            guard let curveOut = curve.outputImage else { return image }
            filteredImage = curveOut
        case .kodak:
            let fade = CIFilter.toneCurve()
            fade.inputImage = ciImage
            fade.point0 = CGPoint(x: 0, y: 0.1)
            fade.point1 = CGPoint(x: 0.25, y: 0.3)
            fade.point2 = CGPoint(x: 0.5, y: 0.6)
            fade.point3 = CGPoint(x: 0.75, y: 0.85)
            fade.point4 = CGPoint(x: 1, y: 1)
            guard let fadeOut = fade.outputImage else { return image }
            let temp = CIFilter.temperatureAndTint()
            temp.inputImage = fadeOut
            temp.neutral = CIVector(x: 6500, y: 0)
            temp.targetNeutral = CIVector(x: 7500, y: 0)
            guard let tempOut = temp.outputImage else { return image }
            filteredImage = tempOut
        case .vsco:
            let clarity = CIFilter.unsharpMask()
            clarity.inputImage = ciImage
            clarity.intensity = 1.0
            clarity.radius = 2.0
            guard let clarityOut = clarity.outputImage else { return image }
            let temp = CIFilter.temperatureAndTint()
            temp.inputImage = clarityOut
            temp.neutral = CIVector(x: 6500, y: 0)
            temp.targetNeutral = CIVector(x: 6000, y: 0)
            guard let tempOut = temp.outputImage else { return image }
            let fade = CIFilter.toneCurve()
            fade.inputImage = tempOut
            fade.point0 = CGPoint(x: 0, y: 0.08)
            fade.point1 = CGPoint(x: 0.25, y: 0.28)
            fade.point2 = CGPoint(x: 0.5, y: 0.55)
            fade.point3 = CGPoint(x: 0.75, y: 0.85)
            fade.point4 = CGPoint(x: 1, y: 1)
            guard let fadeOut = fade.outputImage else { return image }
            filteredImage = fadeOut
        case .portra:
            let temp = CIFilter.temperatureAndTint()
            temp.inputImage = ciImage
            temp.neutral = CIVector(x: 6500, y: 0)
            temp.targetNeutral = CIVector(x: 7000, y: 0)
            guard let tempOut = temp.outputImage else { return image }
            let curve = CIFilter.toneCurve()
            curve.inputImage = tempOut
            curve.point0 = CGPoint(x: 0, y: 0.05)
            curve.point1 = CGPoint(x: 0.25, y: 0.22)
            curve.point2 = CGPoint(x: 0.5, y: 0.55)
            curve.point3 = CGPoint(x: 0.75, y: 0.85)
            curve.point4 = CGPoint(x: 1, y: 1)
            guard let curveOut = curve.outputImage else { return image }
            let pink = CIFilter.colorMonochrome()
            pink.inputImage = curveOut
            pink.color = CIColor(red: 1, green: 0.9, blue: 0.95)
            pink.intensity = 0.08
            guard let pinkOut = pink.outputImage else { return image }
            filteredImage = pinkOut
        case .ektar:
            let sat = CIFilter.colorControls()
            sat.inputImage = ciImage
            sat.saturation = 1.5
            sat.brightness = 0.05
            sat.contrast = 1.2
            guard let satOut = sat.outputImage else { return image }
            let temp = CIFilter.temperatureAndTint()
            temp.inputImage = satOut
            temp.neutral = CIVector(x: 6500, y: 0)
            temp.targetNeutral = CIVector(x: 6000, y: 0)
            guard let tempOut = temp.outputImage else { return image }
            filteredImage = tempOut
        case .polaroid:
            let fade = CIFilter.toneCurve()
            fade.inputImage = ciImage
            fade.point0 = CGPoint(x: 0, y: 0.12)
            fade.point1 = CGPoint(x: 0.25, y: 0.32)
            fade.point2 = CGPoint(x: 0.5, y: 0.6)
            fade.point3 = CGPoint(x: 0.75, y: 0.85)
            fade.point4 = CGPoint(x: 1, y: 1)
            guard let fadeOut = fade.outputImage else { return image }
            let blue = CIFilter.colorMonochrome()
            blue.inputImage = fadeOut
            blue.color = CIColor(red: 0.8, green: 0.9, blue: 1)
            blue.intensity = 0.12
            guard let blueOut = blue.outputImage else { return image }
            let vignette = CIFilter.vignette()
            vignette.inputImage = blueOut
            vignette.intensity = 0.7
            vignette.radius = 2.0
            guard let vignetteOut = vignette.outputImage else { return image }
            filteredImage = vignetteOut
        }
        guard let cgImage = context.createCGImage(filteredImage, from: filteredImage.extent) else { return image }
        return UIImage(cgImage: cgImage)
    }
}

extension PhotoFilter: CaseIterable {
    static var allCases: [PhotoFilter] {
        [.none, .mono, .sepia, .vibrant, .noir, .vintage, .invert, .blur, .fuji, .kodak, .vsco, .portra, .ektar, .polaroid]
    }
}

enum PhotoFilter {
    case none
    case mono
    case sepia
    case vibrant
    case noir
    case vintage
    case invert
    case blur
    case fuji
    case kodak
    case vsco
    case portra
    case ektar
    case polaroid
} 
