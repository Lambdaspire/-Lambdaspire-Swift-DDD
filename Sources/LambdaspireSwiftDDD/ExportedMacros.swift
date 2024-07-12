
@attached(member, names: named(events))
@attached(extension, conformances: HasDomainEvents)
// TODO: There's a warning here that doesn't seem to be correct. All the tests pass and usage seems fine here and in dependent projects.
public macro DomainEntity() = #externalMacro(module: "LambdaspireSwiftDDDMacros", type: "DomainEntityMacro")
