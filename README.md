# slox C64 tools

A small 6502 assembler and Commodore 64 tooling project written in slox.

## Requirements

- slox 1.13 or newer
- The slox runtime libraries `argparser.lox`, `color.lox`, `multiffi.lox`, and
  `notcurses.lox` on the slox include path

The assembler does not depend on `logger.lox`; the TUI components do.

## Assembler

```sh
slox asm.lox [options] <input.a64>
```

Options:

| Flag | Long form | Description |
| --- | --- | --- |
| `-v` | `--verbose` | Print pipeline details and the symbol table |
| `-o PATH` | `--output PATH` | Set the output `.prg` path |
| `-s` | `--sym` | Write a VICE-compatible `.vs` symbol map |
| `-d` | `--d64` | Package the program into a `.d64` disk image |
| `-l` | `--lst` | Write an annotated `.lst` listing |
| `-D` | `--debug` | Enable debug logging |

Example:

```sh
slox asm.lox -l -s sprite1.a64
```

## Diagnostics

Errors and warnings use a consistent file/line format with the source line and
an optional caret:

```text
sprite1.a64:12: error: Duplicate label 'loop'
  loop:
  ^

sprite1.a64:20: warning: Empty directive '.' encountered.
  .
```

Diagnostics are emitted from every pipeline stage, including the preprocessor,
`.INCLUDE` files, symbol resolving, and output writers. The assembler exits
with a non-zero status before writing output files when any error is reported,
and prints a summary when errors or warnings were seen.

## Supported directives

- `.BASIC` — BASIC SYS header before the machine-code payload
- `.BYTE expr[, expr ...]` — emit byte values or expressions
- `.WORD expr[, expr ...]` — emit 16-bit little-endian values
- `.TEXT "text"` / `.STRING "text"` — emit raw string bytes
- `.ALIGN boundary` — pad to the next boundary
- `.FILL count[, byte]` — emit `count` copies of `byte` (default `$00`)
- `.RES count[, byte]` — reserve bytes, equivalent to `.FILL`
- `.INCBIN "file"[, offset[, length]]` / `.INCLUDEBIN ...` — include raw bytes
- `.INCLUDE "file"` — assemble another source file at this point

Constants can be declared with `NAME = expr`, `NAME EQU expr`, or
`NAME .EQU expr`. The program origin is set with `* = $addr`.

Expressions support decimal, `$hex`, `%binary`, current PC (`*`), symbols,
`<`/`>` byte selectors, and `+`, `-`, and `*`.

## Macros and conditionals

A line-oriented preprocessor runs before the parser. Macros are defined with
`.MACRO name p1, p2 ...` and `.ENDMACRO`, then invoked by name or with a
leading dot:

```asm
.MACRO SETBORDER color
  LDA #color
  STA $D020
.ENDMACRO

  SETBORDER 2
  .SETBORDER 3
```

Parameters are substituted as tokens, so they can stand in for instructions,
operands, or whole directive arguments. Nested macro invocations and
conditionals inside macro bodies are expanded only when their branch is
active. Expansion is limited to 16 nested levels to catch recursion.

Conditional assembly uses `.IF expr`, `.ELSEIF expr`, `.ELSE`, and `.ENDIF`,
plus `.IFDEF name` and `.IFNDEF name`:

```asm
DEBUG = 1

.IF DEBUG
  LDA #$01
.ELSEIF RELEASE
  LDA #$02
.ELSE
  LDA #$03
.ENDIF

.IFDEF TARGET
  .byte TARGET
.ENDIF
```

Constants declared with `=`, `EQU`, or `.EQU` are visible to `.IFDEF` and
`.IFNDEF` after their declaration. Undefined symbols used in `.IF` and
`.ELSEIF` expressions evaluate to `0`; ordinary assembly expressions still
report undefined symbols as errors.

Directive names, macro names, macro parameters, and opcodes are
case-insensitive. Constants, labels, and other symbolic names are
case-sensitive and must match exactly.

## Tests

From this directory:

```sh
./run_tests.sh
```

To use a specific slox binary:

```sh
SLOX_BIN=/path/to/slox ./run_tests.sh
```

The tests write temporary `.prg` and `.d64` files under `/tmp` and do not
depend on generated files in this directory.

## Build workflow

A small `Makefile` wraps the common commands:

```sh
make test                       # run the test suite
make asm SRC=sprite1.a64        # assemble one source to its default .prg
make asm SRC=sprite1.a64 OUT=/tmp/sprite1.prg
make samples                    # assemble sample sources into build/
make clean                      # remove build/
```

Override the interpreter with `SLOX_BIN`, for example
`SLOX_BIN=/path/to/slox make test`. The sample build directory can be changed
with `BUILD_DIR`, and the sample source list with `SOURCES`.
