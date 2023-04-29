/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//    APB4 UART16550 Top Level Module                              //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
//             Copyright (C) 2023 ROA Logic BV                     //
//             www.roalogic.com                                    //
//                                                                 //
//   This source file may be used and distributed without          //
//   restriction provided that this copyright statement is not     //
//   removed from the file and that any derivative work contains   //
//   the original copyright notice and the associated disclaimer.  //
//                                                                 //
//      THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY        //
//   EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED     //
//   TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS     //
//   FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR OR     //
//   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,  //
//   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT  //
//   NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;  //
//   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)      //
//   HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN     //
//   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR  //
//   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS          //
//   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  //
//                                                                 //
/////////////////////////////////////////////////////////////////////

// +FHDR -  Semiconductor Reuse Standard File Header Section  -------
// FILE NAME      : apb_uart16550.sv
// DEPARTMENT     :
// AUTHOR         : rherveille
// AUTHOR'S EMAIL :
// ------------------------------------------------------------------
// RELEASE HISTORY
// VERSION DATE        AUTHOR      DESCRIPTION
// 1.0     2023-03-01  rherveille  initial release
// ------------------------------------------------------------------
// KEYWORDS : AMBA APB4 16550 compatible UART     
// ------------------------------------------------------------------
// PURPOSE  : UART 16550
// ------------------------------------------------------------------
// PARAMETERS
//  PARAM NAME        RANGE    DESCRIPTION              DEFAULT UNITS
//
// ------------------------------------------------------------------
// REUSE ISSUES 
//   Reset Strategy      : external asynchronous active low; rst_ni
//   Clock Domains       : clk_i, rising edge
//   Critical Timing     : 
//   Test Features       : na
//   Asynchronous I/F    : no
//   Scan Methodology    : na
//   Instantiations      : na
//   Synthesizable (y/n) : Yes
//   Other               :                                         
// -FHDR-------------------------------------------------------------


/*
 * Addr RW Register                         Bit7      Bit6       Bit5       Bit4       Bit3       Bit2       Bit1       Bit0
 * ------------------------------------------------------------------------------------------------------------------------------+
 * 0x0  R  Receive Buffer Register    RBR  Databit7 | Databit6 | Databit5 | Databit4 | Databit3 | Databit2 | Databit1 | Databit0 |
 * 0x0  W  Transmit Holding Register  THR  Databit7 | Databit6 | Databit5 | Databit4 | Databit3 | Databit2 | Databit1 | Databit0 |
 * 0x1  RW Interrupt Enable Register  IER  0        | 0        | 0        | 0        | EDSSI    | ELSI     | ETBEI    | ERFBI    |
 * 0x2  R  Interrupt Ident Register   IIR  FIFOs En | FIFOs En | 0        | 0        | IIDbit2  | IIDbit1  | IIDbit0  | IntPend  |
 * 0x2  W  FIFO Control Register      FCR  RxTrig1  | RxTrig0  | reserved | reserved | DMA Mode | TxFIFORst| RxFIFORst| FIFO Ena |
 * 0x3  RW Line Control Register      LCR  DLAB     | Set Break| StkParity| EPS      | PEN      | STB      | WLS1     | WLS0     |
 * 0x4  RW Modem Control Register     MCR  0        | 0        | 0        | Loop     | Out2     | Out1     | RTS      | DTR      |
 * 0x5  R  Line Status Register       LSR  RxFIFOErr| TEMT     | THRE     | BI       | FE       | PE       | OE       | DR       |
 * 0x6  R  Modem Status Register      MSR  DCD      | RI       | DSR      | CTS      | DDCD     | TERI     | DDSR     | DCTS     |
 * 0x7  RW Scratchpad Register        SCR  Bit7     | Bit6     | Bit5     | Bit4     | Bit3     | Bit2     | Bit1     | Bit0     |
 *
 * DLAB=1
 * 0x0  RW Divisor Latch LSB          DLL  Bit7     | Bit6     | Bit5     | Bit4     | Bit3     | Bit2     | Bit1     | Bit0     |
 * 0x1  RW Divisor Latch MSB          DLM  Bit15    | Bit14    | Bit13    | Bit12    | Bit11    | Bit10    | Bit9     | Bit8     |
 */

