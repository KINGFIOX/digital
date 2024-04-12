# Makefile for Verilator simulation
VERILATOR = verilator
VERILATOR_FLAGS = -Wall --cc --trace -Iobj_dir

# Source and testbench files
TOP_MODULE = pulse_synchronizer
VERILOG_SRC = src/$(TOP_MODULE).sv
TESTBENCH_SRC = src/tb.cxx
SIM_EXEC = obj_dir/V$(TOP_MODULE)

all: $(SIM_EXEC)

$(SIM_EXEC): $(VERILOG_SRC) $(TESTBENCH_SRC)
	@echo "Compiling Verilog source..."
	$(VERILATOR) $(VERILATOR_FLAGS) $(VERILOG_SRC) --exe $(TESTBENCH_SRC)
	@echo "Building C++ simulation model..."
	$(MAKE) -C obj_dir -f V$(TOP_MODULE).mk


# dwfv 运行 cargo install dwfv
run: vcd
	dwfv *.vcd

# 生成 vcd 文件
vcd: $(SIM_EXEC)
	@./$(SIM_EXEC)
	

clean:
	rm -rf obj_dir *.vcd

.PHONY: all run clean
