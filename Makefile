# The files
FILES		= src/alu.vhdl \
                src/cpu.vhdl \
                src/decoder.vhdl \
                src/instr_memory.vhdl \
                src/memory.vhdl \
                src/registers.vhdl
SIMDIR		= sim
SIMFILES	= test/cpu_tb.vhdl \
               test/for_loop_tb.vhdl \
               test/br1_tb.vhdl \
               test/br2_tb.vhdl \
               test/cmp_tb.vhdl \
               test/math_tb.vhdl

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
	ghdl -e -o sim/for_loop_tb $(GHDL_FLAGS) $(GHDL_WORKDIR) for_loop_tb
	ghdl -e -o sim/br1_tb $(GHDL_FLAGS) $(GHDL_WORKDIR) br1_tb
	ghdl -e -o sim/br2_tb $(GHDL_FLAGS) $(GHDL_WORKDIR) br2_tb
	ghdl -e -o sim/cmp_tb $(GHDL_FLAGS) $(GHDL_WORKDIR) cmp_tb
	ghdl -e -o sim/math_tb $(GHDL_FLAGS) $(GHDL_WORKDIR) math_tb

run:
	cd sim; \
	ghdl -r $(GHDL_FLAGS) cpu_tb --stop-time=220ns --wave=wave_cpu.ghw; \
	ghdl -r $(GHDL_FLAGS) for_loop_tb --stop-time=1900ns --wave=for_loop_cpu.ghw; \
	ghdl -r $(GHDL_FLAGS) br1_tb $(GHDL_STOP) --wave=br1_cpu.ghw; \
	ghdl -r $(GHDL_FLAGS) br2_tb $(GHDL_STOP) --wave=br2_cpu.ghw; \
	ghdl -r $(GHDL_FLAGS) cmp_tb $(GHDL_STOP) --wave=cmp_cpu.ghw; \
	ghdl -r $(GHDL_FLAGS) math_tb $(GHDL_STOP) --wave=math_cpu.ghw; \
	cd ..

view:
	gtkwave sim/wave_cpu.ghw

clean:
	$(GHDL_CMD) --clean --workdir=sim
	
