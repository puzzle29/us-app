import SwiftUI
import OpenAI

// Ajout des structures pour le décodage manuel
struct ChatResponse: Codable {
    let id: String
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
        }
    }
    
    struct Message: Codable {
        let role: String
        let content: String
    }
}

class AIAssistantViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isTyping = false
    private let apiKey: String
    
    struct Message: Identifiable {
        let id = UUID()
        let content: String
        let isAI: Bool
    }
    
    init() {
        // Remplacez ceci par votre clé API
        self.apiKey = "VOTRE_CLE_API_OPENAI"
    }
    
    func generateAdvice(for activity: [String]) async {
        await MainActor.run {
            isTyping = true
        }
        
        let prompt = createPrompt(from: activity)
        
        do {
            let requestBody: [String: Any] = [
                "model": "gpt-3.5-turbo",
                "messages": [
                    ["role": "system", "content": "Tu es un coach sportif expert qui donne des conseils personnalisés pour la préparation et la réussite des séances d'entraînement."],
                    ["role": "user", "content": prompt]
                ]
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            
            var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization") // Utilisation directe de apiKey
            request.httpBody = jsonData
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let decoder = JSONDecoder()
            let response = try decoder.decode(ChatResponse.self, from: data)
            
            await MainActor.run {
                if let message = response.choices.first?.message.content {
                    self.messages.append(Message(content: message, isAI: true))
                } else {
                    self.messages.append(Message(content: "Réponse vide de l'IA.", isAI: true))
                }
                self.isTyping = false
            }
            
        } catch {
            print("❌ Erreur détaillée : \(error)")
            
            await MainActor.run {
                self.messages.append(Message(content: "Désolé, je n'ai pas pu générer de conseils pour le moment. Veuillez réessayer.", isAI: true))
                self.isTyping = false
            }
        }
    }
    
    private func createPrompt(from activity: [String]) -> String {
        return """
        En tant que coach sportif, donne des conseils courts et précis (max 150 mots) pour cette séance :
        
        Date: \(activity[0])
        Échauffement: \(activity[1])
        Durée: \(activity[2])
        Récupération: \(activity[3])
        Type: \(activity[4])
        Détails: \(activity[5])
        Allure: \(activity[6])
        Lieu: \(activity[7])
        
        Donne 3 conseils essentiels et concis sur :
        1. Préparation
        2. Exécution
        3. Récupération
        """
    }
}

struct AIAssistantImage: View {
    var size: CGFloat
    
    var body: some View {
        Group {
            if let _ = UIImage(named: "ai-avatar") {
                Image("ai-avatar")
                    .resizable()
                    .frame(width: size, height: size)
            } else {
                Image(systemName: "wand.and.stars")
                    .resizable()
                    .foregroundColor(.blue)
                    .frame(width: size, height: size)
            }
        }
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.blue, lineWidth: 2))
        .shadow(radius: 5)
    }
}

struct AIAssistantView: View {
    @StateObject private var viewModel = AIAssistantViewModel()
    @State private var showingChat = false
    let activityData: [String]
    
    var body: some View {
        VStack {
            Button(action: {
                showingChat = true
            }) {
                AIAssistantImage(size: 60)
            }
        }
        .sheet(isPresented: $showingChat) {
            ChatView(viewModel: viewModel, activityData: activityData)
        }
    }
}

struct ChatView: View {
    @ObservedObject var viewModel: AIAssistantViewModel
    @Environment(\.dismiss) private var dismiss
    let activityData: [String]
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                        }
                        
                        if viewModel.isTyping {
                            TypingIndicator()
                        }
                    }
                    .padding()
                }
                
                if viewModel.messages.isEmpty {
                    Button(action: {
                        Task {
                            await viewModel.generateAdvice(for: activityData)
                        }
                    }) {
                        Text("Demander des conseils")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Assistant IA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: AIAssistantViewModel.Message
    
    var body: some View {
        HStack {
            if message.isAI {
                AIAssistantImage(size: 30)
            }
            
            if message.isAI {
                TypingText(text: message.content)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(15)
            } else {
                Text(message.content)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
            }
            
            if !message.isAI {
                Spacer()
            }
        }
    }
}

struct TypingIndicator: View {
    @State private var dotCount = 0
    
    var body: some View {
        HStack {
            Text("Réflexion en cours")
            Text(String(repeating: ".", count: dotCount + 1))
        }
        .foregroundColor(.gray)
        .onAppear {
            let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
            _ = timer.sink { _ in
                dotCount = (dotCount + 1) % 3
            }
        }
    }
}

// Ajouter une structure pour le texte avec effet typing
struct TypingText: View {
    let text: String
    @State private var displayedText = ""
    @State private var currentIndex = 0
    
    var body: some View {
        Text(displayedText)
            .onAppear {
                startTyping()
            }
    }
    
    private func startTyping() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if currentIndex < text.count {
                let index = text.index(text.startIndex, offsetBy: currentIndex)
                displayedText += String(text[index])
                currentIndex += 1
            } else {
                timer.invalidate()
            }
        }
    }
} 