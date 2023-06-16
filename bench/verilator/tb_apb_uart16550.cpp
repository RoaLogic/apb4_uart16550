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
//             Copyright (C) 2023 Roa Logic BV                     //
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


using namespace RoaLogic::testbench::clock::units;
using RoaLogic::common::ringbuffer;
using RoaLogic::bus::cBusAPB4;

/**
 * @brief Constructor
 */
cAPBUart16550TestBench::cAPBUart16550TestBench(VerilatedContext* context) : 
    cTestBench<Vapb_uart16550>(context)
{
    //get scope (for DPI)
    const svScope scope = svGetScopeFromName("TOP.apb_uart16550");
    svSetScope(scope);

    //define new clock
    pclk = addClock(_core->PCLK, 6.0_ns, 4.0_ns);

    //create transaction buffer (16 entries; i.e. 2x FIFO size)
    transactionBuffer = new ringbuffer<uint8_t>(16);

    //Hookup APB4 Bus Master
    apbMaster = new cBusAPB4 <uint8_t,uint8_t,ringbuffer<uint8_t>>
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
    //destroy transaction buffer
    delete transactionBuffer;
}


/**
 * @brief poke 16550 CSRs
 *
 * @param reg Register to poke (set value)
 * @param val Value to set register to
 */
void cAPBUart16550TestBench::poke(uint8_t reg, uint8_t val)
{
    Vapb_uart16550::uart16550_poke(reg, val);
}


/**
 * @brief Release 'force' from register. Use after 'poke'
 *
 * @param reg Register to release from poke
 */
void cAPBUart16550TestBench::release(uint8_t reg)
{
    Vapb_uart16550::uart16550_release(reg);
}

/**
 * @brief peek 16550 CSRs
 *
 * @param reg Register to peek (get value)
 * @return Register content
 */
uint8_t cAPBUart16550TestBench::peek (uint8_t reg) const
{
    return Vapb_uart16550::uart16550_peek(reg);
}


//TODO print error message
/**
 * @brief Compare 16550 CSR
 *
 * @param reg Register to compare
 * @param val Value to compare with register contents
 * @return True if values are equal, false otherwise
 */
bool cAPBUart16550TestBench::equal(uint8_t reg, uint8_t val) const
{
    return peek(reg) == val;
}


/**
 * @brief Run APB Idle Cycles
 *
 * @param duration The number of idle cycles to execute
 */
void cAPBUart16550TestBench::APBIdle(unsigned duration)
{
    apbMaster->idle(duration);
    while (!apbMaster->done()) tick();

    std::cout << "APB Bus Idle" << std::endl;
}


/**
 * @brief Reset APB bus
 *
 * @param duration The number of cycles to assert PRESETn (i.e. PRESET=0)
 */
void cAPBUart16550TestBench::APBReset(unsigned duration)
{
    apbMaster->reset(duration);
    while (!apbMaster->done()) tick();

    std::cout << "APB Bus Reset" << std::endl;
}


/**
 * @brief Program 16550 baud rate
 *
 * @param baudrate The baud rate to configure the 16550 to
 */
void cAPBUart16550TestBench::setBaudRate(unsigned baudrate)
{
    uint8_t wval, peekval;

    // divisor depends on APB clock frequency
    long double apbClockFrequency = pclk -> getFrequency();

    // divisor for baudrate
    unsigned divisor = apbClockFrequency / baudrate;

    // Decimal divisor is 16x baudrate
    divisor /= 16;

    // set DLAB=1
    apbMaster->read(LCR, wval);
    while (!apbMaster->done()) tick();
    wval |= DLAB;
    apbMaster->write(LCR, wval);
    while (!apbMaster->done()) tick();

    //verify value is written
    peekval = peek(PEEK_LCR);
    if (peekval != wval)
    {
        std::cout << "ERROR: written:" << std::hex << unsigned(wval) << " peeked:" << std::hex << unsigned(peekval) << std::endl;
    }

    // Program divisor LSB
    wval = divisor & 0xff;
    apbMaster->write(DLL, wval);
    while (!apbMaster->done()) tick();

    //verify value is written
    peekval = peek(PEEK_DLL);
    if (peekval != wval)
    {
        std::cout << "ERROR: written:" << std::hex << unsigned(wval) << " peeked:" << std::hex << unsigned(peekval) << std::endl;
    }

    // Program divisor MSB
    wval = (divisor >> 8) & 0xff;
    apbMaster->write(DLM, wval);
    while (!apbMaster->done()) tick();

    //verify value is written
    peekval = peek(PEEK_DLM);
    if (peekval != wval)
    {
        std::cout << "ERROR: written:" << std::hex << unsigned(wval) << " peeked:" << std::hex << unsigned(peekval) << std::endl;
    }

    // set DLAB=0
    apbMaster->read(LCR, wval);
    while (!apbMaster->done()) tick();
    wval |= DLAB;
    apbMaster->write(LCR, wval);
    while (!apbMaster->done()) tick();

    //verify value is written
    peekval = peek(PEEK_LCR);
    if (peekval != wval)
    {
        std::cout << "ERROR: written:" << std::hex << unsigned(wval) << " peeked:" << std::hex << unsigned(peekval) << std::endl;
    }
}


