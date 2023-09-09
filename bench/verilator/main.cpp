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
//#include <programoptions.hpp>
#include <valueOption.hpp>
#include <noValueOption.hpp>

using namespace RoaLogic::common;

//Legacy function required only so linking works on Cygwin and MSVC++ and MacOS
double sc_time_stamp() { return 0; }




int main(int argc, char* argv[])
{
    cProgramOptions programOptions;    
    const std::unique_ptr<VerilatedContext> contextp(new VerilatedContext);

    cNoValueOption helpOption("h", "help", "Show this help and exit", false);
    cValueOption<std::string> logOption("l", "log", "Log file path, when not specified log is written to terminal");
    cValueOption<bool> boolOption("b", "bool", "Test for boolean, defaults to false. Option could be '1', true, True or TRUE");
    cValueOption<uint8_t> logPriorityOption("p", "priority", "Log priority. Debug = 0, Log = 1, Info = 2, Warning = 3, Error = 4, Fatal = 5");
    uint8_t logPriority = 0;
    
    programOptions.add(&helpOption);
    programOptions.add(&logOption);
    programOptions.add(&logPriorityOption);
    programOptions.add(&boolOption);
    
    programOptions.parse(argc, argv);

    if(helpOption.isSet())
    {
        programOptions.printKnownOptions();
        return 0;
    }

    if (logPriorityOption.isSet())
    {
        logPriority = logPriorityOption.value();
    }
    else
    {
        logPriority = 2;
    }    

    if(logOption.isSet())
    {
        cLog::getInstance()->init(logPriority, logOption.value());
    }
    else
    {
        cLog::getInstance()->init(logPriority, "");
    }

    INFO << ("Parsed and handled options\n");
    WARNING << "Started log with priority: " << logPriority << "\n";
    ERROR << "Test Error \n";
    DEBUG << "Test Debug \n";
 
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

    //wait 100 cycles
    auto waitFor100PCLKCycles = testbench->waitFor(testbench->pclk, 100);
    while (waitFor100PCLKCycles) testbench->tick();

    //Simulate the design until test1 finishes
    auto test1 = testbench->test1();
    auto test2 = testbench->test2();
    while (test1 || test2) testbench->tick();

    //run some more cycles
    while (waitFor100PCLKCycles) testbench->tick();

    //destroy testbench
    delete testbench;

    // Close the log
    cLog::getInstance()->close();
    
    //Completed succesfully
    return 0;
}
