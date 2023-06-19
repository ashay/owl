# ELF Parser in Pure OCaml #

This is a work-in-progress library for reading ELF files.  Once complete, at
minimum, it will allow the user to read the symbol table, associate source code
location information with instruction addresses, etc.


## Goals, In Decreasing Order of Importance ##

 - Get better at writing OCaml and document key lessons
 - Make the library feature complete
 - Make it fast


## Non-Goals, At Least for Now ##

 - Make the code production-ready


## Key Features of this Library ##

 - Uses the `Result` monad (instead of exceptions) for error handling
 - Uses true 64-bit unsigned integer types for uint64 fields, instead of `int64`
 - Checks for buffer overflows before reading bytes
 - Supports both little- and big-endian encoding


## TODO ##

 - Add code to parse section and program headers
 - Setup CI to run test suite


## Acknowledgements ##

 - [let-def/owee](https://github.com/let-def/owee): Owee is an excellent
   library with identical goals, but Owee has limited support for DWARF5.

 - [golang/go](https://github.com/golang/go): I am using the
   [ELF](https://github.com/golang/go/tree/master/src/debug/elf) and
   [DWARF](https://github.com/golang/go/tree/master/src/debug/dwarf) code as
   the reference implementation for my project.

 - [elftoolchain](https://elftoolchain.sourceforge.net): The ELF Toolchain
   project contains a handy elfc script, which generates binary ELF files based
   on a YAML description.


## LICENSE ##

Owl is licensed under
[CC0](https://creativecommons.org/share-your-work/public-domain/cc0).  No rights
reserved.
