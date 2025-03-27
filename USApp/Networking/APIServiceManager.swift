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

    private let googleAPI = GoogleAPISheet()
    private let noCodeAPI = NoCodeAPIService()
    private weak var timer: Timer?

    private init() {}

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
        let data = try await googleAPI.fetchAllRows(tabName: tabId, useCache: useCache)
        scheduleRaceNotifications(from: data)
        return data
    }

    func startBackgroundUpdates(forTabId tabId: String) {
        stopBackgroundUpdates()

        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
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

    private func scheduleRaceNotifications(from data: [[String]]) {
        let raceEntries = data.filter { row in
            row.count >= 6 && row[4].lowercased() == "course"
        }

        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        for entry in raceEntries {
            guard entry.count >= 6 else { continue }

            let dateString = entry[0]
            let details = entry[5]
            guard let raceDate = dateFromString(dateString) else { continue }

            let names = extractNames(from: details)
            guard !names.isEmpty else { continue }

            guard let notificationDate = Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: raceDate) else { continue }

            scheduleNotification(
                title: "Encouragez vos amis !",
                body: "\(names.joined(separator: ", ")) font une course demain, encouragez-les !!! 💪",
                at: notificationDate
            )
        }
    }

    private func scheduleNotification(title: String, body: String, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
            repeats: false
        )

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Erreur lors de la planification de la notification : \(error.localizedDescription)")
            } else {
                print("✅ Notification planifiée pour \(date)")
            }
        }
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
    func configure(with config: Config) {
        self.config = config
    }
}
