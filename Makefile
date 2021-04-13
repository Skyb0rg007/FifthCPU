
VHDL = ghdl
VHDLFLAGS = --std=08
RM = rm -f

check:
	$(VHDL) -s $(VHDLFLAGS) common.vhdl stack.vhdl j1.vhdl j1_test.vhdl

clean:
	$(VHDL) --clean
	$(RM) j1_test testbench.vcd

%.o: %.vhdl
	$(VHDL) -a $(VHDLFLAGS) $<

j1_test: common.o stack.o j1.o j1_test.o
	$(VHDL) -e $(VHDLFLAGS) j1_test

testbench.vcd: j1_test
	$(VHDL) -r j1_test --vcd=$@

waveform: testbench.vcd
	gtkwave $< >/dev/null 2>&1

$(BUILDDIR):
	@mkdir -p $@

# Dependencies
stack.o: common.o
j1.o: common.o stack.o
j1_test.o: j1.o
