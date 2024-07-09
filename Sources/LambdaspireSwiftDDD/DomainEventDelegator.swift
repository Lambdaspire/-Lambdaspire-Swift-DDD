
import LambdaspireAbstractions

protocol DomainEventDelegator {
    func handle<T: DomainEvent>(event: T) async throws
}

class DomainEventHandlerRegistrar : DomainEventDelegator {
    
    private let resolver: DependencyResolver
    
    private var handlers: [String : [Handler]] = [:]
    
    init(resolver: DependencyResolver) {
        self.resolver = resolver
    }
    
    func register<T: DomainEventHandler>(_ t: T.Type) {
        handlers[T.DomainEventType.typeIdentifier] = (handlers[T.DomainEventType.typeIdentifier] ?? []) + [
            { [weak self] in
                guard let self else { return }
                try await T.handle(event: $0 as! T.DomainEventType, resolver: resolver)
            }
        ]
    }
    
    func handle<T: DomainEvent>(event: T) async throws {
        for handler in handlers[T.typeIdentifier] ?? [] {
            try await handler(event)
        }
    }
}

fileprivate typealias Handler = (Any) async throws -> Void
