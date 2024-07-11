
public protocol DomainEventDelegator {
    func handlePreCommit<T: DomainEvent>(event: T) async throws
    func handlePostCommit<T: DomainEvent>(event: T) async throws
}
