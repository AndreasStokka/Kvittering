import SwiftUI
import MessageUI

/// SwiftUI wrapper for MFMessageComposeViewController
struct MessageComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let messageBody: String
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIViewController {
        guard MFMessageComposeViewController.canSendText() else {
            let alert = UIAlertController(
                title: "Ikke tilgjengelig",
                message: "SMS er ikke tilgjengelig på denne enheten.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                dismiss()
            })
            let hostingController = UIHostingController(rootView: EmptyView())
            DispatchQueue.main.async {
                hostingController.present(alert, animated: true)
            }
            return hostingController
        }

        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        controller.recipients = recipients
        controller.subject = subject
        controller.body = messageBody
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
            dismiss()
        }
    }
}



