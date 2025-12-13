import SwiftUI
import SwiftData
import MessageUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showDeleteAlert = false
    @State private var showMailComposer = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button(role: .destructive) { showDeleteAlert = true } label: {
                        Text("Slett alle kvitteringer")
                    }
                }

                Section {
                    Button {
                        showMailComposer = true
                    } label: {
                        Label("Tips en venn", systemImage: "message.fill")
                    }
                }

                Section("Om appen") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Alle data lagres lokalt på enheten i denne versjonen. Det betyr at dine data er sikre, og brukes ikke av appleverandøren, men du må selv stå for backup.")
                        Text("I en senere versjon vil vi lansere skylagring og familiekonto, noe som mest sannsynlig vil koste noen få kroner.")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
            }
            .navigationTitle("Innstillinger")
            .alert("Slett alle?", isPresented: $showDeleteAlert) {
                Button("Slett", role: .destructive) {
                    try? viewModel.deleteAll()
                }
                Button("Avbryt", role: .cancel) {}
            }
            .sheet(isPresented: $showMailComposer) {
                MessageComposeView(
                    recipients: [],
                    subject: "Sjekk ut Kvittering-appen!",
                    messageBody: "Hei! Jeg har funnet en genial app for å organisere kvitteringer. Den heter 'Kvittering' og hjelper deg med å holde oversikt over alle kvitteringene dine. Sjekk den ut!"
                )
            }
            .onAppear {
                viewModel.attach(context: modelContext)
            }
        }
    }
}

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
