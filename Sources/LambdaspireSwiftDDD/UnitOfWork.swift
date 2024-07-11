
import LambdaspireAbstractions
import SwiftData

public class UnitOfWork<TContext : DomainContext> {
    
    private let delegator: DomainEventDelegator
    private let context: TContext
    
    public init(delegator: DomainEventDelegator, context: TContext) {
        self.delegator = delegator
        self.context = context
    }
    
    public func execute(body: @escaping (TContext) async throws -> Void) async throws {
        
        do {
            
            try await body(context)
            
            let raisers = try await context.collectEventRaisers()
            
            defer {
                for var r in raisers {
                    r.clearEvents()
                }
            }
            
            let events = raisers.flatMap { $0.events }
            
            for e in events {
                do {
                    try await delegator.handlePreCommit(event: e)
                } catch {
                    Log.error(error, "An error occurred handling pre-commit event {EventType}.", (
                        EventType: type(of: e).typeIdentifier,
                        EventData: e
                    ))
                    
                    throw error
                }
            }
            
            try await context.commit()
            
            for e in events {
                do {
                    try await delegator.handlePostCommit(event: e)
                } catch {
                    Log.error(error, "An error occurred handling post-commit event {EventType}.", (
                        EventType: type(of: e).typeIdentifier,
                        EventData: e
                    ))
                }
            }
            
        } catch {
            
            Log.error(error, "An error occurred committing UnitOfWork.")
            
            try await context.rollback()
            
            throw error
        }
    }
}
