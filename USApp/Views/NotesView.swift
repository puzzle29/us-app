import SwiftUI

struct NotesView: View {
    @StateObject private var notesManager = NotesManager.shared
    
    var body: some View {
        NavigationView {
            Group {
                if notesManager.notes.isEmpty {
                    VStack {
                        Text("Aucune note enregistrée")
                            .foregroundColor(.secondary)
                            .padding()
                        Text("Prenez des notes depuis les détails d'une séance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(notesManager.notes) { note in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(note.type)
                                        .font(.caption)
                                        .padding(4)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                    
                                    Spacer()
                                    
                                    Text(note.date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(note.content)
                                    .lineLimit(2)
                                
                                if !note.sessionData.isEmpty {
                                    Text("Séance du \(formatDate(note.sessionData[0]))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { indexSet in
                            notesManager.deleteNote(at: indexSet)
                        }
                    }
                }
            }
            .navigationTitle("Mes Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "dd-MM-yyyy"
        
        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "fr_FR")
        outputFormatter.dateFormat = "d MMMM"
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        return dateString
    }
}

#Preview {
    NotesView()
} 