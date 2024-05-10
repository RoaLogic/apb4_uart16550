/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//    UART16550 Verilator Testbench                                //
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

#include <tb_apb_uart16550.hpp>

using namespace RoaLogic;
using namespace testbench::clock::units;
using namespace common;
using namespace bus;
using namespace testbench::tasks;

//#define DEBUG_TESTBENCH

/**
 * @brief Constructor
 */
cAPBUart16550TestBench::cAPBUart16550TestBench(VerilatedContext* context, bool traceActive) : 
    cTestBench<Vapb_uart16550>(context, traceActive)
{
    //get scope (for DPI)
    const svScope scope = svGetScopeFromName("TOP.apb_uart16550");
    svSetScope(scope);

    //define new clock
    pclk = addClock(_core->PCLK, 10.0_ns);       // 100MHz clock

    //Hookup APB4 Bus Master
    apbMaster = new cBusAPB4 <uint8_t,uint8_t>
                        (pclk,
                        _core->PRESETn,
                        _core->PSEL,
                        _core->PENABLE,
                        _core->PADDR,
                        _core->PWRITE,
                        _core->PWDATA,
                        _core->PRDATA,
                        _core->PREADY,
                        _core->PSLVERR);
} 

/*
* @brief Destructor
*/
cAPBUart16550TestBench::~cAPBUart16550TestBench()
{

}

/**
 * @brief run the testbench
 * @details This function runs the testbench for the given number of cycles
 * 
 * @todo: Add a parameterized way to select and run different tests
 * 
 * @return int 
 */
int cAPBUart16550TestBench::run()
{
    sCoRoutineHandler myTest = scratchpadTest(100);

    while (!myTest)
    {
        tick();
    }

    tick();

    INFO << "Test result:" << myTest.getValue() << "\n";

    return myTest.getValue();
}

/**
 * @brief Generate a reset through the entire UART testbench
 * @details This is a coroutine function that will
 * generate a full system reset for the APBUART16550.
 * 
 * @return The coroutine handle of this function
 */
sCoRoutineHandler<bool> cAPBUart16550TestBench::generateReset()
{
    INFO << "Generate reset \n";
    _core->PRESETn = 1;

    for(uint8_t i = 0; i < 5; i++)
    {
        waitNegEdge(pclk);
    }

    INFO << "Reset set active \n";
    _core->PRESETn = 0;

    for(uint8_t i = 0; i < 5; i++)
    {
        waitNegEdge(pclk);       
    }

    _core->PRESETn = 1;
    INFO << "Reset done \n";
    co_return true;
}

/**
 * @brief Test for the scratchpad register of the UART 16550 module
 * @details This test will write and read the scratchpad register and 
 * compare the values. If any of the values is not the same the test will 
 * fail. It's is mainly used to test the APB transactions to the UART module.
 * 
 * Test sequence for a single run:
 * 
 * - Get a random write value
 * - Write the random value to the scratchpad register
 * - Peek the scratchpad register value and compare it with the expected value
 * - Read the value from the scratchpad register
 * - Compare read value with written value
 * - Poke the value in the scratchpad register
 * - Reread the value and compare with the poked value
 *
 * @param runs Number of sequences to run
 */
sCoRoutineHandler<bool> cAPBUart16550TestBench::scratchpadTest (size_t runs)
{
    uint8_t writeValue, readValue, peekval;
    bool result = true;
    INFO << "Start scratchpad test\n";
    co_await generateReset();

    waitPosEdge(pclk);

    for (size_t i = 0; (i < runs) && (result); i++)
    {
        INFO << "Run: " << i << " ";

        writeValue = std::rand();   // Get a random value

        // Write the random value into the scratchpad register
        // SCR is the scratchpad address
        co_await apbMaster->write(SCR, &writeValue);

        peekval = peek(PEEK_SCR);

        if (peekval != writeValue)
        {
            APPEND << "Failed: Written:" << std::hex << unsigned(writeValue) << " peeked:" << std::hex << unsigned(peekval) << "\n";
            result = false;
        }

        // Directly read the value back from the scratchpad register
        co_await apbMaster->read(SCR, &readValue);

        if(writeValue != readValue)
        {
            //values are not the same, test has failed
            result = false;
            APPEND << "Failed: Expected: " << std::hex << unsigned(writeValue) << 
                                    " got " << std::hex << unsigned(readValue) << "\n";
        }

        writeValue = ~writeValue & 0xff;
        poke(PEEK_SCR, writeValue);
        co_await apbMaster->read(SCR, &readValue);
        release(SCR);

        if (readValue != writeValue)
        {
            APPEND << "poked:" << std::hex << unsigned(writeValue) << " received:" << std::hex << unsigned(readValue) << "\n";
            result = false;
        }

        if(result = true)
        {
            APPEND << "ok \n";
        }
    }
    
    INFO << "Scratchpad test ended\n";

    co_return result;
}

