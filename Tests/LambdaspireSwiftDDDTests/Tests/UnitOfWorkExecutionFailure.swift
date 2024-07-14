
import XCTest
import SwiftData

final class UnitOfWorkExecutionFailureTests : BaseTests {
    
    override func setUp() async throws {
        try await super.setUp()
        
        registrar.register(TestPreCommitDomainEventHandler.self)
        registrar.register(TestPostCommitDomainEventHandler.self)
    }
    
    func test_WhenUnitOfWorkExecutionFailuresOccur_ChangesAreRolledBack_And_HandlersAreNotCalled() async throws {
        let id: UUID = .init()
        
        let calledPreCommit = hooks.hook("PreCommit", value: false) { $0 = true }
        let calledPostCommit = hooks.hook("PostCommit", value: false) { $0 = true }
            
        try? await unitOfWork.execute { c in
            
            let t: TestEntity = .init(id: id)
            t.test()
            c.insert(t)
            
            throw EmptyError()
        }
        
        let entity = try! modelContext.fetch(.init(predicate: #Predicate<TestEntity> {
            $0.id == id
        })).first
        
        let count = try! modelContext.fetchCount(FetchDescriptor<TestEntity>())
        
        XCTAssertNil(entity)
        XCTAssertEqual(count, 0)
        XCTAssertFalse(calledPreCommit.value)
        XCTAssertFalse(calledPostCommit.value)
    }
}
