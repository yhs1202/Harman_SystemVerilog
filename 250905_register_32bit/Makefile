VIVADO ?= vivado
PROJ := $(notdir $(CURDIR))

TOP  ?= top
PART ?= xc7a35ticsg324-1L

OUTDIR := out
BIT := $(OUTDIR)/$(PROJ).bit

SOURCES := $(shell find src -type f \( -name '*.v' -o -name '*.sv' \) 2>/dev/null)
XDC := $(wildcard constr/*.xdc)

.PHONY: all help bit clean veryclean check

all: bit

help:
	@echo "Targets:"
	@echo "  make bit         - run Vivado batch build (uses build.tcl)"
	@echo "  make clean       - remove out/ and Vivado work dirs"
	@echo "  make veryclean   - clean + IDE/OS leftovers"
	@echo ""
	@echo "Variables (override as needed):"
	@echo "  TOP=<top_module>    (default: $(TOP))"
	@echo "  PART=<fpga_part>    (default: $(PART))"
	@echo ""
	@echo "Examples:"
	@echo "  make bit"
	@echo "  make bit TOP=top_basys3 PART=xc7a35ticsg324-1L"

check:
	@command -v $(VIVADO) >/dev/null 2>&1 || { \
	  echo "ERROR: '$(VIVADO)' not found in PATH"; exit 127; }

bit: $(BIT)

$(BIT): $(SOURCES) $(XDC) build.tcl
	@mkdir -p $(OUTDIR)
	TOP="$(TOP)" PART="$(PART)" $(VIVADO) -mode batch -source build.tcl
	@test -f "$(BIT)" || { echo "ERROR: expected bitstream '$(BIT)' not found"; exit 1; }

clean:
	@rm -rf $(OUTDIR) .Xil .cache .hw .runs .sim .gen

veryclean: clean
	@rm -rf .vscode .idea Thumbs.db .DS_Store
