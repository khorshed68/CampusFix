//
//  ImagePicker.swift
//  CampusFix
//
//  LAB TOPIC: Delegate Pattern + UIKit-to-SwiftUI integration
//
//  SwiftUI has no built-in camera screen, so we wrap UIKit's
//  UIImagePickerController with UIViewControllerRepresentable.
//
//  What is a delegate?
//    An object that another object "hands work to" or "reports back to".
//    UIImagePickerController does not know what our app wants to do with
//    the photo. Instead it calls methods on its `delegate`:
//      - imagePickerController(_:didFinishPickingMediaWithInfo:)  -> user chose a photo
//      - imagePickerControllerDidCancel(_:)                       -> user cancelled
//
//  Who is the delegate here?
//    The `Coordinator` class below. It conforms to the delegate protocols,
//    receives the photo, and passes it back to SwiftUI through a @Binding.
//

import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    enum Source {
        case camera
        case photoLibrary
    }

    let source: Source
    @Binding var selectedImage: UIImage?        // written by the Coordinator
    @Environment(\.dismiss) private var dismiss

    static var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    // 1. SwiftUI asks us to create the coordinator (our delegate object).
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // 2. SwiftUI asks us to create the UIKit view controller.
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        // The simulator has no camera, so fall back to the photo library.
        picker.sourceType = (source == .camera && Self.isCameraAvailable) ? .camera : .photoLibrary
        picker.allowsEditing = false
        picker.delegate = context.coordinator   // <- connect the delegate
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // Nothing to update: the picker is configured once.
    }

    // 3. The delegate. UIKit calls these methods with the result.
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        /// Called by UIKit when the user picks or takes a photo.
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image    // send result back to SwiftUI
            }
            parent.dismiss()
        }

        /// Called by UIKit when the user taps Cancel.
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
