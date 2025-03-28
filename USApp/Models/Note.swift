import Foundation // Ajout pour UUID et Date

struct Note: Codable, Identifiable {
    let id: UUID
    let date: Date
    let type: String // Changé de RequestType à String pour la simplicité du codage
    let content: String
    let sessionData: [String] // Les données de la séance associée
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case type
        case content
        case sessionData
    }
    
    init(type: RequestType, content: String, sessionData: [String]) {
        self.id = UUID()
        self.date = Date()
        self.type = type.rawValue // Stockage de la valeur brute
        self.content = content
        self.sessionData = sessionData
    }
    
    // Ajout des méthodes de codage requises
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        type = try container.decode(String.self, forKey: .type)
        content = try container.decode(String.self, forKey: .content)
        sessionData = try container.decode([String].self, forKey: .sessionData)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(type, forKey: .type)
        try container.encode(content, forKey: .content)
        try container.encode(sessionData, forKey: .sessionData)
    }
} 