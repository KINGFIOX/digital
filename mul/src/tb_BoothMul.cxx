#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <memory>
#include <stdlib.h>
#include <verilated.h>
#include <verilated_vcd_c.h>

#include "VBoothMul.h"

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
    bool start;
    uint8_t x;
    uint8_t y;

    BoothInTx() = default;
    BoothInTx(bool _start,
        uint8_t _x,
        uint8_t _y)
        : start(_start)
        , x(_x)
        , y(_y)
    {
    }
};

/**
 * @brief 发生器
 *
 * @return BoothInTx*
 */
BoothInTx* rndBoothInTx()
{
    // 20% chance of generating a transaction
    if (rand() % 5 == 0) {
        BoothInTx* tx = new BoothInTx(
            rand() % 2,
            rand() % 128,
            rand() % 128);
        return tx;
    } else {
        return nullptr;
    }
}

// ALU input interface driver
// 这个 driver 也就是做了一个事情：给 dut 的端口赋值
class BoothInDrv {
private:
    VBoothMul* dut;

public:
    BoothInDrv(VBoothMul* dut) { this->dut = dut; }

    void drive(BoothInTx* tx)
    {
        // 初始化都是 0
        dut->start = 0;

        // Don't drive anything if a transaction item doesn't exist
        if (tx != nullptr) {
            dut->start = tx->start;
            dut->x = tx->x;
            dut->y = tx->y;
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
    uint16_t z;
    bool valid;
    uint8_t _x;
    uint8_t _y;
    BoothOutTx(uint16_t _z, bool _valid, uint8_t __x, uint8_t __y)
        : z(_z)
        , valid(_valid)
        , _x(__x)
        , _y(__y)
    {
    }
};

/**
 * @brief
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
        // 如果 dut 不输出，那么肯定 writeOut 一定不会被调用
        if (in_q.empty()) {
            std::cout << "Fatal Error in AluScb: empty AluInTx queue" << std::endl;
            exit(1);
        }

        BoothInTx* in = in_q.front();
        in_q.pop_front();

        if (tx->valid) {
            // Calculate the expected result
            uint16_t expected = tx->_x * tx->_y;

            // Compare the expected result with the actual result
            if (tx->z != expected) {
                std::cout << "Error in AluScb: expected " << expected << ", got " << tx->z << std::endl;
            } else {
                std::cout << "Success: expected " << expected << ", got " << tx->z << std::endl;
            }
        }

        // As the transaction items were allocated on the heap, it's important
        // to free the memory after they have been used
        delete in;
        delete tx;
    }
};

/**
 * @brief 暗中观察，input 接口上发生的变化，就是这个上面的变化生命周期要比
 * transaction gen 长
 *
 */
class BoothInMon {
private:
    VBoothMul* dut;
    BoothScb* scb;

public:
    BoothInMon(VBoothMul* dut, BoothScb* scb)
    {
        this->dut = dut;
        this->scb = scb;
    }

    void monitor()
    {
        BoothInTx* tx = new BoothInTx(
            dut->start,
            dut->x,
            dut->y);
        scb->writeIn(tx);
    }
};

/**
 * @brief
 *
 */
class BoothOutMon {
private:
    VBoothMul* dut;
    BoothScb* scb;

public:
    BoothOutMon(VBoothMul* dut, BoothScb* scb)
    {
        this->dut = dut;
        this->scb = scb;
    }

    void monitor()
    {
        BoothOutTx* tx = new BoothOutTx(dut->z, dut->valid, dut->_x, dut->_y);

        // then pass the transaction item to the scoreboard
        scb->writeOut(tx);
    }
};

void dut_reset(VBoothMul* dut, vluint64_t& sim_time)
{
    dut->rst = 0;
    if (sim_time >= 3 && sim_time < 6) {
        dut->rst = 1;
        dut->x = 0;
        dut->y = 0;
        dut->start = 0;
    }
}

int main(int argc, char** argv, char** env)
{
    srand(time(0));
    Verilated::commandArgs(argc, argv);
    VBoothMul* dut = new VBoothMul;

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
