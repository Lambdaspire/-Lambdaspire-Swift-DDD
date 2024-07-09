
import SwiftData

class UnitOfWork {
    
    private let delegator: DomainEventDelegator
    private let modelContext: ModelContext
    
    init(delegator: DomainEventDelegator, modelContext: ModelContext) {
        self.delegator = delegator
        self.modelContext = modelContext
    }
    
    func execute(body: @escaping (ModelContext) async throws -> Void) async throws {
        do {
            try await body(modelContext)
            try await save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
    
    func save() async throws {
        
        guard modelContext.hasChanges else {
            return
        }
        
        // TODO: This doesn't cover unchanged models that raise events.
        let withEvents = (
            modelContext.changedModelsArray +
            modelContext.insertedModelsArray +
            modelContext.deletedModelsArray
        )
        .compactMap { $0 as? HasDomainEvents }
        .filter { !$0.events.isEmpty }
        
        let events = withEvents.flatMap { $0.events }
        
        for e in events {
            try await delegator.handle(event: e)
        }
        
        for var w in withEvents {
            w.clearEvents()
        }
        
        try modelContext.save()
    }
}
