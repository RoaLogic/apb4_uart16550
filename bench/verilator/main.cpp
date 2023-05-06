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
#include <tb_apb_uart16550.hpp>

//Legacy function required only so linking works on Cygwin and MSVC++ and MacOS
double sc_time_stamp() { return 0; }

int main(int argc, char **argv)
{
    const std::unique_ptr<VerilatedContext> contextp(new VerilatedContext);

    //Pass arguments to Verilated code
    contextp->commandArgs(argc, argv);

    //Create model for DUT
    cAPBUart16550TestBench* testbench = new cAPBUart16550TestBench(contextp.get());

    testbench->opentrace("waveform.vcd");

    /* Need handles to tests
     * These are like statics. The actual object is destroyed immediately after generation,
     * but the handle stays alive
     * if we do:
     *    while (testbench->test1()) testbench->tick();
     * we get a segfault on the 2nd while(), because the object gets immediately destroyed.
     */
    auto waitFor100PCLKCycles = testbench->waitFor(testbench->pclk, 100);
    auto test1                = testbench->test1();
//    auto test2 = testbench->test2();

    //wait 100 cycles
    while (waitFor100PCLKCycles) testbench->tick();

    //Simulate the design until test1 finishes
    while (test1) testbench->tick();

    //run some more cycles
    while (waitFor100PCLKCycles) testbench->tick();

    //destroy testbench
    delete testbench;
    
    //Completed succesfully
    return 0;
}
