
import XCTest
import SwiftData
import LambdaspireAbstractions
import LambdaspireDependencyResolution
import LambdaspireLogging

@testable import LambdaspireSwiftDDD

final class LambdaspireSwiftDDDTests: XCTestCase {

    private var modelContext: ModelContext!
    private var registrar: DomainEventHandlerRegistrar!
    private var unitOfWork: UnitOfWork<ModelContext>!
    private var hooks: Hooks!
    
    override func setUp() async throws {
        
        Log.setLogger(PrintLogger())
        
        hooks = .init()
        
        let serviceLocator: ServiceLocator = .init()
        serviceLocator.register(hooks!)
        
        registrar = .init(resolver: serviceLocator)
        registrar.register(TestPreCommitDomainEventHandler.self)
        registrar.register(TestPostCommitDomainEventHandler.self)
        
        modelContext = .init(
            try! .init(
                for: TestEntity.self, AnotherTestEntity.self,
                configurations: .init(isStoredInMemoryOnly: true, allowsSave: true)))
        
        unitOfWork = .init(delegator: registrar, context: modelContext)
    }
    
    override func tearDown() {
        hooks.clear()
    }

    func test_HappyPath_ChangesAreCommitted_And_DomainEventHandlersAreCalled() async throws {
        let id: UUID = .init()
        
        let calledPreCommit = hooks.hook("PreCommit", value: false) { $0 = true }
        let calledPostCommit = hooks.hook("PostCommit", value: false) { $0 = true }
        
        try await unitOfWork.execute { c in
            
            let t: TestEntity = .init(id: id)
            t.test()
            c.insert(t)
            
            let at: AnotherTestEntity = .init(id: id)
            c.insert(at)
        }
        
        let entity = try! modelContext.fetch(.init(predicate: #Predicate<TestEntity> {
            $0.id == id
        })).first
        
        let count = try! modelContext.fetchCount(FetchDescriptor<TestEntity>())
        
        XCTAssertNotNil(entity)
        XCTAssertEqual(count, 1)
        XCTAssertTrue(calledPreCommit.value)
        XCTAssertTrue(calledPostCommit.value)
    }
    
    func test_WhenUnitOfWorkExecutionFailuresOccur_ChangesAreRolledBack_And_HandlersAreNotCalled() async throws {
        let id: UUID = .init()
        
        let calledPreCommit = hooks.hook("PreCommit", value: false) { $0 = true }
        let calledPostCommit = hooks.hook("PostCommit", value: false) { $0 = true }
        
        do {
            
            try await unitOfWork.execute { c in
                
                let t: TestEntity = .init(id: id)
                t.test()
                c.insert(t)
                
                throw EmptyError()
            }
            
        } catch { }
        
        let entity = try! modelContext.fetch(.init(predicate: #Predicate<TestEntity> {
            $0.id == id
        })).first
        
        let count = try! modelContext.fetchCount(FetchDescriptor<TestEntity>())
        
        XCTAssertNil(entity)
        XCTAssertEqual(count, 0)
        XCTAssertFalse(calledPreCommit.value)
        XCTAssertFalse(calledPostCommit.value)
    }
    
    func test_WhenPreCommitHandlerFailuresOccur_ChangesAreRolledBack_And_PostCommitHandlersAreNotCalled() async throws {
        
        registrar.register(TestThrowingPreCommitDomainEventHandler.self)
        
        let id: UUID = .init()
        
        let calledPreCommit = hooks.hook("PreCommit", value: false) { $0 = true }
        let calledThrowingPreCommit = hooks.hook("ThrowingPreCommit", value: false) { $0 = true }
        let calledPostCommit = hooks.hook("PostCommit", value: false) { $0 = true }
        
        do {
            
            try await unitOfWork.execute { c in
                
                let t: TestEntity = .init(id: id)
                t.test()
                c.insert(t)
            }
            
        } catch { }
        
        XCTAssertTrue(calledPreCommit.value)
        XCTAssertTrue(calledThrowingPreCommit.value)
        XCTAssertFalse(calledPostCommit.value)
    }
} 
