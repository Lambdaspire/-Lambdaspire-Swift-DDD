
import LambdaspireAbstractions

public struct UnitOfWork<TContext : DomainContext> {
    
    var delegator: DomainEventDelegator
    var context: TContext
    var scope: DependencyResolutionScope
    
    public init(delegator: DomainEventDelegator, context: TContext, scope: DependencyResolutionScope) {
        self.delegator = delegator
        self.context = context
        self.scope = scope
    }
    
    public func execute(body: @escaping (TContext) async throws -> Void) async throws {
        
        do {
            
            Log.debug("Executing body in UnitOfWOrk.")
            
            try await body(context)
            
            Log.debug("Executing pre-commit domain event handlers in UnitOfWOrk.")
            
            let raisers = try await context.collectEventRaisers()
            
            defer {
                Log.debug("Clearing domain events from entities.")
                for r in raisers {
                    r.clearEvents()
                }
            }
            
            let events = raisers.flatMap { $0.events }
            
            for e in events {
                do {
                    try await delegator.handlePreCommit(event: e, scope: scope)
                } catch {
                    Log.error(error, "An error occurred handling event {EventType} with pre-commit handler.", (
                        EventType: type(of: e).typeIdentifier,
                        EventData: e
                    ))
                    
                    throw error
                }
            }
            
            Log.debug("Committing in UnitOfWOrk.")
            
            try await context.commit()
            
            Log.debug("Executing post-commit domain event handlers in UnitOfWOrk.")
            
            for e in events {
                do {
                    try await delegator.handlePostCommit(event: e, scope: scope)
                } catch {
                    Log.error(error, "An error occurred handling post-commit event {EventType}.", (
                        EventType: type(of: e).typeIdentifier,
                        EventData: e
                    ))
                }
            }
            
        } catch {
            
            Log.error(error, "An error occurred executing UnitOfWork.")
            
            try await context.rollback()
            
            throw error
        }
        
        Log.debug("Finished executing UnitOfWOrk.")
    }
}