/**
 * @brief Wrapper function for the DPI poke function 
 *
 * @param reg Register to poke (set value)
 * @param val Value to set register to
 */
void cAPBUart16550TestBench::poke(uint8_t reg, uint8_t val)
{
    Vapb_uart16550::uart16550_poke(reg, val);
}


/**
 * @brief Wrapper function for the DPI release function
 * Release 'force' from register. Use after 'poke'
 *
 * @param reg Register to release from poke
 */
void cAPBUart16550TestBench::release(uint8_t reg)
{
    Vapb_uart16550::uart16550_release(reg);
}

/**
 * @brief Wrapper function for the DPI peek function 
 *
 * @param reg Register to peek (get value)
 * @return Register content
 */
uint8_t cAPBUart16550TestBench::peek (uint8_t reg)
{
    return Vapb_uart16550::uart16550_peek(reg);
}

/**
 * @brief Program 16550 baud rate
 *
 * @param baudrate The baud rate to configure the 16550 to
 */
// void cAPBUart16550TestBench::setBaudRate(unsigned baudrate)
// {
//     uint8_t wval, peekval;

//     // divisor depends on APB clock frequency
//     long double apbClockFrequency = pclk -> getFrequency();

//     // divisor for baudrate
//     unsigned divisor = apbClockFrequency / baudrate;

//     // Decimal divisor is 16x baudrate
//     divisor /= 16;

//     // set DLAB=1
//     apbMaster->read(LCR, wval);
//     while (!apbMaster->done()) tick();
//     wval |= DLAB;
//     apbMaster->write(LCR, wval);
//     while (!apbMaster->done()) tick();

//     //verify value is written
//     peekval = peek(PEEK_LCR);
//     if (peekval != wval)
//     {
//         std::cout << "ERROR: written:" << std::hex << unsigned(wval) << " peeked:" << std::hex << unsigned(peekval) << std::endl;
//     }

//     // Program divisor LSB
//     wval = divisor & 0xff;
//     apbMaster->write(DLL, wval);
//     while (!apbMaster->done()) tick();

//     //verify value is written
//     peekval = peek(PEEK_DLL);
//     if (peekval != wval)
//     {
//         std::cout << "ERROR: written:" << std::hex << unsigned(wval) << " peeked:" << std::hex << unsigned(peekval) << std::endl;
//     }

//     // Program divisor MSB
//     wval = (divisor >> 8) & 0xff;
//     apbMaster->write(DLM, wval);
//     while (!apbMaster->done()) tick();

//     //verify value is written
//     peekval = peek(PEEK_DLM);
//     if (peekval != wval)
//     {
//         std::cout << "ERROR: written:" << std::hex << unsigned(wval) << " peeked:" << std::hex << unsigned(peekval) << std::endl;
//     }

//     // set DLAB=0
//     apbMaster->read(LCR, wval);
//     while (!apbMaster->done()) tick();
//     wval |= DLAB;
//     apbMaster->write(LCR, wval);
//     while (!apbMaster->done()) tick();

//     //verify value is written
//     peekval = peek(PEEK_LCR);
//     if (peekval != wval)
//     {
//         std::cout << "ERROR: written:" << std::hex << unsigned(wval) << " peeked:" << std::hex << unsigned(peekval) << std::endl;
//     }
// }


/**
 * @brief Program serial data format
 *
 * @param wordLength Number of databits; 5,6,7, or 8
 * @param stopBits   Number of stop bits; either 1 or 2
 * @param parity     Parity; either none, odd, or even
 */
// void cAPBUart16550TestBench::setFormat(uint8_t wordLength, uint8_t stopBits, parity_t parity)
// {
//     uint8_t val;

//     //verify wordLength is valid
//     assert (wordLength >= 5 && wordLength <= 8);

//     //verify stopBits is valid
//     assert (stopBits > 0 && stopBits <= 2);

//     //get current value of Line Control Register
//     apbMaster->read(LCR, val);
//     while (!apbMaster->done()) tick();

//     //clear LSBs
//     val &= 0xE0;

//     //program control register
//     val |= (wordLength -5) | ((stopBits-1) >> 2) | parity;
//     apbMaster->write(LCR, val);
//     while (!apbMaster->done()) tick();
// }


/**
 * @brief Send data byte
 *
 * @param data Data byte to send
 */
// void cAPBUart16550TestBench::sendByte(uint8_t data)
// {
//     uint8_t val, regval;

//     //wait until THRE
//     do {
//         apbMaster->read(LSR, val);
//         while (!apbMaster->done()) tick();
//     } while ( !(val & THRE) );

//     //write to THR
//     apbMaster->write(THR, data);
//     while (!apbMaster->done()) tick();

//     //THRE should be '0' now
//     regval = peek(LSR);
//     if (regval & THRE)
//     {
//         std::cout << "Peeked LSR, expected THRE cleared, but found set" << std::endl;
//     }
// }

