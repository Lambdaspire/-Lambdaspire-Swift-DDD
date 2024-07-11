
import SwiftData

extension ModelContext : DomainContext {
    
    public func commit() async throws {
        try save()
    }
    
    public func collectEventRaisers() async throws -> [any HasDomainEvents] {
        // NOTE: This does not cover entities unchanged, not inserted, and not deleted.
        (
            changedModelsArray +
            insertedModelsArray +
            deletedModelsArray
        )
        .compactMap { $0 as? HasDomainEvents }
        .filter { !$0.events.isEmpty }
    }
}
