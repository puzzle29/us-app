//
//  APIServiceManager.swift
//  USApp
//
//  Created by Johann FOURNIER on 21/12/2024.
//

import Foundation
import UserNotifications

final class APIServiceManager {
    static let shared = APIServiceManager()

    private var config: Config
    private let googleAPI = GoogleAPISheet()
    private let noCodeAPI = NoCodeAPIService()
    private weak var timer: Timer?

    private init() {
        self.config = Config(
            updateInterval: 300,
            maxRetries: 3,
            cacheTimeout: 3600
        )
    }

    // Ajout d'un type d'erreur personnalisé
    enum APIError: Error {
        case networkError(Error)
        case invalidData
        case rateLimitExceeded
        case cacheError
    }

    // Ajout d'une configuration
    struct Config {
        let updateInterval: TimeInterval
        let maxRetries: Int
        let cacheTimeout: TimeInterval
    }

    // Amélioration de la gestion du timer avec une weak reference
    private func fetchWithRetry(tabId: String, attempts: Int = 0) async throws -> [[String]] {
        do {
            return try await fetchSheetData(tabId: tabId)
        } catch {
            if attempts < config.maxRetries {
                try await Task.sleep(nanoseconds: 1_000_000_000 * UInt64(attempts))
                return try await fetchWithRetry(tabId: tabId, attempts: attempts + 1)
            }
            throw APIError.networkError(error)
        }
    }

    // Amélioration de la gestion de la mémoire
    deinit {
        stopBackgroundUpdates()
    }

    func fetchSheetData(tabId: String, useCache: Bool = true) async throws -> [[String]] {
        do {
            let data = try await googleAPI.fetchAllRows(tabName: tabId, useCache: useCache)
            return data
        } catch {
            print("❌ Erreur dans fetchSheetData : \(error)")
            throw error
        }
    }

    func startBackgroundUpdates(forTabId tabId: String) {
        stopBackgroundUpdates()

        timer = Timer.scheduledTimer(withTimeInterval: config.updateInterval, repeats: true) { _ in
            Task {
                do {
                    let _ = try await self.fetchSheetData(tabId: tabId, useCache: false)
                    print("🔄 Mise à jour en arrière-plan réussie pour l'onglet \(tabId)")
                } catch {
                    print("❌ Erreur lors de la mise à jour en arrière-plan : \(error.localizedDescription)")
                }
            }
        }

        print("✅ Mises à jour en arrière-plan démarrées pour \(tabId)")
    }

    func stopBackgroundUpdates() {
        timer?.invalidate()
        timer = nil
        print("⏹️ Mises à jour en arrière-plan arrêtées")
    }

    private func dateFromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.date(from: dateString)
    }

    private func extractNames(from details: String) -> [String] {
        let regex = try? NSRegularExpression(pattern: "\\(([^)]+)\\)")
        let matches = regex?.matches(in: details, range: NSRange(details.startIndex..., in: details)) ?? []

        return matches.compactMap { match in
            if let range = Range(match.range(at: 1), in: details) {
                return String(details[range])
            }
            return nil
        }
    }

    // Ajouter une méthode de configuration publique
    func configure(with newConfig: Config) {
        self.config = newConfig
        if timer != nil {
            stopBackgroundUpdates()
            startBackgroundUpdates(forTabId: "groupe")
        }
    }
}
