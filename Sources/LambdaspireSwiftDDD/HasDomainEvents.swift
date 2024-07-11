
// TODO: Can macros help with the repetition?

public protocol HasDomainEvents : AnyObject {
    var events: [any DomainEvent] { get set }
}

extension HasDomainEvents {
    
    public func clearEvents() {
        events = []
    }
    
    public func raiseEvent<T: DomainEvent>(_ event: T) {
        events.append(event)
    }
}
