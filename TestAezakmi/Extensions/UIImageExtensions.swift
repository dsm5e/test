import UIKit

extension UIImage {
    func prepareThumbnail(of size: CGSize) -> UIImage? {
        let scale = max(size.width / self.size.width, size.height / self.size.height)
        let width = self.size.width * scale
        let height = self.size.height * scale
        let targetRect = CGRect(x: (size.width - width) / 2, y: (size.height - height) / 2, width: width, height: height)

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }

        draw(in: targetRect)

        return UIGraphicsGetImageFromCurrentImageContext()
    }
} 