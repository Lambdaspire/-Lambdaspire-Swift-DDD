
import LambdaspireAbstractions

public class DomainEventHandlerRegistrar : DomainEventDelegator {
    
    private let resolver: DependencyResolver
    
    private var preCommitHandlers: [String : [Handler]] = [:]
    private var postCommitHandlers: [String : [Handler]] = [:]
    
    public init(resolver: DependencyResolver) {
        self.resolver = resolver
    }
    
    public func register<T: DomainEventHandler>(_ t: T.Type) {
        
        func register(_ handlers: inout [String : [Handler]]) {
            handlers[T.DomainEventType.typeIdentifier] = (handlers[T.DomainEventType.typeIdentifier] ?? []) + [
                { [weak self] in
                    guard let self else { return }
                    try await T.handle(event: $0 as! T.DomainEventType, resolver: resolver)
                }
            ]
        }
        
        if T.isPostCommit {
            register(&postCommitHandlers)
        } else {
            register(&preCommitHandlers)
        }
        
    }
    
    public func handlePreCommit<T: DomainEvent>(event: T) async throws {
        for handler in preCommitHandlers[T.typeIdentifier] ?? [] {
            try await handler(event)
        }
    }
    
    public func handlePostCommit<T: DomainEvent>(event: T) async throws {
        for handler in postCommitHandlers[T.typeIdentifier] ?? [] {
            try await handler(event)
        }
    }
}

fileprivate typealias Handler = (Any) async throws -> Void
