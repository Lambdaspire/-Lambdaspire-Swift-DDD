
import XCTest
import SwiftData
import LambdaspireAbstractions
import LambdaspireDependencyResolution
import LambdaspireLogging

@testable import LambdaspireSwiftDDD

class BaseTests : XCTestCase {
    
    var modelContext: ModelContext!
    var registrar: DomainEventHandlerRegistrar!
    var unitOfWork: UnitOfWork<ModelContext>!
    var hooks: Hooks!
    
    override func setUp() async throws {
        
        Log.setLogger(PrintLogger())
        
        hooks = .init()
        
        let serviceLocator: ServiceLocator = .init()
        serviceLocator.register(hooks!)
        
        registrar = .init(resolver: serviceLocator)
        
        modelContext = .init(
            try! .init(
                for: TestEntity.self, AnotherTestEntity.self,
                configurations: .init(isStoredInMemoryOnly: true, allowsSave: true)))
        
        unitOfWork = .init(delegator: registrar, context: modelContext)
    }
    
    override func tearDown() {
        hooks.clear()
    }
}
