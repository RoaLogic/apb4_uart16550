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



#include "tb_apb_uart16550.hpp"
#include "test.hpp"


#define waitfor_posedge(clock,func) {clock->atPosedge(func); co_yield 0;}


using namespace RoaLogic::testbench::units;

//Constructor
cAPBUart16550TestBench::cAPBUart16550TestBench(VerilatedContext* context) : 
    cTestBench<Vapb_uart16550>(context)
{
    pclk = addClock(_core->PCLK, 6.0_ns, 4.0_ns);
} 

//Destructor
cAPBUart16550TestBench::~cAPBUart16550TestBench()
{

}


//Test1
sTest<uint8_t> cAPBUart16550TestBench::test1()
{
  _core->PWDATA = 0;

  for (int i=0; i < 10; i++)
  {
    std::cout << "In test1" << std::endl;
    _core->PWDATA++;

    //This is where we insert waitfor_posedge
    //posedge means inserting the routine into the posedge_tick for the clock
    //Because coroutines are stackless, we cannot call co_yield in another method,
    //  thus creating a posedge() method does not work (that would co_yield posedge)
    //Macro then?!
    //Also how do we move the address of the current method into the clock-class and
    //then call the stored coroutine function to resume it without knowing the actual
    //type of the function (plus it will be many different functions)

//    pclk->atPosedge(test1);
//    pclk->atPosedge2<&cAPBUart16550TestBench::test1>();
//    co_yield 0;

      co_yield pclk->atPosedge();
  }
}


//Test2
sTest<uint8_t> cAPBUart16550TestBench::test2()
{
  _core->PADDR = 0;

  for (int i=0; i < 100; i++)
  {
    std::cout << "In test2" << std::endl;
    _core->PADDR++;

    //This is where we insert waitfor_posedge
    co_yield 0;
  }
}



