import Foundation
import SwiftUI

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
        if let data = userDefaults.data(forKey: notesKey) {
            do {
                notes = try JSONDecoder().decode([Note].self, from: data)
                print("✅ Notes chargées : \(notes.count) notes")
            } catch {
                print("❌ Erreur lors du chargement des notes : \(error)")
                notes = []
            }
        }
    }
    
    private func saveNotes() {
        do {
            let encoded = try JSONEncoder().encode(notes)
            userDefaults.set(encoded, forKey: notesKey)
            print("✅ Notes sauvegardées : \(notes.count) notes")
        } catch {
            print("❌ Erreur lors de la sauvegarde des notes : \(error)")
        }
    }
    
    func deleteNote(at indexSet: IndexSet) {
        notes.remove(atOffsets: indexSet)
        saveNotes()
    }
} 