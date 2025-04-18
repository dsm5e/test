# TestAezakmi Photo Editor

A SwiftUI application demonstrating a photo editor with various features including:

- Image import from Gallery or Camera
- Image filtering using Core Image
- Drawing on images
- Adding text overlays
- Transformation gestures (scale, rotate, pan)
- Edit history (Undo/Redo)
- Saving edited images to the Photo Library
- Sharing edited images
- Firebase Authentication (Email/Password, Google Sign-In)
- Basic input validation

## Setup

1.  Configure Firebase for your project (add `GoogleService-Info.plist`).
2.  Ensure necessary privacy keys are in `Info.plist` (`NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription`, `NSCameraUsageDescription`).
3.  Open the `.xcodeproj` or `.xcworkspace` in Xcode and run on a simulator or device. 