/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//    UART16550 Package                                            //
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

 
/************************************************
 * UART16550 Package
 */
package uart16550_pkg;


  /*
   * CSR location 
   */
  localparam [2:0] RBR_ADR = 3'h0;
  localparam [2:0] THR_ADR = 3'h0;
  localparam [2:0] IER_ADR = 3'h1;
  localparam [2:0] IIR_ADR = 3'h2;
  localparam [2:0] FCR_ADR = 3'h2;
  localparam [2:0] LCR_ADR = 3'h3;
  localparam [2:0] MCR_ADR = 3'h4;
  localparam [2:0] LSR_ADR = 3'h5;
  localparam [2:0] MSR_ADR = 3'h6;
  localparam [2:0] SCR_ADR = 3'h7;
  localparam [2:0] DLL_ADR = 3'h0;
  localparam [2:0] DLM_ADR = 3'h1;

   

  /*
   * CSR Definition
   */
  typedef struct packed {
    logic [3:0] zeros;             //always zero
    logic       edssi;             //Enable Modem Status Interrupt
    logic       elsi;              //Enable Receiver Line Status Interrupt
    logic       etbei;             //Enable Transmitter Holding Register Empty Interrupt
    logic       erbi;              //Enable Received Data Available Interrupt
  } ier_t; //Interrupt Enable Register

  typedef struct packed {
    logic [1:0] fifos_enabled;     //FIFOs Enabled
    logic [1:0] zeros;             //always zero
    logic [2:0] interrupt_id;      //Interrupt ID
    logic       interrupt_pending; //'0' when interrupt pending
  } iir_t; //Interrupt Ident. Register

  typedef enum logic [1:0] {rxtrigger01=2'b00, rxtrigger04=2'b01, rxtrigger08=2'b10, rxtrigger14=2'b11} rxtrigger_t;

  typedef struct packed {
    rxtrigger_t rx_trigger;        //Receive trigger
    logic [1:0] reserved;          //reserved
    logic       dma_mode;          //DMA mode select
    logic       tx_rst;            //Transmit FIFO Reset
    logic       rx_rst;            //Receive FIFO Reset
    logic       ena;               //FIFO enabled
  } fcr_t; //FIFO Control Register


  typedef enum logic       {eps_odd_parity=1'b0, eps_even_parity=1'b1} eps_t;
  typedef enum logic [1:0] {wls_5bits=2'b00, wls_6bits=2'b01, wls_7bits=2'b10, wls_8bits=2'b11} wls_t;

  typedef struct packed {
    logic       dlab;              //Divisor Latch Access Bit
    logic       set_break;         //Break Control
                                   //  0: normal sout behaviour
				   //  1: force sout to '0'
    logic       stick_parity;      //Stick Parity
                                   //  0: disable stick parity
				   //  1: fixed parity bit
    eps_t       eps;               //Even Parity Select
                                   //  0: Odd parity
				   //  1: Even parity
    logic       pen;               //Parity Enable
                                   //  1: Insert(Tx) and Check(Rx) Parity bit
    logic       stb;               //Number of stop bits
                                   //  0: 1 stop bit
				   //  1: 2 stop bits, except wls=00 1.5 stop bits
    wls_t       wls;               //Word Length Select
                                   //  00: 5bits
				   //  01: 6bits
				   //  10: 7bits
				   //  11: 8bits
  } lcr_t; //Line Control Register

  typedef struct packed {
    logic [2:0] zeros;             //always zero
    logic       loop;
    logic       out2;
    logic       out1;
    logic       rts;               //Request To Send
    logic       dtr;               //Data Terminal Ready
  } mcr_t; //Modem Control Register

  typedef struct packed {
    logic       rx_fifo_error;
    logic       temt;              //Transmitter Emtpy
    logic       thre;              //Transmitter Holding Register Empty
    logic       bi;                //Break Interrupt
    logic       fe;                //Framing Error
    logic       pe;                //Parity Error
    logic       oe;                //Overrun Error
    logic       dr;                //Data Ready
  } lsr_t; //Line Status Register

  typedef struct packed {
    logic       dcd;               //Data Carrier Detect
    logic       ri;                //Ring Indicator
    logic       dsr;               //Data Set Ready
    logic       cts;               //Clear To Send
    logic       ddcd;              //Delta Data Carrier Detect
    logic       teri;              //Trailing Edge Ring Indicator
    logic       ddsr;              //Delta Data Set Ready
    logic       dcts;              //Delta Clear To Send
  } msr_t; //Modem Status Register

  typedef struct packed {
    logic [7:0] dlm;               //Divisor Latch MSB
    logic [7:0] dll;               //Divisor Latch LSB
  } dl_t;

  typedef struct {
    ier_t       ier;               //Interrupt Enable Register
    iir_t       iir;               //Interrupt Ident. Register
    fcr_t       fcr;               //FIFO Control Register
    lcr_t       lcr;               //Line Control Register
    lsr_t       lsr;               //Line Status Register
    mcr_t       mcr;               //Modem Control Register
    msr_t       msr;               //Modem Status Register
    logic [7:0] scr;               //Scratch Register
    //dl_t        dl;                //Divisor Latch -- Separate to make Verilator happy
  } csr_t;



  //Rx FIFO data
  typedef struct packed {
    logic       bi;
    logic       fe;
    logic       pe;
    logic [7:0] d;
  } rx_d_t;
endpackage



