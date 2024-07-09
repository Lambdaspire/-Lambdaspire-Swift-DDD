
import LambdaspireAbstractions

protocol DomainEventHandler {
    
    associatedtype DomainEventType : DomainEvent
    
    static func handle(
        event: DomainEventType,
        resolver: DependencyResolver) async throws
}
