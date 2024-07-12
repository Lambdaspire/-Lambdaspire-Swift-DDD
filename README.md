# Lambdaspire Swift DDD

Helps you write more Domain Driven Design (DDD) style code with SwiftData.

## Domain Events

Allows you to decouple side-effects from their source. You can define pre-commit and post-commit domain event handlers. The former execute before changes are saved and may rollback the transaction. The latter execute after changes are saved and fail more gracefully.

### How to hold it

Define your SwiftData models as usual using the `@Model` macro.

If your models (entities) raise domain events you want to handle, you should also apply the `@DomainEntity` macro. This will add the necessary conformances that allow you to raise events using `raiseEvent(...)` and have the events handled (described later).

```swift
@Model
@DomainEntity
class Employee {
    
    // ...
    
    func youreHired() {
        raiseEvent(EmployeeHiredEvent(employeeId: myId))
    } 
}
```

All this does is generate the necessary code to conform to the `HasDomainEvents` protocol. You could do it manually (not recommended):

<details>
<summary><strong>Aside: How to manually implement <code>HasDomainEvents</code>.</strong></summary>

Conform your model to the `HasDomainEvents` protocol with `@Transient var events: [any DomainEvent] = []`. It must be transient, otherwise SwiftData will attempt to persist the events to storage.

```swift
@Model
class Employee : HasDomainEvents {

    // ... 
    
    @Transient var events: [any DomainEvent] = []
}
```
</details>

<br/>

Define your domain events as simple structs conforming to `DomainEvent`. It's best if the domain events are lightweight, used for data transfer only.

```swift
struct EmployeeHiredEvent : DomainEvent {
    var employeeId: UUID
}
```

Define your domain event handlers as structs conforming to `DomainEventHandler`.

Handlers which should fire before data is committed to storage are the simplest.

```swift
struct When_EmployeeHired_AssignThemABuddy : DomainEventHandler {
    
    static func handle(event: TestDomainEvent, resolver: DependencyResolver) async throws {
        try await resolver
            .resolve(BuddySystem.self)
            .assignBuddyToEmployee(id: event.employeeId)
    }
}
```

Handlers which should fire after data is committed to storage should override the default implementation of `isPostCommit` with one that returns `true`.

```swift
struct When_EmployeeHired_SendThemAWelcomePackage : DomainEventHandler {
    
    static var isPostCommit: Bool { true }
    
    static func handle(event: TestDomainEvent, resolver: DependencyResolver) async throws {
        try await resolver
            .resolve(HumanResources.self)
            .requestWelcomePackageForEmployee(id: event.employeeId)
    }
}
```

The handlers need to be registered with an object that will ultimately be used to delegate events to their respective handlers. Use `DomainEventHandlerRegistrar` for this.

```swift
let resolver: DependencyResolver = SomeImplementation()
let registrar: DomainEventHandlerRegistrar = .init(resolver: resolver)
registrar.register(When_EmployeeHired_AssignThemABuddy.self)
registrar.register(When_EmployeeHired_SendThemAWelcomePackage.self)
```

The component that ties all this together is the `UnitOfWork`. It takes any `DomainEventDelegator` (which `DomainEventHandlerRegistrar` conforms to) and a generic `TContext`, which in most circumstances will be a SwiftData `ModelContext`. With it, you can execute contained bodies of work that may trigger Domain Events, and those events will be handled accordingly.

```swift
let uow: UnitOfWork<ModelContext> = .init(delegator: registrar, context: modelContext)

uow.execute { context in 

    let employee: Employee = .init(name: "Skylark")
    employee.youreHired() // Event raised here.
    context.insert(employee)
    
}
```

## Appendix

### More about Domain Event Handlers

Pre-commit handlers fire after the `execute` body finishes and before `context.commit()` is called. If any pre-commit handlers fail, the entire unit of work is aborted and changes are rolled back with `context.rollback()`.

Post-commit handlers fire after a successful commit. Any post-commit handler can fail without disrupting the execution of other post-commit handlers.

### Logging

