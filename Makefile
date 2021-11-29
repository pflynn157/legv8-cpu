# The files
FILES		= src/alu.vhdl \
                src/cpu.vhdl \
                src/decoder.vhdl \
                src/instr_memory.vhdl \
                src/memory.vhdl \
                src/registers.vhdl
SIMDIR		= sim
SIMFILES	= test/cpu_tb.vhdl \
               test/br2_tb.vhdl \
               test/cmp_tb.vhdl

# GHDL
GHDL_CMD	= ghdl
GHDL_FLAGS	= --ieee=synopsys --warn-no-vital-generic
GHDL_WORKDIR = --workdir=sim --work=work
GHDL_STOP	= --stop-time=800ns

# For visualization
VIEW_CMD        = /usr/bin/gtkwave

# The commands
all:
	make compile
	make run

compile:
	mkdir -p sim
	ghdl -a $(GHDL_FLAGS) $(GHDL_WORKDIR) $(FILES)
	ghdl -a $(GHDL_FLAGS) $(GHDL_WORKDIR) $(SIMFILES)
	ghdl -e -o sim/cpu_tb $(GHDL_FLAGS) $(GHDL_WORKDIR) cpu_tb
	ghdl -e -o sim/br2_tb $(GHDL_FLAGS) $(GHDL_WORKDIR) br2_tb
	ghdl -e -o sim/cmp_tb $(GHDL_FLAGS) $(GHDL_WORKDIR) cmp_tb

run:
	cd sim; \
	ghdl -r $(GHDL_FLAGS) cpu_tb $(GHDL_STOP) --wave=wave_cpu.ghw; \
	ghdl -r $(GHDL_FLAGS) br2_tb $(GHDL_STOP) --wave=br2_cpu.ghw; \
	ghdl -r $(GHDL_FLAGS) cmp_tb $(GHDL_STOP) --wave=cmp_cpu.ghw; \
	cd ..

view:
	gtkwave sim/wave_cpu.ghw

clean:
	$(GHDL_CMD) --clean --workdir=sim
	
