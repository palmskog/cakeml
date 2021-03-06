The definition of the CakeML language. The definition is (mostly) expressed in
[Lem](https://www.cl.cam.ac.uk/~pes20/lem), but the generated HOL is included.
The directory includes definitions of:
 - the concrete syntax,
 - the abstract syntax,
 - big step semantics (both functional and relational),
 - a small step semantics,
 - the semantics of FFI calls, and,
 - the type system.

The Lem version used: rems-project/lem@194778e97d1e9a41ebbe34a8e4d5fb2d10395ba7

[addancs.sml](addancs.sml):
A script to add a set_grammar_ancestry line to a generated Script.sml file.

[alt_semantics](alt_semantics):
Alternative definitions of the semantics:
  - using inductive relations (as opposed to functional big-step style), and,
  - as a small-step relation.

[ast.lem](ast.lem):
Definition of CakeML abstract syntax (AST).

[astPP.sml](astPP.sml):
Pretty printing for CakeML AST

[astSyntax.sml](astSyntax.sml):
ML functions for manipulating HOL terms and types defined as part of the
CakeML semantics, in particular CakeML abstract syntax.

[cmlPtreeConversionScript.sml](cmlPtreeConversionScript.sml):
Specification of how to convert parse trees to abstract syntax.

[evaluate.lem](evaluate.lem):
Functional big-step semantics for evaluation of CakeML programs.

[ffi](ffi):
Definition of CakeML's observational semantics, in particular traces of calls
over the Foreign-Function Interface (FFI).

[fpSem.lem](fpSem.lem):
Definitions of the floating point operations used in CakeML.

[gramScript.sml](gramScript.sml):
Definition of CakeML's Context-Free Grammar.
The grammar specifies how token lists should be converted to syntax trees.

[grammar.txt](grammar.txt):
Infixes are assigned to 9 different levels.  From tightest to loosest, they are

[lexer_funScript.sml](lexer_funScript.sml):
A functional specification of lexing from strings to token lists.

[namespace.lem](namespace.lem):
Defines a datatype for nested namespaces where names can be either
short (e.g. foo) or long (e.g. ModuleA.InnerB.bar).

[primTypes.lem](primTypes.lem):
Definition of the primitive types that are in scope before any CakeML program
starts. Some of them are generated by running an initial program.

[proofs](proofs):
Theorems about CakeML's syntax and semantics.

[semanticPrimitives.lem](semanticPrimitives.lem):
Definitions of semantic primitives (e.g., values, and functions for doing
primitive operations) used in the semantics.

[semanticPrimitivesSyntax.sml](semanticPrimitivesSyntax.sml):
ML functions for manipulating the HOL terms and types defined in
semanticPrimitivesTheory.

[semanticsScript.sml](semanticsScript.sml):
The top-level semantics of CakeML programs.

[terminationScript.sml](terminationScript.sml):
Termination proofs for functions defined in .lem files whose termination is
not proved automatically.

[tokenUtilsScript.sml](tokenUtilsScript.sml):
Utility functions over tokens.
TODO: perhaps should just appear in tokensTheory.

[tokens.lem](tokens.lem):
The tokens of CakeML concrete syntax.
Some tokens are from Standard ML and not used in CakeML.

[typeSystem.lem](typeSystem.lem):
Specification of CakeML's type system.
