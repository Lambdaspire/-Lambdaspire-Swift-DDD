
import XCTest
import SwiftData

@testable import LambdaspireSwiftDDD

final class HappyPathTests : BaseTests {
    
    override func setUp() async throws {
        try await super.setUp()
        
        registrar.register(TestPreCommitDomainEventHandler.self)
        registrar.register(TestPostCommitDomainEventHandler.self)
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
}
