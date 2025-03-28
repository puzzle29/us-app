//
//  SharedViews.swift
//  USApp
//
//  Created by Johann FOURNIER on 16/12/2024.
//

import SwiftUI

// MARK: - BackButton
struct BackButton: View {
   
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body
    var body: some View {
        Button(action: {
            dismiss()
        }) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                Text("Retour")
            }
            .foregroundColor(.blue)
        }
    }
}

// MARK: - DetailRow
struct DetailRow: View {
    // MARK: - Properties
    let icon: String
    let title: String
    let content: String
    let color: Color
    var isInteractive: Bool = false
    var action: (() -> Void)? = nil

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.body)
                Text(title)
                    .font(.body)
            }
            .foregroundColor(color)
            
            if isInteractive {
                Button(action: {
                    action?()
                }) {
                    HStack {
                        Text(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "N/A" : content)
                            .font(.body)
                            .foregroundColor(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                        
                        Image(systemName: "arrow.up.forward.app.fill")
                            .foregroundColor(.blue)
                    }
                    .padding(.leading, 24)
                }
            } else {
                Text(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "N/A" : content)
                    .font(.body)
                    .foregroundColor(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .primary)
                    .padding(.leading, 24)
            }
        }
    }
}

// MARK: - Color Extension
extension Color {
    
    // MARK: - Initializer with Hex
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - DetailViewColors
struct DetailViewColors {
    static let titleColor = Color.primary
    static let warmupColor = Color.orange
    static let detailsColor = Color.purple
    static let durationColor = Color.pink
    static let recoveryColor = Color.green
    static let paceColor = Color.purple.opacity(0.8)
    static let locationColor = Color.blue
}

// MARK: - DetailViewIcons
struct DetailViewIcons {
    static let warmup = "flame.fill"
    static let details = "info.circle.fill"
    static let duration = "clock.fill"
    static let recovery = "heart.circle.fill"
    static let pace = "speedometer"
    static let location = "location.fill"
}

// Ajouter un enum pour les types de demandes
enum RequestType: String, CaseIterable {
    case question = "Question"
    case reclamation = "Réclamation"
    case permission = "Demande de permission"
    case autre = "Autre"
}

// Ajouter un composant pour le bouton de demande
struct RequestButton: View {
    @State private var showingRequestSheet = false
    @State private var selectedRequestType: RequestType = .question
    @State private var messageText = ""
    
    var body: some View {
        VStack {
            Button(action: {
                showingRequestSheet = true
            }) {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundColor(.white)
                    Text("Prendre une note")
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
        }
        .sheet(isPresented: $showingRequestSheet) {
            RequestFormView(
                showingSheet: $showingRequestSheet,
                selectedType: $selectedRequestType,
                messageText: $messageText
            )
        }
    }
}

// Ajouter une vue pour le formulaire
struct RequestFormView: View {
    @Binding var showingSheet: Bool
    @Binding var selectedType: RequestType
    @Binding var messageText: String
    @Environment(\.dismiss) private var dismiss
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Type de note")) {
                    Picker("Type", selection: $selectedType) {
                        ForEach(RequestType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                
                Section(header: Text("La note")) {
                    TextEditor(text: $messageText)
                        .frame(height: 150)
                }
                
                Section {
                    Button(action: {
                        sendRequest()
                        showingConfirmation = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Envoyer")
                            Spacer()
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Nouvelle note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .alert("Note enregistrée", isPresented: $showingConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Votre note a été enregistrée avec succès.")
            }
        }
    }
    
    private func sendRequest() {
        let subject = "[\(selectedType.rawValue)] Demande US Athlé"
        let body = messageText
        
        if let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "mailto:email@example.com?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(url)
        }
    }
}
