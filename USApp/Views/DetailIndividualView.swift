//
//  DetailIndividualView.swift
//  USApp
//
//  Created by Johann FOURNIER on 16/12/2024.
//

import SwiftUI

struct DetailIndividualView: View {
    let rowData: [String]
    @Binding var selectedProfile: String?

    private func openInMaps(address: String) {
        let addressEncoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?q=\(addressEncoded)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                let webUrl = URL(string: "https://maps.apple.com/?q=\(addressEncoded)")!
                UIApplication.shared.open(webUrl)
            }
        }
    }

    var body: some View {
        ZStack {
            // MARK: - Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1, green: 0.7, blue: 0.7, opacity: 0.3),
                    Color(red: 0.7, green: 0.7, blue: 1, opacity: 0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // MARK: - Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // MARK: - Title
                    Text(formatDate(rowData[0]))
                        .font(.title2)
                        .foregroundColor(DetailViewColors.titleColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 10)

                    // MARK: - Échauffement
                    DetailRow(
                        icon: DetailViewIcons.warmup,
                        title: "Échauffement",
                        content: rowData[1],
                        color: DetailViewColors.warmupColor
                    )

                    // MARK: - Durée
                    DetailRow(
                        icon: DetailViewIcons.duration,
                        title: "Durée",
                        content: rowData[2],
                        color: DetailViewColors.durationColor
                    )

                    // MARK: - Récupération
                    DetailRow(
                        icon: DetailViewIcons.recovery,
                        title: "Récupération",
                        content: rowData[3],
                        color: DetailViewColors.recoveryColor
                    )

                    // MARK: - Détails
                    DetailRow(
                        icon: DetailViewIcons.details,
                        title: "Détails",
                        content: rowData[5],
                        color: DetailViewColors.detailsColor
                    )

                    // MARK: - Allure
                    DetailRow(
                        icon: DetailViewIcons.pace,
                        title: "Allure",
                        content: rowData[6],
                        color: DetailViewColors.paceColor
                    )

                    // MARK: - Lieu
                    DetailRow(
                        icon: DetailViewIcons.location,
                        title: "Lieu",
                        content: rowData[7],
                        color: DetailViewColors.locationColor,
                        isInteractive: true
                    ) {
                        openInMaps(address: rowData[7])
                    }

                    // Ajouter le bouton de demande
                    RequestButton(sessionData: rowData)
                        .padding(.top, 20)
                        .frame(maxWidth: .infinity, alignment: .center)

                    // Ajouter l'assistant IA
                    AIAssistantView(activityData: rowData)
                        .padding(.top, 20)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // MARK: - Toolbar
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton()
            }
        }
    }

    // MARK: - Helpers
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "dd-MM-yyyy"

        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "fr_FR")
        outputFormatter.dateFormat = "EEEE d MMMM"

        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date).capitalized
        }
        return dateString
    }
}

#Preview {
    NavigationView {
        DetailIndividualView(
            rowData: [
                "11-12-2024",
                "20min",
                "40min",
                "10min",
                "Fractionné",
                "2 x (8x30s/30s)",
                "Rapide",
                "Parc des sports Val-de-Seine"
            ],
            selectedProfile: .constant("Johann")
        )
    }
}
