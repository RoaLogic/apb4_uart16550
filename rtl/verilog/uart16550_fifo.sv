/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//    UART16550 FIFO Module                                        //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
//             Copyright (C) 2024 Roa Logic BV                     //
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
// FILE NAME      : uart16550_fifo.sv
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



//Error bits are in MSBs
module uart16550_fifo
import uart16550_pkg::*;
#(
  parameter int DATA_WIDTH = 8,
  parameter int FIFO_DEPTH = 16
)
(
  input  logic                          rst_ni,     //Asynchronous active low reset
  input  logic                          clk_i,      //Clock

  input  logic                          rst_i,      //Synchronous active high reset
  input  logic                          ena_i,      //FIFO enable
  input  logic                          push_i,     //Push data onto queue
  input  logic                          pop_i,      //Pop data from queue

  input  logic [DATA_WIDTH        -1:0] d_i,        //Data input
  output logic [DATA_WIDTH        -1:0] q_o,        //Data output
  output logic                          error_o,    //Any of the upper 3 MSBs in the FIFO is '1'

  output logic                          empty_o,    //FIFO is empty
  output logic                          full_o,     //FIFO is full
  output logic                          underrun_o, //FIFO underrun
  output logic                          overrun_o,  //FIFO overrun
  input  logic [$clog2(FIFO_DEPTH)-1:0] trigger_lvl_i,
  output logic                          trigger_o
);

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  logic [DATA_WIDTH        -1:0] mem_array [FIFO_DEPTH-1:0];
  logic [FIFO_DEPTH        -2:0] error;
  logic [$clog2(FIFO_DEPTH)-1:0] wadr;

  logic                          push, pop;
 
  

  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  /* FIFO write address
  */

  //no writing to full FIFO
  assign push = push_i & ~full_o;


  //write address
  always @(posedge clk_i, negedge rst_ni)
    if      (!rst_ni) wadr <= 'h0;
    else if ( rst_i ) wadr <= 'h0;
    else 
      case ({push, pop})
        2'b01  : wadr <= wadr -1;
        2'b10  : wadr <= wadr +1;
        default: ;
      endcase


  /* Memory array
  */
  always @(posedge clk_i)
    case ({push, pop})
      2'b00: ;

      2'b01: begin
                 for (int i=0; i < FIFO_DEPTH-2; i++)
                   mem_array[i] <= mem_array[i+1];

                 mem_array[FIFO_DEPTH-1] <= 'h0;
             end

      2'b10: mem_array[wadr] <= d_i;

      2'b11: begin
                 for (int i=0; i < FIFO_DEPTH-2; i++)
                   mem_array[i] <= mem_array[i+1];

                 mem_array[FIFO_DEPTH-1] <= 'h0;

                 mem_array[wadr-1] <= d_i;
             end
    endcase


  /* Assign output
   */
  assign q_o = mem_array[0];


  /* Receive error
   */

  //no reading from emtpy FIFO
  assign pop = pop_i & ~empty_o;


  //Rx error
  always_comb
    for (int i=0; i < FIFO_DEPTH-1; i++) error[i] = |mem_array[i][DATA_WIDTH-1 -: 3];


  always @(posedge clk_i, rst_ni)
    if      (!rst_ni) error_o <= 1'b0;
    else if ( rst_i ) error_o <= 1'b0;
    else              error_o <= |error;


  /* Flags
  */
  //empty
  always @(posedge clk_i, negedge rst_ni)
    if      (!rst_ni) empty_o <= 1'b1;
    else if ( rst_i ) empty_o <= 1'b1;
    else
      case ({push, pop})
        2'b01  : empty_o <= (~|wadr[$clog2(FIFO_DEPTH)-1:1] & wadr[0]) | ~ena_i; //--> wadr == 1
        2'b10  : empty_o <= 1'b0;
        default: ;
      endcase


  //full
  always @(posedge clk_i, negedge rst_ni)
    if      (!rst_ni) full_o <= 1'b0;
    else if ( rst_i ) full_o <= 1'b0;
    else
      case ({push, pop})
        2'b01  : full_o <= 1'b0;
        2'b10  : full_o <= &wadr | ~ena_i;
        default: ;
      endcase


  //underrun
  always @(posedge clk_i, negedge rst_ni)
    if      (!rst_ni) underrun_o <= 1'b0;
    else if ( rst_i ) underrun_o <= 1'b0;
    else
      case ({push_i, pop_i})
        2'b01  : underrun_o <= empty_o;
        2'b10  : underrun_o <= 1'b0;
        default: ;
      endcase


  //overrun
  always @(posedge clk_i, negedge rst_ni)
    if      (!rst_ni) overrun_o <= 1'b0;
    else if ( rst_i ) overrun_o <= 1'b0;
    else
      case ({push_i, pop_i})
        2'b01  : overrun_o <= 1'b0;
        2'b10  : overrun_o <= full_o;
        default: ;
      endcase


  //trigger
  always @(posedge clk_i, negedge rst_ni)
    if      (!rst_ni    ) trigger_o <= 1'b0;
    else if ( rst_i     ) trigger_o <= 1'b0;
    else if ( push ^ pop) trigger_o <= (wadr >= trigger_lvl_i);

endmodule
