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

//Constructor
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

//Destructor
cAPBUart16550TestBench::~cAPBUart16550TestBench()
{
  //destroy transaction buffer
  delete transactionBuffer;
}


void cAPBUart16550TestBench::APBIdle(unsigned duration)
{
  apbMaster->idle(duration);
  while (!apbMaster->done()) tick();

  std::cout << "APB Bus Idle" << std::endl;
}


void cAPBUart16550TestBench::APBReset(unsigned duration)
{
  apbMaster->reset(duration);
  while (!apbMaster->done()) tick();

  std::cout << "APB Bus Reset" << std::endl;
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

        //get register value from Verilog
        peekval = Vapb_uart16550::uart16550_peek(PEEK_SCR);

        //compare write value with register content
        //this validates APB write
        if (wval != peekval)
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
        Vabp_uart16550:uart16550_poke(PEEK_SCR, wval);
        apbMaster->read(SCR, rval);
        while (!apbMaster->done()) tick();
        Vapb_uart16550::uart16550_release(PEEK_SCR);

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




/*
//Test1
clockedTest_t cAPBUart16550TestBench::test1()
{
    waitPosedge(pclk);
    _core->PWDATA = 1;

    for (int i=0; i < 10; i++)
    {
        std::cout << "In test1" << std::endl;

        waitPosedge(pclk);
        _core->PWDATA++;
    }
}


//Test2
clockedTest_t cAPBUart16550TestBench::test2()
{
  waitPosedge(tmp_clk1);
  _core->PADDR = 0;

  for (int i=0; i < 10; i++)
  {
    std::cout << "In test2" << std::endl;

    waitPosedge(tmp_clk1);
    _core->PADDR++;
  }
}
*/
