
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(LambdaspireSwiftDDDMacros)
import LambdaspireSwiftDDDMacros

let testMacros: [String: Macro.Type] = [
    "DomainEntity": DomainEntityMacro.self
]
#endif

final class LambdaspireSwiftDDDMacrosTests : XCTestCase {
    
    func test_DomainEntityMacro_ProducesExpectedExpansion() throws {
        #if canImport(LambdaspireSwiftDDDMacros)
        assertMacroExpansion(
            """
            @DomainEntity
            class Test {
                let something: String
            
                init(something: String) {
                    self.something = something
                }
            }
            """,
            expandedSource: """
            
            class Test {
                let something: String
            
                init(something: String) {
                    self.something = something
                }
            
                @Transient var events: [any DomainEvent] = []
            }
            
            extension Test : HasDomainEvents {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
