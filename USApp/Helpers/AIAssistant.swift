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
        self.openAI = OpenAI(apiToken: "VOTRE_CLE_API")
    }
    
    func generateAdvice(for activity: [String]) async {
        isTyping = true
        let prompt = createPrompt(from: activity)
        
        do {
            let query = ChatQuery(
                messages: [
                    ChatQuery.ChatCompletionMessageParam(role: .system, content: "Tu es un coach sportif expert qui donne des conseils personnalisés pour la préparation et la réussite des séances d'entraînement."),
                    ChatQuery.ChatCompletionMessageParam(role: .user, content: prompt)
                ],
                model: .gpt4
            )
            
            let result = try await openAI.chats(query: query)
            
            if let message = result.choices.first?.message.content {
                await MainActor.run {
                    self.messages.append(Message(content: message, isAI: true))
                    self.isTyping = false
                }
            } else {
                await MainActor.run {
                    self.messages.append(Message(content: "Réponse vide de l'IA.", isAI: true))
                    self.isTyping = false
                }
            }
        } catch {
            await MainActor.run {
                self.messages.append(Message(content: "Désolé, je n'ai pas pu générer de conseils pour le moment.", isAI: true))
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

struct AIAssistantView: View {
    @StateObject private var viewModel = AIAssistantViewModel()
    @State private var showingChat = false
    let activityData: [String]
    
    var body: some View {
        VStack {
            Button(action: {
                showingChat = true
            }) {
                Image("ai-avatar") // Ajouter une image d'avatar IA dans vos assets
                    .resizable()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                    .shadow(radius: 5)
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
                Image("ai-avatar")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
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