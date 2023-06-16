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

void getScope()
{
std::cout << "Called getScope()" << std::endl;
    svScope scope = svGetScope();
    const char* scopeName = svGetNameFromScope(scope);

    std::cout << "ScopeName:" << scopeName << std::endl;
}


int main(int argc, char **argv)
{
    const std::unique_ptr<VerilatedContext> contextp(new VerilatedContext);

    const unsigned int baudrate = 19200;


    //Pass arguments to Verilated code
    contextp->commandArgs(argc, argv);

    //Create model for DUT
    cAPBUart16550TestBench* testbench = new cAPBUart16550TestBench(contextp.get());


    testbench->opentrace("waveform.vcd");

    //Idle APB bus
    testbench->APBIdle(2);

    //run APB Reset test
    testbench->APBReset(3);

    //run scratchpad test
    testbench->scratchpadTest(10);

    //program baudrate
    testbench->setBaudRate(baudrate);
    
    //Program data format
    testbench->setFormat(8,1,oddParity);

    //write data
    testbench->sendByte(0xDE);
    testbench->sendByte(0xAD);
    testbench->sendByte(0xBE);
    testbench->sendByte(0xEF);


    //Idle APB bus
    testbench->APBIdle(100000);

    //destroy testbench
    delete testbench;
    
    //Completed succesfully
    return 0;
}
