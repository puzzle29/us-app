struct Note: Codable, Identifiable {
    let id: UUID
    let date: Date
    let type: RequestType
    let content: String
    let sessionData: [String] // Les données de la séance associée
    
    init(type: RequestType, content: String, sessionData: [String]) {
        self.id = UUID()
        self.date = Date()
        self.type = type
        self.content = content
        self.sessionData = sessionData
    }
} 