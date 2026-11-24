SLOX_BIN ?= slox
SRC ?=
OUT ?=
BUILD_DIR ?= build
SOURCES ?= sample.a64 constants.a64

PNG ?= editor.png
SPRITE ?=

.PHONY: all test asm samples cairo-editor cairo-editor-png clean help

all: test

help:
	@echo "Targets:"
	@echo "  make test                    Run the assembler test suite"
	@echo "  make asm SRC=file.a64        Assemble one source file"
	@echo "  make asm SRC=file.a64 OUT=x  Assemble to a specific output path"
	@echo "  make samples                 Assemble sample sources into build/"
	@echo "  make cairo-editor            Launch the Cairo/X11 sprite editor"
	@echo "  make cairo-editor-png        Render one editor frame to PNG=$(PNG)"
	@echo "  make clean                   Remove build/"

test:
	./run_tests.sh

asm:
	@if [ -z "$(SRC)" ]; then echo "Error: set SRC=path/to/source.a64"; exit 1; fi
	$(SLOX_BIN) asm.lox $(SRC) $(if $(OUT),-o $(OUT),)

samples: | $(BUILD_DIR)
	@for src in $(SOURCES); do \
		echo "Assembling $$src"; \
		$(SLOX_BIN) asm.lox $$src -o $(BUILD_DIR)/$$(basename $$src .a64).prg || exit 1; \
	done

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

cairo-editor:
	$(SLOX_BIN) cse_main.lox $(if $(SPRITE),--sprite $(SPRITE),)

cairo-editor-png:
	$(SLOX_BIN) cse_main.lox --png $(PNG) $(if $(SPRITE),--sprite $(SPRITE),)

clean:
	rm -rf $(BUILD_DIR)
