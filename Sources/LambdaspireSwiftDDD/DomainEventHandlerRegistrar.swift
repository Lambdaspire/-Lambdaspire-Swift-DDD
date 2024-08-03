
import LambdaspireAbstractions

public class DomainEventHandlerRegistrar : DomainEventDelegator {
    
    private var preCommitHandlers: [String : [Handler]] = [:]
    private var postCommitHandlers: [String : [Handler]] = [:]
    
    public func register<T: DomainEventHandler>(_ t: T.Type) {
        
        func register(_ handlers: inout [String : [Handler]]) {
            
            handlers[T.DomainEventType.typeIdentifier] = (handlers[T.DomainEventType.typeIdentifier] ?? []) + [
                { event, scope in
                    Log.debug(
                        "Handling event {EventType} with handler {EventHandlerType}.", (
                            EventType: T.DomainEventType.typeIdentifier,
                            EventHandlerType: String(describing: T.self)
                        ))
                    // TODO: This is not good, but we don't want to have to double register...
                    let handler: T = scope.tryResolve() ?? T.init(scope: scope)
                    try await handler.handle(event: event as! T.DomainEventType)
                }
            ]
        }
        
        if T.isPostCommit {
            register(&postCommitHandlers)
        } else {
            register(&preCommitHandlers)
        }
        
    }
    
    public func handlePreCommit<T: DomainEvent>(event: T, scope: DependencyResolutionScope) async throws {
        for handler in preCommitHandlers[T.typeIdentifier] ?? [] {
            try await handler(event, scope)
        }
    }
    
    public func handlePostCommit<T: DomainEvent>(event: T, scope: DependencyResolutionScope) async throws {
        for handler in postCommitHandlers[T.typeIdentifier] ?? [] {
            try await handler(event, scope)
        }
    }
}

fileprivate typealias Handler = (Any, any DependencyResolutionScope) async throws -> Void
