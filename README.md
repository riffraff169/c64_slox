# slox C64 tools

A small 6502 assembler and Commodore 64 tooling project written in slox.

## Requirements

- slox 1.13 or newer
- The slox runtime libraries `argparser.lox`, `color.lox`, `multiffi.lox`, and
  `notcurses.lox` on the slox include path
- For the Cairo editor: the runtime libraries `canvas.lox`, `cairo.lox`, and
  `x11.lox`, plus libcairo and X11 at runtime

The assembler does not depend on `logger.lox`; the notcurses TUI components do.

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
slox asm.lox -l -s constants.a64
```

## Diagnostics

Errors and warnings use a consistent file/line format with the source line and
an optional caret:

```text
constants.a64:12: error: Duplicate label 'loop'
  loop:
  ^

constants.a64:20: warning: Empty directive '.' encountered.
  .
```

Diagnostics are emitted from every pipeline stage, including the preprocessor,
`.INCLUDE` files, symbol resolving, and output writers. The assembler exits
with a non-zero status before writing output files when any error is reported,
and prints a summary when errors or warnings were seen.

## Sprite editors

### Cairo/X11 editor

```sh
slox cse_main.lox
slox cse_main.lox --sprite sprite.bin
slox cse_main.lox --png editor.png --sprite sprite.bin
```

`cse_main.lox` opens a 960x720 Cairo canvas. `--sprite` loads an existing
64-byte raw sprite binary at startup, and `--png` renders one offscreen frame
without opening an X11 window. The editor panel provides mode switching,
pattern selection, save/load dialogs, clear, and quit.

Controls:

- Click the canvas to paint; click a pattern row to select it
- `M` switches between single-color and multicolor mode
- `1`-`4` select a pattern (`3` and `4` are multicolor only)
- `P` or the Colors button opens the color picker for the active multicolor pattern
- In multicolor mode, clicking the same pattern row in the list twice opens its
  color picker; pattern `00` has no color picker
- Clicking sprite cells only paints; it never opens the color picker
- `S` / `L` open the save/load filename dialog
- `C` clears the sprite, `Q` or `Esc` quits

Saved sprites use the C64 layout: three bytes per row for 21 rows plus one
padding byte. Single-color mode packs eight 1-bit pixels per byte. Multicolor
mode packs four 2-bit horizontal pixel pairs per byte. Switching modes
converts existing pixels: adjacent single-color bits become multicolor
patterns (on/blank becomes `10: Primary`), and switching back restores the
individual bits. The window redraws only when editor state changes; canvas
clicks update just the affected sprite/preview cells, expose events redraw only
the reported region, and dialog typing updates just the filename field.

The color picker offers the 16 standard C64 colors for patterns `01`, `10`, and
`11`. Click a swatch to apply it, or use the arrow keys and `Enter`. Clicking
outside the picker or pressing `Esc` closes it without applying a color. Color
choices only affect the editor preview: saved sprites contain bit patterns only,
and the colors are defined by the program that displays them.

The original notcurses editor is unchanged and remains available through
`slox se_main.lox`.

## Supported directives

- `.BASIC` - BASIC SYS header before the machine-code payload
- `.BYTE expr[, expr ...]` - emit byte values or expressions
- `.WORD expr[, expr ...]` - emit 16-bit little-endian values
- `.TEXT "text"` / `.STRING "text"` - emit raw string bytes
- `.PET "text"` - emit PETSCII bytes; uppercase letters are `$41`-`$5A` and
  lowercase letters are `$61`-`$7A`
- `.SCREEN "text"` - emit screen codes for direct screen memory; uppercase and
  lowercase letters both become `$01`-`$1A`, and `@` becomes `$00`
- `.ALIGN boundary` - pad to the next boundary
- `.FILL count[, byte]` - emit `count` copies of `byte` (default `$00`)
- `.RES count[, byte]` - reserve bytes, equivalent to `.FILL`
- `.INCBIN "file"[, offset[, length]]` / `.INCLUDEBIN ...` - include raw bytes
- `.INCLUDE "file"` - assemble another source file at this point
- `.ASSERT condition[, "message"]` - fail assembly when `condition` is `0`

Constants can be declared with `NAME = expr`, `NAME EQU expr`, or
`NAME .EQU expr`. The program origin is set with `* = $addr`.

Expressions support decimal, `$hex`, `%binary`, current PC (`*`), symbols,
`<`/`>` byte selectors, `+`, `-`, `*`, `%` modulo, and `==` equality. Equality
returns `1` when both sides match and `0` otherwise.

Pass 1 starts by assuming that unknown forward operands can use zero page, then
repeats until symbol addresses and instruction sizes settle. This prefers the
smallest stable layout. If an operand's value moves outside `$00-$FF` because
the instruction itself changed size, it is promoted to absolute. If that value
would flip back and forth, the operand is fixed to absolute so assembly
terminates.

```asm
* = $0020
  LDA later       ; emits A5 23 when later lands at $0023
  RTS
later:
```

A label exactly at the zero-page boundary keeps the two-byte form:

```asm
* = $00FC
  LDA later       ; emits A5 FF, not AD FF 00
  RTS
later:            ; $00FF
```

Use `.ASSERT` to enforce layout rules such as sprite alignment. Put the label
on its own line after `.ALIGN` so it receives the aligned address:

```asm
* = $0840
  .align 64
sprite_data:
  .assert sprite_data % 64 == 0, "sprite data must be 64-byte aligned"
  .fill 64, $00
```

## Undocumented 6510 opcodes

The assembler accepts these stable undocumented NMOS 6510 mnemonics. They are
not part of the documented 6502 instruction set, so use them only when targeting
a compatible CPU. Behavior on CMOS 8500/8502 revisions is outside the scope of
this support. Unstable instructions such as `XAA`, `OAL`, `AHX`, `SHY`, `SHX`,
`TAS`, and `LAS` are intentionally not supported.

| Mnemonic | Aliases | Operation |
| --- | --- | --- |
| `SLO` | `ASO` | ASL memory, then ORA with A |
| `RLA` | | ROL memory, then AND with A |
| `SRE` | `LSE` | LSR memory, then EOR with A |
| `RRA` | | ROR memory, then ADC with A |
| `SAX` | | Store A AND X |
| `LAX` | | Load A and X together |
| `DCP` | `DCM` | DEC memory, then CMP with A |
| `ISC` | `ISB`, `INS` | INC memory, then SBC with A |
| `ALR` | | AND immediate, then LSR A |
| `ARR` | | AND immediate, then ROR A |
| `AXS` | `SBX` | X := A AND X minus immediate |

Every addressing mode that the CPU defines for a mnemonic is accepted, and the
same zero-page fixpoint rules apply. For example:

```asm
  SLO $10        ; 07 10
  SLO $0400,x    ; 1F 00 04
  LAX ($10),y    ; B3 10
  SAX $10,y      ; 97 10
  DCM $10        ; C7 10
  AXS #$03       ; CB 03
```

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
make asm SRC=constants.a64      # assemble one source to its default .prg
make asm SRC=constants.a64 OUT=/tmp/constants.prg
make samples                    # assemble sample sources into build/
make cairo-editor               # launch the Cairo/X11 sprite editor
make cairo-editor-png           # render one editor frame to editor.png
make clean                      # remove build/
```

Override the interpreter with `SLOX_BIN`, for example
`SLOX_BIN=/path/to/slox make test`. The sample build directory can be changed
with `BUILD_DIR`, and the sample source list with `SOURCES`.
