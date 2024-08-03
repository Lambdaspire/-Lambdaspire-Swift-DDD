
import XCTest
import SwiftData
import LambdaspireAbstractions
import LambdaspireDependencyResolution

@testable import LambdaspireSwiftDDD

class BaseTests : XCTestCase {
    
    var modelContext: ModelContext!
    var registrar: DomainEventHandlerRegistrar!
    var unitOfWork: UnitOfWork<ModelContext>!
    var hooks: Hooks!
    
    override func setUp() async throws {
        
        let builder: ContainerBuilder = .init()
        
        builder.singleton(Hooks.init)
        builder.singleton(ModelContext.self) {
            .init(
                try! .init(
                    for: TestEntity.self, AnotherTestEntity.self,
                    configurations: .init(isStoredInMemoryOnly: true, allowsSave: true)))
        }
        builder.singleton(DomainEventHandlerRegistrar.init)
        builder.singleton(DomainEventDelegator.self, assigned(DomainEventHandlerRegistrar.self))
        builder.transient(UnitOfWorkFactory<ModelContext>.self)
        builder.transient(DependencyResolutionScope.self) { $0 }
        
        let container = builder.build()
        
        modelContext = container.resolve()
        registrar = container.resolve()
        hooks = container.resolve()
        unitOfWork = container.resolve(UnitOfWorkFactory<ModelContext>.self).create()
    }
}

// TODO: It seems like @Resolvable serves better in Abstractions.
@Resolvable
class UnitOfWorkFactory<Context: DomainContext> {
    
    private let delegator: DomainEventDelegator
    private let context: Context
    private let scope: DependencyResolutionScope
    
    func create() -> UnitOfWork<Context> {
        .init(delegator: delegator, context: context, scope: scope)
    }
}
