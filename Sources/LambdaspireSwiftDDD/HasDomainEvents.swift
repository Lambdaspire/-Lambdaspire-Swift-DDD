
// TODO: Can macros help with the repetition?

protocol HasDomainEvents {
    var events: [any DomainEvent] { get set }
}

extension HasDomainEvents {
    
    mutating func clearEvents() {
        events = []
    }
    
    mutating func raiseEvent<T: DomainEvent>(_ event: T) {
        events.append(event)
    }
}