/**
 * @brief scratchpadTest reads and writes to the scratchpad register
 *        This tests the APB to register interface
 *
 * @param runs Number of test runs
 */
void cAPBUart16550TestBench::scratchpadTest (unsigned runs)
{
    uint8_t wval, rval, peekval;
    bool error;

    std::cout << "16550 Scratchpad Test\n";
    for (int run=0; run < runs; run++)
    {
        std::cout << "run:" << run << "...";
        error = false;

        //generate random value
        wval = std::rand();

        //write value in scratchpad
        apbMaster->write(SCR, wval);
        while (!apbMaster->done()) tick();

        //compare write value with register content
        //this validates APB write
        peekval = peek(PEEK_SCR);
        if (peekval != wval)
        {
            std::cout << std::endl << "ERROR: written:" << std::hex << unsigned(wval) << " peeked:" << std::hex << unsigned(peekval);
            error |= true;
        }

        //read value from scratchpad
        apbMaster->read(SCR, rval);
        while (!apbMaster->done()) tick();

        //compare values
        if (rval != wval)
        {
            std::cout << std::endl << "ERROR: written:" << std::hex << unsigned(wval) << " read:" << std::hex << unsigned(rval);
            error |= true;
        }

        //break content in the scratchpad register and read/compare values again
        //this validates APB read
        wval = ~wval & 0xff;
        poke(PEEK_SCR, wval);
        apbMaster->read(SCR, rval);
        while (!apbMaster->done()) tick();
        release(PEEK_SCR);

        if (rval != wval)
        {
            std::cout << std::endl << "ERROR: poked:" << std::hex << unsigned(wval) << " received:" << std::hex << unsigned(rval);
            error |= true;
        }

        //Final 'okay' message (if all goes well)
        if (!error)
        {
            std::cout << "ok" << std::endl;
        }
        else
        {
            std::cout << std::endl;
        }
    }
}


/**
 * @brief Program serial data format
 *
 * @param wordLength Number of databits; 5,6,7, or 8
 * @param stopBits   Number of stop bits; either 1 or 2
 * @param parity     Parity; either none, odd, or even
 */
void cAPBUart16550TestBench::setFormat(uint8_t wordLength, uint8_t stopBits, parity_t parity)
{
    uint8_t val;

    //verify wordLength is valid
    assert (wordLength >= 5 && wordLength <= 8);

    //verify stopBits is valid
    assert (stopBits > 0 && stopBits <= 2);

    //get current value of Line Control Register
    apbMaster->read(LCR, val);
    while (!apbMaster->done()) tick();

    //clear LSBs
    val &= 0xE0;

    //program control register
    val |= (wordLength -5) | ((stopBits-1) >> 2) | parity;
    apbMaster->write(LCR, val);
    while (!apbMaster->done()) tick();
}


/**
 * @brief Send data byte
 *
 * @param data Data byte to send
 */
void cAPBUart16550TestBench::sendByte(uint8_t data)
{
    uint8_t val, regval;

    //wait until THRE
    do {
        apbMaster->read(LSR, val);
        while (!apbMaster->done()) tick();
    } while ( !(val & THRE) );

    //write to THR
    apbMaster->write(THR, data);
    while (!apbMaster->done()) tick();

    //THRE should be '0' now
    regval = peek(LSR);
    if (regval & THRE)
    {
        std::cout << "Peeked LSR, expected THRE cleared, but found set" << std::endl;
    }
}

