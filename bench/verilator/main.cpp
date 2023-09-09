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

void getScope()
{
std::cout << "Called getScope()" << std::endl;
    svScope scope = svGetScope();
    const char* scopeName = svGetNameFromScope(scope);

    std::cout << "ScopeName:" << scopeName << std::endl;
}


int main(int argc, char **argv)
{
    cProgramOptions programOptions;    
    const std::unique_ptr<VerilatedContext> contextp(new VerilatedContext);

    const unsigned int baudrate = 19200;


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

    // Close the log
    cLog::getInstance()->close();
    
    //Completed succesfully
    return 0;
}
