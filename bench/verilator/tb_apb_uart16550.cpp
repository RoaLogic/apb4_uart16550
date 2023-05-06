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

//#define waitfor_posedge(clock,func) {clock->atPosedge(func); co_yield 0;}

using namespace RoaLogic::testbench::units;

//Constructor
cAPBUart16550TestBench::cAPBUart16550TestBench(VerilatedContext* context) : 
    cTestBench<Vapb_uart16550>(context)
{
    pclk = addClock(_core->PCLK, 6.0_ns, 4.0_ns);

    //create 2 testclocks
    //abuse 2 APB signals
    tmp_clk1 = addClock(_core->PENABLE, 21_MHz);
    tmp_clk2 = addClock(_core->PWRITE, 50_MHz);
} 

//Destructor
cAPBUart16550TestBench::~cAPBUart16550TestBench()
{

}


clockedTest_t cAPBUart16550TestBench::waitFor(cClock* clk, unsigned cycles)
{
std::cout << "waitFor\n";
   for (unsigned i=0; i < cycles; i++) waitPosedge(clk);
}


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
