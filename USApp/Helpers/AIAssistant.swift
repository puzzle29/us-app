import SwiftUI
import OpenAI

class AIAssistantViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isTyping = false
    private var openAI: OpenAI
    
    struct Message: Identifiable {
        let id = UUID()
        let content: String
        let isAI: Bool
    }
    
    init() {
        // Assurez-vous que la clé API est définie
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String else {
            self.openAI = OpenAI(apiToken: "VOTRE_CLE_API")
            return
        }
        self.openAI = OpenAI(apiToken: apiKey)
    }
    
    func generateAdvice(for activity: [String]) async {
        await MainActor.run {
            isTyping = true
        }
        
        let prompt = createPrompt(from: activity)
        
        do {
            print("🔄 Envoi de la requête à OpenAI...")
            let query = ChatQuery(
                messages: [
                    ChatQuery.ChatCompletionMessageParam(role: .system, content: "Tu es un coach sportif expert qui donne des conseils personnalisés pour la préparation et la réussite des séances d'entraînement.")!,
                    ChatQuery.ChatCompletionMessageParam(role: .user, content: prompt)!
                ],
                model: .gpt4
            )
            
            print("📝 Prompt envoyé : \(prompt)")
            
            let result = try await openAI.chats(query: query)
            print("✅ Réponse reçue de OpenAI")
            
            await MainActor.run {
                if let message = result.choices.first?.message.content {
                    self.messages.append(Message(content: message, isAI: true))
                } else {
                    self.messages.append(Message(content: "Réponse vide de l'IA.", isAI: true))
                }
                self.isTyping = false
            }
        } catch {
            print("❌ Erreur OpenAI : \(error)")
            await MainActor.run {
                self.messages.append(Message(content: "Désolé, je n'ai pas pu générer de conseils pour le moment. Erreur: \(error.localizedDescription)", isAI: true))
                self.isTyping = false
            }
        }
    }
    
    private func createPrompt(from activity: [String]) -> String {
        return """
        En tant que coach sportif, analyse cette séance d'entraînement et donne des conseils personnalisés :
        
        Date: \(activity[0])
        Échauffement: \(activity[1])
        Durée: \(activity[2])
        Récupération: \(activity[3])
        Type: \(activity[4])
        Détails: \(activity[5])
        Allure: \(activity[6])
        Lieu: \(activity[7])
        
        Donne des conseils sur :
        1. La préparation optimale
        2. La gestion de l'effort
        3. La récupération
        4. Les points d'attention spécifiques au lieu
        5. La nutrition avant/pendant/après
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
            
            Text(message.content)
                .padding()
                .background(message.isAI ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                .cornerRadius(15)
            
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