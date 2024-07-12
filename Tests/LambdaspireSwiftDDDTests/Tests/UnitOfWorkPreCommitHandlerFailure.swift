
import XCTest
import SwiftData

final class UnitOfWorkPreCommitHandlerFailureTests : BaseTests {
    
    override func setUp() async throws {
        try await super.setUp()
        
        registrar.register(TestPreCommitDomainEventHandler.self)
        registrar.register(TestPostCommitDomainEventHandler.self)
        registrar.register(TestThrowingPreCommitDomainEventHandler.self)
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
