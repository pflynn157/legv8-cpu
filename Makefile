# The files
FILES		= src/registers.vhdl \
              src/decoder.vhdl \
              src/alu.vhdl \
              src/cpu2.vhdl
SIMDIR		= sim
SIMFILES	= test/cpu2_tb.vhdl

# GHDL
GHDL_CMD	= ghdl
GHDL_FLAGS	= --ieee=synopsys --warn-no-vital-generic
GHDL_WORKDIR = --workdir=sim --work=work
GHDL_STOP	= --stop-time=500ns

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
	ghdl -e -o sim/cpu2_tb $(GHDL_FLAGS) $(GHDL_WORKDIR) cpu2_tb

run:
	cd sim; \
	ghdl -r $(GHDL_FLAGS) cpu2_tb $(GHDL_STOP) --wave=wave_cpu2.ghw; \
	cd ..

view:
	gtkwave sim/wave_cpu2.ghw

clean:
	$(GHDL_CMD) --clean --workdir=sim
