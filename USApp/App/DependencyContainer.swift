// Ajout d'un conteneur de dépendances
final class DependencyContainer {
    static let shared = DependencyContainer()
    
    let apiService: APIServiceManager
    let cacheManager: CacheManager
    let notificationManager: NotificationManager
    
    private init() {
        let config = APIServiceManager.Config(
            updateInterval: 300,
            maxRetries: 3,
            cacheTimeout: 3600
        )
        
        self.apiService = APIServiceManager(config: config)
        self.cacheManager = CacheManager()
        self.notificationManager = NotificationManager()
    }
} 