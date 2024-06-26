#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <memory>
#include <stdlib.h>
#include <verilated.h>
#include <verilated_vcd_c.h>

#include "Vversat_updown_counter.h"

#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)

#define MAX_SIM_TIME 300
#define VERIF_START_TIME 7
vluint64_t sim_time = 0;
vluint64_t posedge_cnt = 0;

/**
 * @brief 只有 driver 才包含有 DUT
 *
 */

class BoothInTx {
public:
    uint8_t new_cntr_preset_value;
    bool new_cntr_preset;
    bool enable_cnt_up;
    bool enable_cnt_dn;
    bool pause_counting;

    BoothInTx() = default;
    BoothInTx(bool _new_cntr_preset,
        uint8_t _new_cntr_preset_value,
        bool _enable_cnt_up,
        bool _enable_cnt_dn,
        bool _pause_counting)
        : new_cntr_preset(_new_cntr_preset)
        , new_cntr_preset_value(_new_cntr_preset_value)
        , enable_cnt_up(_enable_cnt_up)
        , enable_cnt_dn(_enable_cnt_dn)
        , pause_counting(_pause_counting)
    {
    }
};

BoothInTx* rndBoothInTx()
{
    // 20% chance of generating a transaction
    if (rand() % 5 == 0) {
        BoothInTx* tx = new BoothInTx(
            rand() % 2,
            rand() % 256,
            rand() % 2,
            rand() % 2,
            rand() % 2);
        return tx;
    } else {
        return nullptr;
    }
}

// ALU input interface driver
// 这个 driver 也就是做了一个事情：给 dut 的端口赋值
class BoothInDrv {
private:
    Vversat_updown_counter* dut;

public:
    BoothInDrv(Vversat_updown_counter* dut) { this->dut = dut; }

    void drive(BoothInTx* tx)
    {
        // 初始化都是 0
        dut->enable_cnt_dn = 0;
        dut->enable_cnt_up = 0;
        dut->pause_counting = 0;
        dut->new_cntr_preset = 0;

        // Don't drive anything if a transaction item doesn't exist
        if (tx != nullptr) {
            dut->new_cntr_preset = tx->new_cntr_preset;
            dut->new_cntr_preset_value = tx->new_cntr_preset_value;
            dut->enable_cnt_up = tx->enable_cnt_up;
            dut->enable_cnt_dn = tx->enable_cnt_dn;
            dut->pause_counting = tx->pause_counting;
            // Release the memory by deleting the tx item
            // after it has been consumed
            delete tx;
        }
    }
};

// ALU output interface transaction item class
/**
 * @brief 因为我们只有一个输出
 *
 */
class BoothOutTx {
public:
    bool ctr_expired;
    BoothOutTx(bool _ctr_expired)
        : ctr_expired(_ctr_expired)
    {
    }
};

// CNT scoreboard
/**
 * @brief scoreboard 负责计算
 *
 */
class BoothScb {
private:
    std::deque<BoothInTx*> in_q;

public:
    // Input interface monitor port
    /**
     * @brief 向 DUT 写入 transaction
     *
     * @param tx
     */
    void writeIn(BoothInTx* tx)
    {
        // Push the received transaction item into a queue for later
        in_q.push_back(tx);
    }

    // Output interface monitor port
    // output
    void writeOut(BoothOutTx* tx)
    {
        // We should never get any data from the output interface
        // before an input gets driven to the input interface
        // 如果 dut 不输出，那么肯定 writeOut 一定不会被调用
        if (in_q.empty()) {
            std::cout << "Fatal Error in AluScb: empty AluInTx queue" << std::endl;
            exit(1);
        }

        // Grab the transaction item from the front of the input item queue
        BoothInTx* in = in_q.front();
        in_q.pop_front();

        if (tx->ctr_expired) {
            std::cout << "cnt expired!" << std::endl;
        }

        // As the transaction items were allocated on the heap, it's important
        // to free the memory after they have been used
        delete in;
        delete tx;
    }
};

// ALU input interface monitor
/**
 * @brief 暗中观察，input 接口上发生的变化，就是这个上面的变化生命周期要比
 * transaction gen 长
 *
 */
class BoothInMon {
private:
    Vversat_updown_counter* dut;
    BoothScb* scb;

public:
    BoothInMon(Vversat_updown_counter* dut, BoothScb* scb)
    {
        this->dut = dut;
        this->scb = scb;
    }

    void monitor()
    {
        BoothInTx* tx = new BoothInTx(
            dut->new_cntr_preset,
            dut->new_cntr_preset_value,
            dut->enable_cnt_up,
            dut->enable_cnt_dn,
            dut->pause_counting);

        scb->writeIn(tx);
    }
};

// ALU output interface monitor
/**
 * @brief
 *
 */
class BoothOutMon {
private:
    Vversat_updown_counter* dut;
    BoothScb* scb;

public:
    BoothOutMon(Vversat_updown_counter* dut, BoothScb* scb)
    {
        this->dut = dut;
        this->scb = scb;
    }

    void monitor()
    {

        // If there is valid data at the output interface,
        // create a new AluOutTx transaction item and populate
        // it with result observed at the interface pins
        BoothOutTx* tx = new BoothOutTx(dut->ctr_expired);

        // then pass the transaction item to the scoreboard
        scb->writeOut(tx);
    }
};

void dut_reset(Vversat_updown_counter* dut, vluint64_t& sim_time)
{
    dut->resetb = 1;
    if (sim_time >= 3 && sim_time < 6) {
        dut->resetb = 1;
        dut->new_cntr_preset = 0;
        dut->new_cntr_preset_value = 0;
        dut->enable_cnt_up = 0;
        dut->enable_cnt_dn = 0;
        dut->pause_counting = 0;
    }
}

int main(int argc, char** argv, char** env)
{
    srand(time(0));
    Verilated::commandArgs(argc, argv);
    Vversat_updown_counter* dut = new Vversat_updown_counter;

    // 注册 vcd
    Verilated::traceEverOn(true);
    VerilatedVcdC* m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open(TOSTRING(WAVEFORM_FILE));

    BoothInTx* tx;

    // Here we create the driver, scoreboard, input and output monitor blocks
    // monitor 给 scb 写入，并不是传入一个 transaction 就写一次。而是 monitor
    // 一次就 注册
    BoothInDrv* drv = new BoothInDrv(dut);
    BoothScb* scb = new BoothScb();
    BoothInMon* inMon = new BoothInMon(dut, scb);
    BoothOutMon* outMon = new BoothOutMon(dut, scb);

    while (sim_time < MAX_SIM_TIME) {
        dut_reset(dut, sim_time);
        dut->clk ^= 1;
        dut->eval();

        // Do all the driving/monitoring on a positive edge
        if (dut->clk == 1) {

            if (sim_time >= VERIF_START_TIME) {
                // Generate a randomised transaction item of type AluInTx
                tx = rndBoothInTx();

                // Pass the transaction item to the ALU input interface driver,
                // which drives the input interface based on the info in the
                // transaction item
                drv->drive(tx);

                // Monitor the input interface
                inMon->monitor();

                // Monitor the output interface
                // out monitor 写到 scoreboard 里面
                outMon->monitor();
            }
        }
        // end of positive edge processing

        // 写入日志
        m_trace->dump(sim_time);
        sim_time++;
    }

    m_trace->close();
    delete dut;
    delete outMon;
    delete inMon;
    delete scb;
    delete drv;
    exit(EXIT_SUCCESS);
}
