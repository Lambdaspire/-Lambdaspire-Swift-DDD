
import LambdaspireSwiftDDD
import SwiftData
import Foundation

@Model
class TestEntity : HasDomainEvents {
    
    var id: UUID = UUID()
    
    init(id: UUID) {
        self.id = id
    }
    
    func test() {
        raiseEvent(TestDomainEvent(id: id))
    }
    
    // TODO: Can macros help with the repetition?
    @Transient
    var events: [any DomainEvent] = []
}

struct TestDomainEvent : DomainEvent {
    var id: UUID
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
