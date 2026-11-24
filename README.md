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