module apb_uart16550
import uart16550_pkg::*;
#(
  parameter int FIFO_DEPTH = 16
)
(
  input  logic       PRESETn,
  input  logic       PCLK,
  input  logic       PSEL,
  input  logic       PENABLE,
  input  logic [2:0] PADDR,
  input  logic       PWRITE,
  input  logic [7:0] PWDATA,
  output logic [7:0] PRDATA,
  output logic       PREADY,
  output logic       PSLVERR,

  output logic       sout_o,
  input  logic       sin_i,
  output logic       rts_no,
  output logic       dtr_no,
  input  logic       dsr_ni,
  input  logic       dcd_ni,
  input  logic       cts_ni,
  input  logic       ri_ni,

  output logic       out1_no,
  output logic       out2_no,

  output logic       txrdy_no,
  output logic       rxrdy_no,

  output logic       baudout_no,

  output logic       intr_o
);

  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //



  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //

  logic       apb_read;
  logic       apb_write;

  csr_t       csr;

  logic       tx_push,
              tx_pop,
              tx_empty,
              tx_sr_empty;
  logic [7:0] tx_q;

  logic       rx_push,
              rx_pop,
              rx_empty,
              rx_fifo_error,
              rx_overrun;
  logic [3:0] rx_trigger_lvl;
  logic       rx_trigger;
  rx_d_t      rx_d,
              rx_q;


  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  /*
   * APB accesses
   */
  //The core supports zero-wait state accesses on all transfers.
  //It is allowed to drive PREADY with a hard wired signal
  assign PREADY  = 1'b1; //always ready
  assign PSLVERR = 1'b0; //Never an error


  //Decode APB read and write
  assign apb_read  = PSEL & PENABLE & ~PWRITE;
  assign apb_write = PSEL & PENABLE &  PWRITE;

  logic  clk_i = PCLK;
  logic  rst_ni = PRESETn;


  /*
   * Hookup Registers
   */
  uart16550_regs regs (
    .rst_ni           ( rst_ni        ),
    .clk_i            ( clk_i         ),

    .adr_i            ( PADDR         ),
    .d_i              ( PWDATA        ),
    .q_o              ( PRDATA        ),
    .re_i             ( apb_read      ),
    .we_i             ( apb_write     ),

    .csr_o            ( csr           ),

    .baudout_o        ( baudout_no    ),
    .rts_no           ( rts_no        ),
    .cts_ni           ( cts_ni        ),
    .dtr_no           ( dtr_no        ),
    .dsr_ni           ( dsr_ni        ),
    .dcd_ni           ( dcd_ni        ),
    .ri_ni            ( ri_ni         ),

    .txrdy_no         ( txrdy_no      ),
    .rxrdy_no         ( rxrdy_no      ),

    .out1_no          ( out1_no       ),
    .out2_no          ( out2_no       ),

    .irq_o            ( intr_o        ),

    //Tx signals
    .tx_empty_i       ( tx_empty      ),
    .tx_push_o        ( tx_push       ),
    .tx_sr_empty_i    ( tx_sr_empty   ),

    //Rx signals
    .rx_empty_i       ( rx_empty      ),
    .rx_pop_o         ( rx_pop        ),
    .rx_q_i           ( rx_q          ),
    .overrun_error_i  ( rx_overrun    ),
    .rx_fifo_error_i  ( rx_fifo_error ),
    .rx_trigger_lvl_o ( rx_trigger_lvl ),
    .rx_trigger_i     ( rx_trigger     ));


  /*
   * Hookup Tx FIFO
   */
  uart16550_fifo #(
    .DATA_WIDTH    ( 8              ),
    .FIFO_DEPTH    ( FIFO_DEPTH     ))
  tx_fifo (
    .rst_ni        ( rst_ni         ),
    .clk_i         ( clk_i          ),

    .rst_i         ( csr.fcr.tx_rst ),
    .ena_i         ( csr.fcr.ena    ),
    .push_i        ( tx_push        ),
    .pop_i         ( tx_pop         ),

    .d_i           ( PWDATA         ),
    .q_o           ( tx_q           ),
    .error_o       (                ),

    .empty_o       ( tx_empty       ),
    .full_o        (                ),
    .underrun_o    (                ),
    .overrun_o     (                ),
    .trigger_lvl_i ( 4'h0           ),
    .trigger_o     (                ));


  /*
   * Hookup Tx Block
   */
  uart16550_tx
  tx (
    .rst_ni     ( rst_ni      ),
    .clk_i      ( clk_i       ),

    .baudout_i  ( baudout_no  ),
    .csr_i      ( csr         ),
    .pop_o      ( tx_pop      ),
    .d_i        ( tx_q        ),
    .sr_empty_o ( tx_sr_empty ),
    .sout_o     ( sout_o      ));


  /*
   * Hookup Rx Block
   */
  uart16550_rx
  rx (
    .rst_ni    ( rst_ni     ),
    .clk_i     ( clk_i      ),

    .baudout_i ( baudout_no ),
    .csr_i     ( csr        ),
    .push_o    ( rx_push    ),
    .q_o       ( rx_d       ),
    .sin_i     ( sin_i      )); //TODO: SIN needs to be synchronised


  /*
   * Hookup Rx FIFO
   */
  uart16550_fifo #(
    .DATA_WIDTH   ( $bits(rx_d_t)   ),
    .FIFO_DEPTH   ( FIFO_DEPTH      ))
  rx_fifo (
    .rst_ni        ( rst_ni         ),
    .clk_i         ( clk_i          ),

    .rst_i         ( csr.fcr.rx_rst ),
    .ena_i         ( csr.fcr.ena    ),
    .push_i        ( rx_push        ),
    .pop_i         ( rx_pop         ),

    .d_i           ( rx_d           ),
    .q_o           ( rx_q           ),
    .error_o       ( rx_fifo_error  ),

    .empty_o       ( rx_empty       ),
    .full_o        (                ),
    .underrun_o    (                ),
    .overrun_o     ( rx_overrun     ),
    .trigger_lvl_i ( rx_trigger_lvl ),
    .trigger_o     ( rx_trigger     ));

endmodule
