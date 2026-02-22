//
//  CustomContextPopover.swift
//

import SwiftUI

extension View {
  @ViewBuilder
  /// Custom context popover.
  /// - Parameters:
  ///   - isPresented: Binding<Bool>
  ///   - arrowDirection: UIPopoverArrowDirection
  ///   - content: @escaping (
  /// - Returns: Content)->some View
  func CustomContextPopover<Content: View>(isPresented: Binding<Bool>, arrowDirection: UIPopoverArrowDirection, @ViewBuilder content: @escaping ()->Content)->some View {
    self
      .background {
        PopOverController(isPresented: isPresented, arrowDirection: arrowDirection, content: content())
      }
  }
}

struct PopOverController<Content: View>: UIViewControllerRepresentable {
  @Binding var isPresented: Bool
  var arrowDirection: UIPopoverArrowDirection
  var content: Content

  @State private var alreadyPresented: Bool = false

  /// Make coordinator
  /// - Returns: Coordinator
  /// Make coordinator.
  func makeCoordinator() -> Coordinator {
    return Coordinator(parent: self)
  }

  /// Make u i view controller.
  /// - Parameters:
  ///   - context: Parameter description
  /// - Returns: some UIViewController
  func makeUIViewController(context: Context) -> some UIViewController {
    let controller = UIViewController()
    controller.view.backgroundColor = .clear
    return controller
  }

  /// Update u i view controller.
  /// - Parameters:
  ///   - _: Parameter description
  ///   - context: Parameter description
  func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    if alreadyPresented {
      if !isPresented {
        uiViewController.dismiss(animated: true) {
          alreadyPresented = false
        }
      }
    } else {
      if isPresented {
        let controller = CustomHostingView(rootView: content)
        controller.view.backgroundColor = .systemBackground
        controller.modalPresentationStyle = .popover
        controller.popoverPresentationController?.permittedArrowDirections = arrowDirection
            
        controller.presentationController?.delegate = context.coordinator
            
        controller.popoverPresentationController?.sourceView = uiViewController.view
            
        uiViewController.present(controller, animated: true)
      }
    }
  }

  class Coordinator: NSObject,UIPopoverPresentationControllerDelegate{
    var parent: PopOverController
    /// Parent:  pop over controller
    /// Initializes a new instance.
    /// - Parameters:
    ///   - parent: PopOverController
    init(parent: PopOverController) {
      self.parent = parent
    }
    
    /// Adaptive presentation style.
    /// - Parameters:
    ///   - for: Parameter description
    /// - Returns: UIModalPresentationStyle
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
      return .none
    }
    
    /// Presentation controller will dismiss.
    /// - Parameters:
    ///   - _: Parameter description
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
      parent.isPresented = false
    }
    
    /// Presentation controller.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - willPresentWithAdaptiveStyle: Parameter description
    ///   - transitionCoordinator: Parameter description
    func presentationController(_ presentationController: UIPresentationController, willPresentWithAdaptiveStyle style: UIModalPresentationStyle, transitionCoordinator: UIViewControllerTransitionCoordinator?) {
      DispatchQueue.main.async {
        self.parent.alreadyPresented = true
      }
    }
  }
}

class CustomHostingView<Content: View>: UIHostingController<Content>{
  /// View did load
  /// View did load.
  override func viewDidLoad() {
    super.viewDidLoad()
    preferredContentSize = view.intrinsicContentSize
  }
}
