
IVERILOG = iverilog
VVP = vvp
RM = rm -f
GTKWAVE = gtkwave
GFORTH = gforth

.DEFAULT: all
.PHONY: clean

all: fifth

clean:
	$(RM) fifth fifth.vcd ROM.hex

fifth: fifth.v fifth_tb.v ROM.hex
	@#$(IVERILOG) -o fifth j1.v fifth_tb.v
	$(IVERILOG) -s fifth_tb -o fifth fifth.v fifth_tb.v

fifth.vcd: fifth
	$(VVP) fifth

wave: fifth.vcd
	$(GTKWAVE) fifth.vcd >/dev/null 2>&1

ROM.hex: compile.fs ROM.fifth
	$(GFORTH) compile.fs > ROM.hex

