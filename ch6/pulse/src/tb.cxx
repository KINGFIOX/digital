#include <verilated.h>
#include <verilated_vcd_c.h>

#include "Vpulse_synchronizer.h"

int main(int argc, char** argv, char** env)
{
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true); // Enable tracing

    Vpulse_synchronizer* top = new Vpulse_synchronizer;

    VerilatedVcdC* vcd = new VerilatedVcdC;
    top->trace(vcd, 5); // Trace 99 levels of hierarchy
    vcd->open("wavetrace.vcd"); // Open the VCD file

    // Initialize signals
    top->clksrc = 0;
    top->resetb_clksrc = 0;
    top->clkdest = 0;
    top->resetb_clkdest = 0;
    top->pulse_src = 0;

    int time = 0;

    // Simulation loop
    while (time < 1000 && !Verilated::gotFinish()) {
        if (time % 5 == 3)
            top->clksrc = !top->clksrc; // Toggle clksrc every 10 time units
        if (time % 7 == 2)
            top->clkdest = !top->clkdest; // Toggle clkdest every 20 time units

        if (time == 10) {
            top->resetb_clksrc = 1; // Release reset on clksrc
            top->resetb_clkdest = 1; // Release reset on clkdest
        }

        if (time == 30)
            top->pulse_src = 1; // Generate a pulse
        if (time == 300)
            top->pulse_src = 0; // End pulse

        top->eval(); // Evaluate model
        vcd->dump(time); // Dump trace data

        time++;
    }

    vcd->close(); // Close VCD
    delete top; // Clean up

    exit(0);
}
