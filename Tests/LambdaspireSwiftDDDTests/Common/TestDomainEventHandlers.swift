
import LambdaspireSwiftDDD
import LambdaspireAbstractions

struct TestPreCommitDomainEventHandler : DomainEventHandler {
    static func handle(event: TestDomainEvent, resolver: DependencyResolver) async throws {
        resolver.resolve(Hooks.self).use("PreCommit")
    }
}

struct TestPostCommitDomainEventHandler : DomainEventHandler {
    
    static var isPostCommit: Bool { true }
    
    static func handle(event: TestDomainEvent, resolver: DependencyResolver) async throws {
        resolver.resolve(Hooks.self).use("PostCommit")
    }
}

struct TestThrowingPreCommitDomainEventHandler : DomainEventHandler {
    static func handle(event: TestDomainEvent, resolver: DependencyResolver) async throws {
        resolver.resolve(Hooks.self).use("ThrowingPreCommit")
        throw EmptyError()
    }
}
