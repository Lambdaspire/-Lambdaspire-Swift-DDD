
import LambdaspireSwiftDDD
import LambdaspireAbstractions
import LambdaspireDependencyResolution

@Resolvable
class TestPreCommitDomainEventHandler : DomainEventHandler {
    
    private let hooks: Hooks
    
    init(hooks: Hooks) {
        self.hooks = hooks
    }
    
    func handle(event: TestDomainEvent) async throws {
        hooks.use("PreCommit")
    }
}

@Resolvable
class TestPostCommitDomainEventHandler : DomainEventHandler {
    
    static var isPostCommit: Bool { true }
    
    private let hooks: Hooks
    
    func handle(event: TestDomainEvent) async throws {
        hooks.use("PostCommit")
    }
}

@Resolvable
class TestThrowingPreCommitDomainEventHandler : DomainEventHandler {
    
    var hooks: Hooks
    
    func handle(event: TestDomainEvent) async throws {
        hooks.use("ThrowingPreCommit")
        throw EmptyError()
    }
}
