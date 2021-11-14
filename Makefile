# The files
FILES		= src/registers.vhdl \
              src/decoder.vhdl \
              src/cpu.vhdl \
              src/alu.vhdl
SIMDIR		= sim
SIMFILES	= test/reg_tb.vhdl \
          test/cpu_tb.vhdl

# GHDL
GHDL_CMD	= ghdl
GHDL_FLAGS	= --ieee=synopsys --warn-no-vital-generic
GHDL_WORKDIR = --workdir=sim --work=work
GHDL_STOP	= --stop-time=650ns

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
	ghdl -e -o sim/reg_tb $(GHDL_FLAGS) $(GHDL_WORKDIR) reg_tb
	ghdl -e -o sim/cpu_tb $(GHDL_FLAGS) $(GHDL_WORKDIR) cpu_tb

run:
	cd sim; \
	ghdl -r $(GHDL_FLAGS) reg_tb $(GHDL_STOP) --wave=wave_reg.ghw; \
	ghdl -r $(GHDL_FLAGS) cpu_tb $(GHDL_STOP) --wave=wave_cpu.ghw; \
	cd ..

view:
	gtkwave sim/wave_cpu.ghw

clean:
	$(GHDL_CMD) --clean --workdir=sim
