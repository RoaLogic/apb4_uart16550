/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//    UART16550 Receiver Module                                    //
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
// FILE NAME      : uart16550_rx.sv
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



module uart16550_rx
import uart16550_pkg::*;
(
  input  logic  rst_ni,
  input  logic  clk_i,

  input  logic  baudout_i,

/* verilator lint_off UNUSEDSIGNAL */
  input  csr_t  csr_i,
/* verilator lint_on UNUSEDSIGNAL */

  output logic  push_o,
  output rx_d_t q_o,

  input  logic  sin_i
);

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  enum logic [2:0] {ST_IDLE=0, ST_START=1, ST_BYTE=2, ST_PARITY=3, ST_STOP=4} state;

  logic       dsin;
  logic       fallingedge_sin;
  logic [3:0] cnt;
  logic       cnt7,
              cnt0;
  logic [2:0] bitcnt;

  logic [7:0] break_load_value,
              break_cnt;
//  logic [9:0] timeout_load_value,
//              timeout_cnt;


  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  //Detect falling edge of sin_i
  always @(posedge clk_i)
    dsin <= sin_i;

  assign fallingedge_sin = ~sin_i & dsin;


  //bit counter steps
  assign cnt7 = cnt == 4'h7;
  assign cnt0 = ~|cnt;


  //Rx FSM
  always @(posedge clk_i, negedge rst_ni)
    if (!rst_ni)
    begin
        state  <= ST_IDLE;
        cnt    <= {$bits(cnt   ){1'bx}};       //don't care
        bitcnt <= {$bits(bitcnt){1'bx}};       //don't care
        q_o    <= {$bits(q_o   ){1'bx}};       //don't care
        push_o <= 1'b0;
    end
    else
    begin
        push_o <= 1'b0;

        if (baudout_i)
        begin
            cnt <= cnt -1;

            case (state)
              //wait for start
              ST_IDLE  : if (fallingedge_sin) //start bit detected
                         begin
                             state <= ST_START;
                             cnt   <= 4'd15;    //start bit is 16 baudout cycles
                         end


              //check if this was a start or a spike
              ST_START : if (cnt7)
                         begin
                             if (sin_i)
                             begin
                                 //not a full start, assume spike and ignore
                                 state <= ST_IDLE;
                                 cnt   <= 4'dx; //don't care
                             end
                         end
                         else if (cnt0)
                         begin
                             state  <= ST_BYTE;
                             cnt    <= 4'd15;        //databit is 16 baudout cycles
                             bitcnt <= {1'b1,csr_i.lcr.wls};
                         end


              ST_BYTE  : if (cnt7)
                         begin
                             case (csr_i.lcr.wls) //Shift Register
                               wls_5bits: q_o.d <= {3'h0, sin_i, q_o.d[4:1]};
                               wls_6bits: q_o.d <= {2'h0, sin_i, q_o.d[5:1]};
                               wls_7bits: q_o.d <= {1'h0, sin_i, q_o.d[6:1]};
                               wls_8bits: q_o.d <= {      sin_i, q_o.d[7:1]};
                             endcase
                         end
                         else if (cnt0)
                         begin
                             //have all bits been transmitted
                             if (~|bitcnt) state <= csr_i.lcr.pen ? ST_PARITY : ST_STOP;

                             cnt    <= 4'd15;                               //data/paritybit is 16baudout cycles
                             bitcnt <= bitcnt -1;                           //next databit
                         end


              ST_PARITY: if (cnt7)
                         begin
                             case ({csr_i.lcr.stick_parity, csr_i.lcr.eps})
                                2'b00: q_o.pe <= ~^{sin_i,q_o.d};           //odd parity
                                2'b01: q_o.pe <=  ^{sin_i,q_o.d};           //even parity
                                2'b10: q_o.pe <= ~sin_i;                    //parity should have been a '1'
                                2'b11: q_o.pe <=  sin_i;                    //parity should have been a '0'
                              endcase
                         end
                         else if (cnt0)
                         begin
                             state <= ST_STOP;
                             cnt   <= 4'd15;
                         end


              ST_STOP  : if (cnt7)
                         begin
                             q_o.fe <= ~sin_i;   //FrameError: sin_i should have been a '1' for stop
                             push_o <= 1'b1;     //push data into RBR/RxFIFO
                         end
                         else if (cnt0)
                         begin
                             state <= ST_IDLE;
                             cnt   <= 4'dx;      //don't care
                         end

              //We should never end up here!
              default  : begin
                            state <= ST_IDLE;
                         end
            endcase
        end
    end



  //Timeout and BREAK

  //break counter load value
  always_comb
    case ({csr_i.lcr.pen, csr_i.lcr.stb, csr_i.lcr.wls})
      {2'b00, wls_5bits}: break_load_value = 8'd112; //Start, no parity, 5 data, 1 stop   ( 7)
      {2'b00, wls_6bits}: break_load_value = 8'd128; //Start, no parity, 6 data, 1 stop   ( 8)
      {2'b00, wls_7bits}: break_load_value = 8'd144; //Start, no parity, 7 data, 1 stop   ( 9)
      {2'b00, wls_8bits}: break_load_value = 8'd160; //Start, no parity, 8 data, 1 stop   (10)
      {2'b01, wls_5bits}: break_load_value = 8'd120; //Start, no parity, 5 data, 1.5 stop ( 7.5)
      {2'b01, wls_6bits}: break_load_value = 8'd144; //Start, no parity, 6 data, 2 stop   ( 9)
      {2'b01, wls_7bits}: break_load_value = 8'd160; //Start, no parity, 7 data, 2 stop   (10)
      {2'b01, wls_8bits}: break_load_value = 8'd176; //Start, no parity, 8 data, 2 stop   (11)
      {2'b10, wls_5bits}: break_load_value = 8'd128; //Start,    parity, 5 data, 1 stop   ( 8)
      {2'b10, wls_6bits}: break_load_value = 8'd144; //Start,    parity, 6 data, 1 stop   ( 9)
      {2'b10, wls_7bits}: break_load_value = 8'd160; //Start,    parity, 7 data, 1 stop   (10)
      {2'b10, wls_8bits}: break_load_value = 8'd176; //Start,    parity, 8 data, 1 stop   (11)
      {2'b11, wls_5bits}: break_load_value = 8'd136; //Start,    parity, 5 data, 1.5 stop ( 8.5)
      {2'b11, wls_6bits}: break_load_value = 8'd160; //Start,    parity, 6 data, 2 stop   (10)
      {2'b11, wls_7bits}: break_load_value = 8'd176; //Start,    parity, 7 data, 2 stop   (11)
      {2'b11, wls_8bits}: break_load_value = 8'd192; //Start,    parity, 8 data, 2 stop   (12)
    endcase


  //Timeout load value is same as break load value times 4
  //assign timeout_load_value = break_load_value *4;


  //BREAK
  always @(posedge clk_i, rst_ni)
    if      (!rst_ni                 ) break_cnt <= 8'd176; //Default for 8N1
    else if ( sin_i                  ) break_cnt <= break_load_value;
    else if ( baudout_i && |break_cnt) break_cnt <= break_cnt -1;


endmodule
