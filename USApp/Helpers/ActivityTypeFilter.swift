import SwiftUI

struct ActivityTypeFilter: View {
    @Binding var selectedType: String?
    let types: [String]
    
    var body: some View {
        Menu {
            Button(action: { selectedType = nil }) {
                HStack {
                    Text("Tous")
                    if selectedType == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            ForEach(types, id: \.self) { type in
                Button(action: { selectedType = type }) {
                    HStack {
                        Text(type)
                        if selectedType == type {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundColor(.blue)
                Text(selectedType ?? "Type")
                    .foregroundColor(.blue)
            }
            .padding(8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
} 