class NotesManager: ObservableObject {
    static let shared = NotesManager()
    @Published private(set) var notes: [Note] = []
    
    private let userDefaults = UserDefaults.standard
    private let notesKey = "savedNotes"
    
    init() {
        loadNotes()
    }
    
    func saveNote(type: RequestType, content: String, sessionData: [String]) {
        let note = Note(type: type, content: content, sessionData: sessionData)
        notes.append(note)
        saveNotes()
    }
    
    private func loadNotes() {
        if let data = userDefaults.data(forKey: notesKey),
           let decodedNotes = try? JSONDecoder().decode([Note].self, from: data) {
            notes = decodedNotes
        }
    }
    
    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            userDefaults.set(encoded, forKey: notesKey)
        }
    }
    
    func deleteNote(at indexSet: IndexSet) {
        notes.remove(atOffsets: indexSet)
        saveNotes()
    }
} 