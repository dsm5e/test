import Foundation
import SwiftUI
import PhotosUI
import CoreImage
import CoreImage.CIFilterBuiltins

class EditorViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var processedImage: UIImage?
    @Published var previewImage: UIImage?
    @Published var imageSelection: PhotosPickerItem? {
        didSet {
            if let imageSelection {
                loadTransferable(from: imageSelection)
            }
        }
    }
    @Published var showingImagePicker = false
    @Published var showingCamera = false
    @Published var recentEdits: [RecentEdit] = []
    
    // Drawing tool state
    @Published var isDrawing = false
    @Published var drawingPaths: [DrawingPath] = []
    @Published var currentPath = DrawingPath(points: [], color: .accentColorToken, lineWidth: 3.0)
    
    // Text overlay state
    @Published var textOverlays: [TextOverlay] = []
    @Published var selectedTextOverlay: TextOverlay?
    
    // Filter state
    @Published var selectedFilter: PhotoFilter = .none
    private let context = CIContext()
    
    // Transform state
    @Published var scale: CGFloat = 1.0
    @Published var rotation: Angle = .zero
    @Published var position: CGSize = .zero
    
    // History
    @Published var history: [EditHistory] = []
    @Published var historyIndex = -1
    
    func loadTransferable(from imageSelection: PhotosPickerItem) {
        imageSelection.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                guard let imageData = try? result.get() else {
                    return
                }
                
                if let uiImage = UIImage(data: imageData) {
                    let resized = Self.resizeImage(uiImage, maxDimension: 256)
                    let preview = Self.resizeImage(uiImage, maxDimension: 256)
                    self.selectedImage = resized
                    self.processedImage = resized
                    self.previewImage = preview
                    self.addHistoryStep()
                }
            }
        }
    }
    
    static func resizeImage(_ image: UIImage, maxDimension: CGFloat = 256) -> UIImage {
        let size = image.size
        let aspectRatio = size.width / size.height
        var newSize: CGSize
        if aspectRatio > 1 {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    func applyFilter(_ filter: PhotoFilter) {
        guard let inputImage = previewImage else { return }
        selectedFilter = filter
        if filter == .none {
            DispatchQueue.main.async {
                self.processedImage = self.selectedImage
                self.previewImage = self.selectedImage
                self.addHistoryStep()
            }
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let start = Date()
            print("applyFilter: start for \(filter)")
            guard let ciImage = CIImage(image: inputImage) else {
                print("applyFilter: failed to create CIImage")
                return
            }
            print("applyFilter: CIImage created in \(Date().timeIntervalSince(start))s")
            let filterStart = Date()
            let filteredImage: CIImage
            switch filter {
            case .none:
                DispatchQueue.main.async {
                    self.processedImage = self.selectedImage
                    self.previewImage = self.selectedImage
                    self.addHistoryStep()
                }
                return
            case .mono:
                let filter = CIFilter.photoEffectMono()
                filter.inputImage = ciImage
                guard let output = filter.outputImage else { return }
                filteredImage = output
            case .sepia:
                let filter = CIFilter.sepiaTone()
                filter.inputImage = ciImage
                filter.intensity = 0.7
                guard let output = filter.outputImage else { return }
                filteredImage = output
            case .vibrant:
                let filter = CIFilter.vibrance()
                filter.inputImage = ciImage
                filter.amount = 1.5
                guard let output = filter.outputImage else { return }
                filteredImage = output
            case .noir:
                let filter = CIFilter.photoEffectNoir()
                filter.inputImage = ciImage
                guard let output = filter.outputImage else { return }
                filteredImage = output
            case .vintage:
                let filter = CIFilter.sepiaTone()
                filter.inputImage = ciImage
                filter.intensity = 0.5
                guard let output = filter.outputImage else { return }
                let vignetteFilter = CIFilter.vignette()
                vignetteFilter.inputImage = output
                vignetteFilter.intensity = 1.0
                vignetteFilter.radius = 1.5
                guard let finalOutput = vignetteFilter.outputImage else { return }
                filteredImage = finalOutput
            case .invert:
                let filter = CIFilter.colorInvert()
                filter.inputImage = ciImage
                guard let output = filter.outputImage else { return }
                filteredImage = output
            case .blur:
                let filter = CIFilter.gaussianBlur()
                filter.inputImage = ciImage
                filter.radius = 5.0
                guard let output = filter.outputImage else { return }
                filteredImage = output
            case .fuji:
                let temp = CIFilter.temperatureAndTint()
                temp.inputImage = ciImage
                temp.neutral = CIVector(x: 6500, y: 0)
                temp.targetNeutral = CIVector(x: 5000, y: 0)
                guard let tempOut = temp.outputImage else { return }
                let curve = CIFilter.toneCurve()
                curve.inputImage = tempOut
                curve.point0 = CGPoint(x: 0, y: 0)
                curve.point1 = CGPoint(x: 0.25, y: 0.18)
                curve.point2 = CGPoint(x: 0.5, y: 0.5)
                curve.point3 = CGPoint(x: 0.75, y: 0.82)
                curve.point4 = CGPoint(x: 1, y: 1)
                guard let curveOut = curve.outputImage else { return }
                filteredImage = curveOut
            case .kodak:
                let fade = CIFilter.toneCurve()
                fade.inputImage = ciImage
                fade.point0 = CGPoint(x: 0, y: 0.1)
                fade.point1 = CGPoint(x: 0.25, y: 0.3)
                fade.point2 = CGPoint(x: 0.5, y: 0.6)
                fade.point3 = CGPoint(x: 0.75, y: 0.85)
                fade.point4 = CGPoint(x: 1, y: 1)
                guard let fadeOut = fade.outputImage else { return }
                let temp = CIFilter.temperatureAndTint()
                temp.inputImage = fadeOut
                temp.neutral = CIVector(x: 6500, y: 0)
                temp.targetNeutral = CIVector(x: 7500, y: 0)
                guard let tempOut = temp.outputImage else { return }
                filteredImage = tempOut
            case .vsco:
                let clarity = CIFilter.unsharpMask()
                clarity.inputImage = ciImage
                clarity.intensity = 1.0
                clarity.radius = 2.0
                guard let clarityOut = clarity.outputImage else { return }
                let temp = CIFilter.temperatureAndTint()
                temp.inputImage = clarityOut
                temp.neutral = CIVector(x: 6500, y: 0)
                temp.targetNeutral = CIVector(x: 6000, y: 0)
                guard let tempOut = temp.outputImage else { return }
                let fade = CIFilter.toneCurve()
                fade.inputImage = tempOut
                fade.point0 = CGPoint(x: 0, y: 0.08)
                fade.point1 = CGPoint(x: 0.25, y: 0.28)
                fade.point2 = CGPoint(x: 0.5, y: 0.55)
                fade.point3 = CGPoint(x: 0.75, y: 0.85)
                fade.point4 = CGPoint(x: 1, y: 1)
                guard let fadeOut = fade.outputImage else { return }
                filteredImage = fadeOut
            case .portra:
                let temp = CIFilter.temperatureAndTint()
                temp.inputImage = ciImage
                temp.neutral = CIVector(x: 6500, y: 0)
                temp.targetNeutral = CIVector(x: 7000, y: 0)
                guard let tempOut = temp.outputImage else { return }
                let curve = CIFilter.toneCurve()
                curve.inputImage = tempOut
                curve.point0 = CGPoint(x: 0, y: 0.05)
                curve.point1 = CGPoint(x: 0.25, y: 0.22)
                curve.point2 = CGPoint(x: 0.5, y: 0.55)
                curve.point3 = CGPoint(x: 0.75, y: 0.85)
                curve.point4 = CGPoint(x: 1, y: 1)
                guard let curveOut = curve.outputImage else { return }
                let pink = CIFilter.colorMonochrome()
                pink.inputImage = curveOut
                pink.color = CIColor(red: 1, green: 0.9, blue: 0.95)
                pink.intensity = 0.08
                guard let pinkOut = pink.outputImage else { return }
                filteredImage = pinkOut
            case .ektar:
                let sat = CIFilter.colorControls()
                sat.inputImage = ciImage
                sat.saturation = 1.5
                sat.brightness = 0.05
                sat.contrast = 1.2
                guard let satOut = sat.outputImage else { return }
                let temp = CIFilter.temperatureAndTint()
                temp.inputImage = satOut
                temp.neutral = CIVector(x: 6500, y: 0)
                temp.targetNeutral = CIVector(x: 6000, y: 0)
                guard let tempOut = temp.outputImage else { return }
                filteredImage = tempOut
            case .polaroid:
                let fade = CIFilter.toneCurve()
                fade.inputImage = ciImage
                fade.point0 = CGPoint(x: 0, y: 0.12)
                fade.point1 = CGPoint(x: 0.25, y: 0.32)
                fade.point2 = CGPoint(x: 0.5, y: 0.6)
                fade.point3 = CGPoint(x: 0.75, y: 0.85)
                fade.point4 = CGPoint(x: 1, y: 1)
                guard let fadeOut = fade.outputImage else { return }
                let blue = CIFilter.colorMonochrome()
                blue.inputImage = fadeOut
                blue.color = CIColor(red: 0.8, green: 0.9, blue: 1)
                blue.intensity = 0.12
                guard let blueOut = blue.outputImage else { return }
                let vignette = CIFilter.vignette()
                vignette.inputImage = blueOut
                vignette.intensity = 0.7
                vignette.radius = 2.0
                guard let vignetteOut = vignette.outputImage else { return }
                filteredImage = vignetteOut
            }
            print("applyFilter: filter applied in \(Date().timeIntervalSince(filterStart))s")
            let cgStart = Date()
            guard let cgImage = self.context.createCGImage(filteredImage, from: filteredImage.extent) else {
                print("applyFilter: failed to create CGImage")
                return
            }
            print("applyFilter: CGImage created in \(Date().timeIntervalSince(cgStart))s")
            let result = UIImage(cgImage: cgImage)
            DispatchQueue.main.async {
                self.previewImage = result
                self.processedImage = result
                self.addHistoryStep()
                print("applyFilter: total time \(Date().timeIntervalSince(start))s")
            }
        }
    }
    
    func addTextOverlay(_ text: String, font: UIFont, color: Color) {
        let newOverlay = TextOverlay(
            id: UUID(),
            text: text,
            position: CGPoint(x: 150, y: 150),
            font: font,
            color: color
        )
        
        textOverlays.append(newOverlay)
        selectedTextOverlay = newOverlay
        addHistoryStep()
    }
    
    func updateTextOverlay(_ overlay: TextOverlay) {
        if let index = textOverlays.firstIndex(where: { $0.id == overlay.id }) {
            textOverlays[index] = overlay
            addHistoryStep()
        }
    }
    
    func removeTextOverlay(_ overlay: TextOverlay) {
        textOverlays.removeAll { $0.id == overlay.id }
        selectedTextOverlay = nil
        addHistoryStep()
    }
    
    func addDrawingPoint(_ point: CGPoint) {
        currentPath.points.append(point)
    }
    
    func endDrawing() {
        if !currentPath.points.isEmpty {
            drawingPaths.append(currentPath)
            currentPath = DrawingPath(points: [], color: currentPath.color, lineWidth: currentPath.lineWidth)
            addHistoryStep()
        }
    }
    
    func clearDrawing() {
        drawingPaths = []
        currentPath = DrawingPath(points: [], color: .accentColorToken, lineWidth: 3.0)
        addHistoryStep()
    }
    
    func undo() {
        if historyIndex > 0 {
            historyIndex -= 1
            applyHistoryState(history[historyIndex])
        }
    }
    
    func redo() {
        if historyIndex < history.count - 1 {
            historyIndex += 1
            applyHistoryState(history[historyIndex])
        }
    }
    
    func addHistoryStep() {
        // Create a new state
        let currentState = EditHistory(
            processedImage: previewImage,
            textOverlays: textOverlays,
            drawingPaths: drawingPaths,
            filter: selectedFilter,
            scale: scale,
            rotation: rotation,
            position: position
        )
        
        // Skip adding if identical to the last state (prevents unnecessary history states)
        if historyIndex >= 0, history.count > 0, isIdenticalState(currentState, history[historyIndex]) {
            return
        }
        
        // If we're not at the end of history, remove future states
        if historyIndex < history.count - 1 {
            history = Array(history[0...historyIndex])
        }
        
        history.append(currentState)
        historyIndex = history.count - 1
    }
    
    private func isIdenticalState(_ state1: EditHistory, _ state2: EditHistory) -> Bool {
        // Compare essential properties to determine if states are effectively the same
        if state1.filter != state2.filter { return false }
        if state1.scale != state2.scale { return false }
        if state1.rotation != state2.rotation { return false }
        if state1.position != state2.position { return false }
        if state1.textOverlays.count != state2.textOverlays.count { return false }
        if state1.drawingPaths.count != state2.drawingPaths.count { return false }
        
        // For simplicity, we'll just check counts of arrays
        // A more thorough check would compare each element
        
        return true
    }
    
    private func applyHistoryState(_ state: EditHistory) {
        processedImage = state.processedImage
        previewImage = state.processedImage
        textOverlays = state.textOverlays
        drawingPaths = state.drawingPaths
        selectedFilter = state.filter
        scale = state.scale
        rotation = state.rotation
        position = state.position
    }
    
    func saveEditedImage() -> UIImage? {
        guard let baseImage = processedImage else { return nil }
        
        let renderer = UIGraphicsImageRenderer(size: baseImage.size)
        
        return renderer.image { context in
            // Draw the base image
            baseImage.draw(in: CGRect(origin: .zero, size: baseImage.size))
            
            let ctx = context.cgContext
            
            // Draw paths
            for path in drawingPaths {
                if path.points.count < 2 { continue }
                
                ctx.setStrokeColor(UIColor(path.color).cgColor)
                ctx.setLineWidth(path.lineWidth)
                ctx.setLineCap(.round)
                ctx.setLineJoin(.round)
                
                if let firstPoint = path.points.first {
                    // Use points directly, assuming they are relative to the image size
                    ctx.move(to: firstPoint) 
                    
                    for point in path.points.dropFirst() {
                        // Use points directly
                        ctx.addLine(to: point)
                    }
                }
                
                ctx.strokePath()
            }
            
            // Draw text overlays
            for overlay in textOverlays {
                let attributedString = NSAttributedString(
                    string: overlay.text,
                    attributes: [
                        .font: overlay.font,
                        .foregroundColor: UIColor(overlay.color)
                    ]
                )
                
                // Draw text at its stored position, assuming relative to image size
                let textRect = CGRect(
                    origin: overlay.position, // Use position directly
                    size: attributedString.size() // Calculate size needed
                )
                
                 // Ensure text doesn't draw outside bounds (optional, but safer)
                 let clippedRect = textRect.intersection(CGRect(origin: .zero, size: baseImage.size))
                 if !clippedRect.isNull {
                     attributedString.draw(in: clippedRect)
                 }
            }
        }
    }
    
    func saveToPhotoLibrary(completion: @escaping (Bool) -> Void) {
        guard let finalImage = saveEditedImage() else {
            completion(false)
            return
        }
        
        UIImageWriteToSavedPhotosAlbum(finalImage, nil, nil, nil)
        
        // Save to recent edits
        let thumbnail = finalImage.prepareThumbnail(of: CGSize(width: 200, height: 200)) ?? finalImage
        let newEdit = RecentEdit(id: UUID(), thumbnail: thumbnail, originalImage: selectedImage, editedImage: finalImage, date: Date())
        recentEdits.insert(newEdit, at: 0)
        
        // Limit recent edits to 20
        if recentEdits.count > 20 {
            recentEdits = Array(recentEdits.prefix(20))
        }
        
        saveRecentEdits()
        completion(true)
    }
    
    func shareImage() -> UIImage? {
        guard let finalImage = saveEditedImage() else {
            return nil
        }
        return finalImage
    }
    
    func loadRecentEdits() {
        // In a real app, load from user defaults or other storage
        // For demo, we'll leave this empty - it would populate as users edit images
        recentEdits = []
    }
    
    func saveRecentEdits() {
        // In a real app, save to user defaults or other storage
    }
    
    func loadEdit(_ edit: RecentEdit) {
        selectedImage = edit.originalImage
        processedImage = edit.editedImage
        // In a real app, you'd also restore the editing state
        // For now, let's just reset basic transform/filter state when loading
        resetTransformsAndFilter() 
        addHistoryStep() // Add initial state of loaded edit to history
    }
    
    // Function to reset transform and filter state
    private func resetTransformsAndFilter() {
        scale = 1.0
        rotation = .zero
        position = .zero
        selectedFilter = .none
        // Keep drawing/text, as they might be part of the loaded edit
    }

    // Function to reset the entire editing state
    func resetState() {
        // Reset current session images and selection
        selectedImage = nil
        processedImage = nil
        previewImage = nil
        imageSelection = nil
        
        // DO NOT reset recentEdits here
        // recentEdits = [] // Or reload them: loadRecentEdits()
        
        // Reset drawing state
        isDrawing = false
        drawingPaths = []
        currentPath = DrawingPath(points: [], color: .accentColorToken, lineWidth: 3.0)
        
        // Reset text state
        textOverlays = []
        selectedTextOverlay = nil
        
        // Reset filter
        selectedFilter = .none
        
        // Reset transforms
        scale = 1.0
        rotation = .zero
        position = .zero
        
        // Reset history for the session
        history = []
        historyIndex = -1
        
        // DO NOT reload recent edits here unless intended
        // loadRecentEdits()
    }
}

struct RecentEdit: Identifiable {
    let id: UUID
    let thumbnail: UIImage
    let originalImage: UIImage?
    let editedImage: UIImage
    let date: Date
}

struct DrawingPath: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    var color: Color
    var lineWidth: CGFloat
}

struct TextOverlay: Identifiable {
    let id: UUID
    var text: String
    var position: CGPoint
    var font: UIFont
    var color: Color
}

struct EditHistory {
    let processedImage: UIImage?
    let textOverlays: [TextOverlay]
    let drawingPaths: [DrawingPath]
    let filter: PhotoFilter
    let scale: CGFloat
    let rotation: Angle
    let position: CGSize
}

//enum PhotoFilter {
//    case none
//    case mono
//    case sepia
//    case vibrant
//    case noir
//    case vintage
//} 
