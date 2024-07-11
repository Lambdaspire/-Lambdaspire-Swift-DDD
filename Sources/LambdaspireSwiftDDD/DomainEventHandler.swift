
import LambdaspireAbstractions

public protocol DomainEventHandler {
    
    associatedtype DomainEventType : DomainEvent
    
    static var isPostCommit: Bool { get }
    
    static func handle(
        event: DomainEventType,
        resolver: DependencyResolver) async throws
}

public extension DomainEventHandler {
    static var isPostCommit: Bool { false }
}
