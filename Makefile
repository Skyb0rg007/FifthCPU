
IVERILOG = iverilog
VVP = vvp
VERILATOR = verilator
GTKWAVE = gtkwave
GFORTH = gforth
RM = rm -f
MKDIR = mkdir -p

BUILDDIR = _build

.DEFAULT: all
.PHONY: clean lint wave

all: fifth

clean:
	$(RM) $(BUILDDIR)/*

lint:
	$(VERILATOR) --lint-only -Wall src/fifth.v src/fifth_tb.v

wave: $(BUILDDIR)/fifth.lxt
	$(GTKWAVE) $< >/dev/null 2>&1

dump: $(BUILDDIR)/fifth.lxt

fifth: $(BUILDDIR)/fifth.vvp

ROM: $(BUILDDIR)/ROM.hex


# Build rules for files

$(BUILDDIR)/fifth.vvp: src/fifth.v src/fifth_tb.v | $(BUILDDIR)
	$(IVERILOG) -s fifth_tb -o $@ $^

$(BUILDDIR)/fifth.lxt: $(BUILDDIR)/fifth.vvp $(BUILDDIR)/ROM.hex
	cd $(BUILDDIR) && $(VVP) fifth.vvp -lxt2 

$(BUILDDIR)/ROM.hex: src/ROM.fifth compile.fs | $(BUILDDIR)
	$(GFORTH) compile.fs $< > $@

$(BUILDDIR):
	$(MKDIR) $@
