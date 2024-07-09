
import XCTest
import SwiftData
import LambdaspireAbstractions
import LambdaspireDependencyResolution

@testable import LambdaspireSwiftDDD

final class LambdaspireSwiftDDDTests: XCTestCase {

    private var modelContext: ModelContext!
    private var unitOfWork: UnitOfWork!
    private var hooks: Hooks!
    
    override func setUp() async throws {
        
        hooks = .init()
        
        let serviceLocator: ServiceLocator = .init()
        serviceLocator.register(Hooks.self, hooks)
        
        let registrar: DomainEventHandlerRegistrar = .init(resolver: serviceLocator)
        registrar.register(TestDomainEventHandler.self)
        
        modelContext = .init(
            try! .init(
                for: TestEntity.self, AnotherTestEntity.self,
                configurations: .init(isStoredInMemoryOnly: true, allowsSave: true)))
        
        unitOfWork = .init(delegator: registrar, modelContext: modelContext)
    }
    
    override func tearDown() {
        hooks.clear()
    }

    func testDomainEventHandlerIsCalled() async throws {
        let id: UUID = .init()
        
        var called = false
        hooks.hook(id: id) {
            called = true
        }
        
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
        
        XCTAssertTrue(called)
        XCTAssertNotNil(entity)
        XCTAssertEqual(count, 1)
    }
    
    func testWhenFailuresOccurTheChangesAreRolledBack() async throws {
        let id: UUID = .init()
        
        do {
            
            try await unitOfWork.execute { c in
                c.insert(TestEntity(id: id))
                throw EmptyError()
            }
            
        } catch {
            
            let entity = try! modelContext.fetch(.init(predicate: #Predicate<TestEntity> {
                $0.id == id
            })).first
            
            let count = try! modelContext.fetchCount(FetchDescriptor<TestEntity>())
            
            XCTAssertNil(entity)
            XCTAssertEqual(count, 0)
        }
    }
}

fileprivate struct EmptyError : Error { }

@Model
class TestEntity : HasDomainEvents {
    
    var id: UUID = UUID()
    
    init(id: UUID) {
        self.id = id
    }
    
    func test() {
        // TODO: Fighting compiler.
        var s = self
        s.raiseEvent(TestDomainEvent(id: id))
    }
    
    // TODO: Can macros help with the repetition?
    @Transient
    var events: [any DomainEvent] = []
}

@Model
class AnotherTestEntity : HasDomainEvents {
    
    var id: UUID = UUID()
    
    init(id: UUID) {
        self.id = id
    }
    
    // TODO: Can macros help with the repetition?
    @Transient
    var events: [any DomainEvent] = []
}

struct TestDomainEvent : DomainEvent {
    var id: UUID
}

struct TestDomainEventHandler : DomainEventHandler {
    static func handle(event: TestDomainEvent, resolver: DependencyResolver) async throws {
        resolver.resolve(Hooks.self).use(id: event.id)
    }
}

// This is pure dirt.
class Hooks {
    
    var hooks: [UUID : () -> Void] = [:]
    
    func use(id: UUID) {
        hooks[id]!()
    }
    
    func hook(id: UUID, fn: @escaping () -> Void) {
        hooks[id] = fn
    }
    
    func hook(fn: @escaping () -> Void) -> UUID {
        let id: UUID = .init()
        hook(id: id, fn: fn)
        return id
    }
    
    func unhook(id: UUID) {
        hooks.removeValue(forKey: id)
    }
    
    func clear() {
        hooks.removeAll()
    }
}
