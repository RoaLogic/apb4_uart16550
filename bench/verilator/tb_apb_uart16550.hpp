/**
 * @file tb_apb_uart16550.hpp
 * @author B.Schouteten
 * @brief 
 * @version 0.1
 * @date 2023-04-30
 * 
 * @copyright Copyright (c) 2023
 * 
 */

//For std::unique_ptr
#include <memory>

//Include common routines
#include "testbench.hpp"

//Include model header, generated by Verilator
#include "Vapb_uart16550.h"

//Include test definition
#include "test.hpp"

using namespace RoaLogic::testbench;
using namespace RoaLogic::testbench::test;

enum class coyieldCallback_t {
  posedge,
  negedge
};

struct coyieldReturn_t {
    cClock* clockObj;
    coyieldCallback_t callback;
};


class cAPBUart16550TestBench : public cTestBench<Vapb_uart16550>
{
    public:
        cClock* pclk;
        cClock* tmp_clk1;
        cClock* tmp_clk2;

        //constructor
        cAPBUart16550TestBench(VerilatedContext* context);

        //destructor
        ~cAPBUart16550TestBench();

        //Test 1
        sTest<coyieldReturn_t> test1();

        //Test 2
        //sTest<uint8_t> test2();
};
