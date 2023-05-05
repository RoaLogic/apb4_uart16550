/**
 * @file main.cpp
 * @author B.Schouteten
 * @brief 
 * @version 0.1
 * @date 2023-04-30
 * 
 * @copyright Copyright (c) 2023
 * 
 */
#include "tb_apb_uart16550.hpp"

//Legacy function required only so linking works on Cygwin and MSVC++ and MacOS
double sc_time_stamp() { return 0; }

int main(int argc, char **argv)
{
    const std::unique_ptr<VerilatedContext> contextp(new VerilatedContext);

    //Pass arguments to Verilated code
    contextp->commandArgs(argc, argv);

    //Create model for DUT
    cAPBUart16550TestBench* testBench = new cAPBUart16550TestBench(contextp.get());

    testBench->opentrace("waveform.vcd");

    //start both tests
    auto test1 = testBench->test1();
//    auto test2 = testBench->test2();

    //Simulate the design (until $finish)
    while (!testBench->finished())
    {
        testBench->tick();
    }

    delete testBench;
    
    //Completed succesfully
    return 0;
}
