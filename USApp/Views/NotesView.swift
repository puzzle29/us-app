import SwiftUI

struct NotesView: View {
    @StateObject private var notesManager = NotesManager.shared
    
    var body: some View {
        NavigationView {
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
                            Text("Séance du \(note.sessionData[0])")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    notesManager.deleteNote(at: indexSet)
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    NotesView()
} 