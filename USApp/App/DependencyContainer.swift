// Ajout d'un conteneur de dépendances
final class DependencyContainer {
    static let shared = DependencyContainer()
    
    let apiService: APIServiceManager
    let cacheManager: CacheManager
    let notificationManager: NotificationManager
    
    private init() {
        // Utiliser les instances partagées
        self.apiService = APIServiceManager.shared
        self.cacheManager = CacheManager()
        self.notificationManager = NotificationManager.shared
        
        // Configurer après l'initialisation
        let config = APIServiceManager.Config(
            updateInterval: 300,
            maxRetries: 3,
            cacheTimeout: 3600
        )
        self.apiService.configure(with: config)
    }
} 