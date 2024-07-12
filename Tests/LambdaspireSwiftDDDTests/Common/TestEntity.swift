
import LambdaspireSwiftDDD
import LambdaspireSwiftDDDMacros
import SwiftData
import Foundation

@Model
@DomainEntity
class TestEntity {
    
    var id: UUID = UUID()
    
    init(id: UUID) {
        self.id = id
    }
    
    func test() {
        raiseEvent(TestDomainEvent(id: id))
    }
}

struct TestDomainEvent : DomainEvent {
    var id: UUID
}

@Model
@DomainEntity
class AnotherTestEntity {
    
    var id: UUID = UUID()
    
    init(id: UUID) {
        self.id = id
    }
}
