# Makefile for Verilator simulation
VERILATOR = verilator
VERILATOR_FLAGS = -Wall --cc --trace -Iobj_dir

# Source and testbench files
TOP_MODULE = versat_updown_counter
VERILOG_SRC = src/$(TOP_MODULE).sv
TESTBENCH_SRC = src/tb_versat_updown_counter.cxx
SIM_EXEC = obj_dir/V$(TOP_MODULE)

all: $(SIM_EXEC)

$(SIM_EXEC): $(VERILOG_SRC) $(TESTBENCH_SRC)
	@echo "Compiling Verilog source..."
	$(VERILATOR) $(VERILATOR_FLAGS) $(VERILOG_SRC) --exe $(TESTBENCH_SRC)
	@echo "Building C++ simulation model..."
	$(MAKE) -C obj_dir -f V$(TOP_MODULE).mk

# 生成 vcd 文件, 并用 dwfv 运行 cargo install dwfv
run: $(SIM_EXEC)
	@./$(SIM_EXEC)
	dwfv waveform.vcd
	

clean:
	rm -rf obj_dir waveform.vcd

.PHONY: all run clean
