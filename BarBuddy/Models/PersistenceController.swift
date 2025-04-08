//
//
//  BarBuddy
//

import CoreData

/**
 * Manages CoreData persistence for the app.
 *
 * This class handles the Core Data stack setup and provides
 * convenience methods for saving and retrieving data.
 */
struct PersistenceController {
    /// Shared singleton instance
    static let shared = PersistenceController()
    
    /// The Core Data persistent container
    let container: NSPersistentContainer
    
    /**
     * Initializes the persistence controller with optional in-memory storage.
     *
     * - Parameter inMemory: If true, data is stored in memory only (for testing)
     */
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "BarBuddy")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    /**
     * Saves changes in the view context if there are any.
     *
     * This should be called after making changes to entities to persist them.
     */
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    /**
     * Creates a preview controller for SwiftUI previews.
     */
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        
        // Add sample data for previews here
        let context = controller.container.viewContext
        
        // Example: Create a sample user profile
        let profile = CDUserProfile(context: context)
        profile.id = UUID()
        profile.weight = 160.0
        profile.genderRaw = "Male"
        
        // Save the context
        try? context.save()
        
        return controller
    }()
}