There is some light logging implemented using the static `Log` from `Lambdaspire-Swift-Abstractions`. To see the logs, make sure you set up the logger with something that implements `LambdaspireSwiftLogging.Logger`. You may find the [`Lambdaspire-Swift-Logging`](https://github.com/Lambdaspire/Lambdaspire-Swift-Logging) package helpful (though, at time of writing, it leaves much to be desired).

```swift
import LambdaspireAbstractions
import LambdaspireLogging

// Log to console.
Log.setLogger(PrintLogger())
```

### Complete, Working Code Example

```swift

import SwiftUI
import SwiftData
import LambdaspireLogging
import LambdaspireSwiftDDD
import LambdaspireAbstractions
import LambdaspireDependencyResolution

// MARK: Resolver and Delegator setup

// NOTE:
// It is not ideal to declare the resolver and delegator as global singletons.
// It is, however, convenient for this example.

let resolver: ServiceLocator = {
    let s: ServiceLocator = .init()
    s.register(Police())
    s.register(IT())
    s.register(HR())
    s.register(Legal())
    return s
}()

let delegator: DomainEventHandlerRegistrar = {
    let d: DomainEventHandlerRegistrar = .init(resolver: resolver)
    d.register(When_EmployeeWasFired_PrepareLegally.self)
    d.register(When_EmployeeWasFired_RevokeAllAccess.self)
    d.register(When_EmployeeWasFired_DestroyAllTheEvidence.self)
    d.register(When_EmployeeWasHired_PerformPoliceCheck.self)
    return d
}()

// MARK: App

@main
struct LambdaspireSwiftDDDExampleApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Employee.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: View

struct ContentView: View {
    
    @State private var displayedError: DomainError?
    
    @Query private var employees: [Employee]
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(employees) { e in
                    NavigationLink {
                        Text(verbatim: e.name)
                    } label: {
                        LabeledContent(e.name, value: e.isFired ? "Fired" : "Employed")
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            fire(e)
                        } label: {
                            Text("Fire")
                        }
                        .tint(.red)
                    }
                }
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
                ToolbarItem {
                    Button(action: addEmployee) {
                        Text("Recruit Random Person")
                    }
                }
            }
        } detail: {
            Text("Select an Employee")
        }
        .alert(
            isPresented: .init(
                get: { displayedError != nil },
                set: { if !$0 { displayedError = nil } }
            ),
            error: displayedError) { _ in
                Button("OK") { }
            } message: { e in
                Text(e.localizedDescription)
            }

    }
    
    var unitOfWork: UnitOfWork<ModelContext> {
        // HACK: ModelContext autosaves. This seems difficult to override in SwiftUI ModelContexts injected via @Environment.
        modelContext.autosaveEnabled = false
        return .init(delegator: delegator, context: modelContext)
    }

    private func addEmployee() {
        Task.detached {
            do {
                try await unitOfWork.execute { c in
                    let employee = Employee()
                    try employee.getHired()
                    c.insert(employee)
                }
            } catch let error as DomainError {
                displayedError = error
            } catch {
                // Uh oh.
            }
        }
    }

    private func fire(_ employee: Employee) {
        Task.detached {
            do {
                try await unitOfWork.execute { c in
                    try employee.getFired()
                }
            } catch let error as DomainError {
                displayedError = error
            } catch {
                // Uh oh.
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Employee.self, inMemory: true, isAutosaveEnabled: false)
}

// MARK: Domain

@Model
@DomainEntity
final class Employee {
    
    var uuid: UUID = UUID()
    var name: String = ""
    var isInducted: Bool = false
    var isFired: Bool = false
    
    init(uuid: UUID = .init(), name: String = names.randomElement()!, isInducted: Bool = false, isFired: Bool = false) {
        self.uuid = uuid
        self.name = name
        self.isInducted = isInducted
        self.isFired = isFired
    }
    
    func getHired() throws {
        
        guard !isInducted else {
            throw DomainError("I've been here for a long time.")
        }
        
        isInducted = true
        
        raiseEvent(EmployeeWasHired(name: name))
    }
    
    func getFired() throws {
        
        guard !isFired else {
            throw DomainError("You can't fire me! I'm already fired!")
        }
        
        isFired = true
        
        raiseEvent(EmployeeWasFired(employeeId: uuid))
    }
}

struct EmployeeWasFired : DomainEvent {
    var employeeId: UUID
}

struct EmployeeWasHired : DomainEvent {
    var name: String
}

struct When_EmployeeWasHired_PerformPoliceCheck : DomainEventHandler {
    
    static func handle(event: EmployeeWasHired, resolver: any DependencyResolver) async throws {
        // As this is a pre-commit handler,
        // And the background check throws a DomainError if it fails,
        // A failure here will prevent the employee being persisted.
        try await resolver
            .resolve(Police.self)
            .backgroundCheck(name: event.name)
    }
}

struct When_EmployeeWasFired_RevokeAllAccess : DomainEventHandler {
    
    static var isPostCommit: Bool { true }
    
    static func handle(event: EmployeeWasFired, resolver: any DependencyResolver) async throws {
        resolver
            .resolve(IT.self)
            .revokeAllAccess(employeeId: event.employeeId)
    }
}

struct When_EmployeeWasFired_DestroyAllTheEvidence : DomainEventHandler {
    
    static var isPostCommit: Bool { true }
    
    static func handle(event: EmployeeWasFired, resolver: any DependencyResolver) async throws {
        resolver
            .resolve(HR.self)
            .destroyAllTheEvidence(employeeId: event.employeeId)
    }
}

struct When_EmployeeWasFired_PrepareLegally : DomainEventHandler {
    
    static var isPostCommit: Bool { true }
    
    static func handle(event: EmployeeWasFired, resolver: any DependencyResolver) async throws {
        resolver
            .resolve(Legal.self)
            .cya(employeeId: event.employeeId)
    }
}

class IT {
    func revokeAllAccess(employeeId: UUID) {
        print("sudo revoko accesso -f")
    }
}

class HR {
    func destroyAllTheEvidence(employeeId: UUID) {
        print("I'm sorry, IT must have accidentally deleted all your emails.")
    }
}

class Legal {
    func cya(employeeId: UUID) {
        print("The law isn't exacty black and white on this, so we should be fine.")
    }
}

class Police {
    func backgroundCheck(name: String) async throws {
        if Bool.random() {
            throw DomainError("\(name) is a wanted criminal who escaped from prison so we have rejected their application.")
        }
    }
}

struct DomainError : LocalizedError {
    
    private var message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    public var errorDescription: String? { message }
}


// MARK: Stuff

let names = [
    "Jim",
    "Jone",
    "Jackie",
    "John",
    "Jane",
    "Jill",
    "Julian",
    "Jules",
    "Jen",
    "Jasper",
    "Jacko",
    "Jerry"
]

```
