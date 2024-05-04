/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//    Main.cpp                                                     //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
//             Copyright (C) 2024 Roa Logic BV                     //
//             www.roalogic.com                                    //
//                                                                 //
//     This source file may be used and distributed without        //
//   restriction provided that this copyright statement is not     //
//   removed from the file and that any derivative work contains   //
//   the original copyright notice and the associated disclaimer.  //
//                                                                 //
//      THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY        //
//   EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED     //
//   TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS     //
//   FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR        //
//   OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,           //
//   INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES      //
//   (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE     //
//   GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR          //
//   BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF    //
//   LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT    //
//   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT    //
//   OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE           //
//   POSSIBILITY OF SUCH DAMAGE.                                   //
//                                                                 //
/////////////////////////////////////////////////////////////////////

#include "tb_apb_uart16550.hpp"

#include <noValueOption.hpp>
#include <valueOption.hpp>

using namespace RoaLogic;
using namespace common;
using namespace testbench;
using namespace tasks;

cProgramOptions programOptions;

cNoValueOption helpOption("h", "help", "Show this help and exit", false);
cNoValueOption traceOption("t", "trace", "Trace option, is given the trace will be enabled", false);
cValueOption<std::string> logOption("l", "log", "Log file path, when not specified log is written to terminal");    
cValueOption<uint8_t> logPriorityOption("p", "priority", "Log priority. Debug = 0, Log = 1, Info = 2, Warning = 3, Error = 4, Fatal = 5");

int setupProgramOptions(int argc, char** argv);
void setupLogger(void);

int main(int argc, char** argv) 
{
    bool withTrace = false;
    // First setup the program options and followed by this setup the logger module
    if(setupProgramOptions(argc, argv))
    {
        return 0;
    }

    setupLogger();

    withTrace = traceOption.isSet();

    // Now let's setup our testbench
    std::unique_ptr<VerilatedContext> contextp(new VerilatedContext);
    contextp->commandArgs(argc, argv); // Parse the eventual option for verilator
    //Create model for DUT
    cAPBUart16550TestBench* testbench = new cAPBUart16550TestBench(contextp.get(), withTrace);

    // Open the trace if this is enabled
    if(withTrace)
    {
        testbench->opentrace("waveform.vcd");
    }

    // Run the testbench for 20 cycles
    testbench->run();

    // finalize the design
    delete testbench;

    // Close the log
    cLog::getInstance()->close();

    return 0;
}

/**
 * @brief Function to setup the program options for this main file
 * @details this function sets the program options, parses the given
 * parameters and then checks some initial program options
 * 
 * @param argc 
 * @param argv 
 * @return 0  continue execution
 * @return >0 Stop program 
 */
int setupProgramOptions(int argc, char** argv)
{
    programOptions.add(&helpOption);
    programOptions.add(&traceOption);
    programOptions.add(&logOption);
    programOptions.add(&logPriorityOption);

    programOptions.parse(argc, argv);

    if(helpOption.isSet())
    {
        programOptions.printKnownOptions();
        return 1;
    }

    return 0;
}

/**
 * @brief Function to setup the logger
 * @details This function sets the logger up.
 * It checks if the priority option is set and gets the value,
 * if it's not set it will be by default INFO.
 * 
 * When the logOption is set, the file path will be selected. 
 * In other cases it will use the terminal for output.
 * 
 * @attention This function must have the logOption and logPriorityOption 
 * in the system.
 */
void setupLogger(void)
{
    uint8_t logPriority = 0;

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

    INFO << "Started log with priority: " << logPriority << "\n";
}

void getScope()
{
    //INFO << "Called getScope()" << std::endl;
    svScope scope = svGetScope();
    const char* scopeName = svGetNameFromScope(scope);

    INFO << "ScopeName:" << scopeName << "\n";
}