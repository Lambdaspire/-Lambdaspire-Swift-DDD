
import LambdaspireAbstractions

public protocol DomainEventDelegator {
    func handlePreCommit<T: DomainEvent>(event: T, scope: DependencyResolutionScope) async throws
    func handlePostCommit<T: DomainEvent>(event: T, scope: DependencyResolutionScope) async throws
}
