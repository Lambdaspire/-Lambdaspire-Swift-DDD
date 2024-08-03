
import LambdaspireAbstractions

public protocol DomainEventHandler : Resolvable {
    
    associatedtype DomainEventType : DomainEvent
    
    static var isPostCommit: Bool { get }
    
    func handle(event: DomainEventType) async throws
}

public extension DomainEventHandler {
    static var isPostCommit: Bool { false }
}
