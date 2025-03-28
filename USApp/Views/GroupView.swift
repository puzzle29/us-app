//
//  GroupView.swift
//  USApp
//
//  Created by Johann FOURNIER on 16/12/2024.
//

import SwiftUI

// Création d'un ViewModel séparé
final class GroupViewModel: ObservableObject {
    @Published private(set) var sheetData: [[String]] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    private let cacheManager = CacheManager()
    
    // Ajouter la fonction pour mettre à jour les données
    func fetchGroupData() {
        isLoading = true
        errorMessage = nil
        
        let cacheKey = "GoogleSheet_groupe"
        
        // Charger les données en cache
        if let cachedData = cacheManager.loadData(forKey: cacheKey) {
            self.sheetData = cachedData
            self.isLoading = false
        }
        
        Task {
            do {
                let data = try await APIServiceManager.shared.fetchSheetData(tabId: "groupe", useCache: false)
                await MainActor.run {
                    self.sheetData = data
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    // Déplacer la logique de filtrage dans le ViewModel
    func filteredData(searchQuery: String, isShowingFutureSessions: Bool, activityType: String?) -> [[String]] {
        let today = Calendar.current.startOfDay(for: Date())
        
        print("💭 Filtrage : \(sheetData.count) lignes totales")
        
        let filtered = sheetData.filter { row in
            guard row.count >= 8, let date = dateFromString(row[0]) else {
                print("⚠️ Ligne ignorée : format incorrect ou date invalide")
                return false
            }
            let matchesSearch = searchQuery.isEmpty || row.contains { $0.localizedCaseInsensitiveContains(searchQuery) }
            let matchesDate = isShowingFutureSessions ? date >= today : date < today
            let matchesType = activityType == nil || row[4] == activityType
            return matchesSearch && matchesDate && matchesType
        }
        
        print("✅ Résultat du filtrage : \(filtered.count) lignes")
        return filtered
    }

    private func dateFromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.date(from: dateString)
    }
}

// Vue refactorisée
struct GroupView: View {
    @StateObject private var viewModel = GroupViewModel()
    @State private var sheetData: [[String]] = []
    @State private var isLoading: Bool = false
    @State private var isUpdating: Bool = false
    @State private var errorMessage: String?
    @Binding var searchQuery: String
    @State private var selectedRow: [String]?
    @State private var showDetailView: Bool = false
    var isShowingFutureSessions: Bool
    @Binding var selectedActivityType: String?

    private let cacheManager = CacheManager()

    var body: some View {
        ZStack {
            VStack(spacing: 5) {
                if isUpdating {
                    InfiniteProgressBar(color: Color(red: 0.7, green: 0.5, blue: 1.0))
                        .frame(height: 4)
                        .padding(.horizontal)
                }

                if let errorMessage = errorMessage {
                    Text("Erreur : \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                } else if viewModel.filteredData(
                    searchQuery: searchQuery,
                    isShowingFutureSessions: isShowingFutureSessions,
                    activityType: selectedActivityType
                ).isEmpty {
                    Text("Aucune séance trouvée")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(viewModel.filteredData(
                                searchQuery: searchQuery,
                                isShowingFutureSessions: isShowingFutureSessions,
                                activityType: selectedActivityType
                            ), id: \.self) { row in
                                Button(action: {
                                    selectedRow = row
                                    showDetailView = true
                                }) {
                                    SessionTile(
                                        type: row[4],
                                        details: row[5],
                                        location: row[7],
                                        date: row[0]
                                    )
                                }
                                .buttonStyle(TileButtonStyle())
                            }
                            
                            // Ajouter un espaceur en bas
                            Spacer(minLength: 80) // Ajuster cette valeur selon vos besoins
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showDetailView) {
            if let selectedRow = selectedRow {
                DetailGroupView(rowData: selectedRow)
            }
        }
        .onAppear {
            viewModel.fetchGroupData() // Appeler la méthode du ViewModel
        }
    }
}
