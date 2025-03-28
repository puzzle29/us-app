//
//  IndividualView.swift
//  USApp
//
//  Created by Johann FOURNIER on 12/12/2024.
//

import SwiftUI

struct IndividualView: View {
    @Binding var selectedProfile: String?
    @Binding var showProfileSelection: Bool
    @State private var sheetData: [[String]] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var selectedRow: [String]?
    @State private var showDetailView: Bool = false
    @State private var isUpdating: Bool = false
    var isShowingFutureSessions: Bool
    @Binding var searchQuery: String
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
                } else if filteredData().isEmpty {
                    Text("Aucune séance trouvée pour \(selectedProfile ?? "le profil sélectionné").")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(filteredData(), id: \.self) { row in
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
                DetailIndividualView(
                    rowData: selectedRow,
                    selectedProfile: $selectedProfile
                )
            }
        }
        .onAppear {
            if let profile = selectedProfile {
                fetchIndividualData(tabName: profile)
            }
        }
        .onChange(of: selectedProfile) { _, newValue in
            if let profile = newValue {
                fetchIndividualData(tabName: profile)
            }
        }
    }

    private func filteredData() -> [[String]] {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Ajout de logs pour déboguer
        print("📊 Données totales : \(sheetData.count) lignes")
        
        let filtered = sheetData.filter { row in
            // Vérifier le format de la ligne
            print("🔍 Analyse ligne : \(row)")
            
            guard row.count >= 8 else {
                print("⚠️ Ligne ignorée : moins de 8 colonnes")
                return false
            }
            
            // Vérifier le format de la date
            let dateString = row[0]
            print("📅 Date à analyser : \(dateString)")
            
            guard let date = dateFromString(dateString) else {
                print("⚠️ Date invalide : \(dateString)")
                return false
            }
            
            // Vérifier les critères de filtrage
            let matchesSearch = searchQuery.isEmpty || row.contains { $0.localizedCaseInsensitiveContains(searchQuery) }
            let matchesDate = isShowingFutureSessions ? date >= today : date < today
            let matchesType = selectedActivityType == nil || row[4] == selectedActivityType
            
            print("""
                ✓ Résultat du filtrage pour la ligne :
                - Date valide : \(date)
                - Correspond à la recherche : \(matchesSearch)
                - Correspond au filtre de date : \(matchesDate)
                - Correspond au filtre de type : \(matchesType)
                - Sera affichée : \(matchesSearch && matchesDate && matchesType)
                """)
            
            return matchesSearch && matchesDate && matchesType
        }
        
        print("✅ Résultat final : \(filtered.count) lignes après filtrage")
        return filtered
    }

    private func dateFromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        // Ajouter ces lignes pour s'assurer que le parsing de date est cohérent
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.timeZone = TimeZone.current
        
        if let date = formatter.date(from: dateString) {
            print("✅ Date parsée avec succès : \(date)")
            return date
        } else {
            print("❌ Échec du parsing de la date : \(dateString)")
            return nil
        }
    }

    private func fetchIndividualData(tabName: String) {
        isLoading = true
        errorMessage = nil
        isUpdating = true
        
        print("🔄 Début du chargement des données pour \(tabName)")
        
        let cacheKey = "GoogleSheet_\(tabName)"
        
        if let cachedData = cacheManager.loadData(forKey: cacheKey) {
            print("📦 Données trouvées dans le cache : \(cachedData.count) lignes")
            self.sheetData = cachedData
            self.isLoading = false
        }
        
        Task {
            do {
                let data = try await GoogleAPISheet().fetchAllRows(tabName: tabName, useCache: false)
                print("🌐 Données reçues de l'API : \(data.count) lignes")
                
                await MainActor.run {
                    self.sheetData = data
                    self.isUpdating = false
                    print("✅ Données mises à jour dans la vue")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur : \(error.localizedDescription)"
                    self.isUpdating = false
                    print("❌ Erreur lors du chargement : \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    IndividualView(
        selectedProfile: .constant("Johann"),
        showProfileSelection: .constant(false),
        isShowingFutureSessions: true,
        searchQuery: .constant(""),
        selectedActivityType: .constant(nil)
    )
}
