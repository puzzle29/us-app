//
//  CacheManager.swift
//  USApp
//
//  Created by Johann FOURNIER on 21/12/2024.
//

import Foundation

final class CacheManager {
    struct CacheConfig {
        let maxAge: TimeInterval
        let maxSize: Int64
        
        static let `default` = CacheConfig(
            maxAge: 3600, // 1 heure
            maxSize: 1024 * 1024 * 1024 // 1 GB
        )
    }

    private let cacheDirectory: URL
    private let fileManager: FileManager
    private let config: CacheConfig

    init(config: CacheConfig = .default) {
        fileManager = FileManager.default
        cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.config = config
    }

    func saveData(_ data: [[String]], forKey key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        do {
            let dataToSave = try JSONEncoder().encode(data)
            try dataToSave.write(to: fileURL, options: .atomic)
            print("✅ Cache enregistré pour la clé \(key)")
        } catch {
            print("❌ Erreur lors de l'enregistrement dans le cache : \(error)")
        }
    }

    func loadData(forKey key: String) -> [[String]]? {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        do {
            let cachedData = try Data(contentsOf: fileURL)
            let decodedData = try JSONDecoder().decode([[String]].self, from: cachedData)
            print("✅ Données chargées depuis le cache pour la clé \(key)")
            return decodedData
        } catch {
            print("❌ Erreur lors de la lecture du cache : \(error)")
            return nil
        }
    }

    func clearCache(forKey key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        do {
            try fileManager.removeItem(at: fileURL)
            print("✅ Cache supprimé pour la clé \(key)")
        } catch {
            print("❌ Erreur lors de la suppression du cache : \(error)")
        }
    }

    private func isDataExpired(forKey key: String) -> Bool {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
              let modificationDate = attributes[.modificationDate] as? Date else {
            return true
        }
        return Date().timeIntervalSince(modificationDate) > config.maxAge
    }

    private func cleanupCache() {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey])
            let expiredFiles = files.filter { isDataExpired(forKey: $0.lastPathComponent) }
            try expiredFiles.forEach { try fileManager.removeItem(at: $0) }
        } catch {
            print("❌ Erreur lors du nettoyage du cache : \(error)")
        }
    }

    enum CacheError: Error {
        case saveFailed(Error)
        case loadFailed(Error)
        case invalidData
        case diskSpaceFull
    }
}
