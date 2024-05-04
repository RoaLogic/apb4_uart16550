/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//    UART16550 Transmitter Module                                 //
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
// FILE NAME      : uart16550_tx.sv
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



module uart16550_tx
import uart16550_pkg::*;
(
  input  logic       rst_ni,
  input  logic       clk_i,

  input  logic       baudout_i,

/* verilator lint_off UNUSEDSIGNAL */
  input  csr_t       csr_i,
/* verilator lint_on UNUSEDSIGNAL */

  output logic       pop_o,
  input  logic [7:0] d_i,

  output logic       sr_empty_o,

  output logic       sout_o
);

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  enum logic [1:0] {ST_IDLE=0, ST_START=1, ST_BYTE=3, ST_PARITY=2} state;

  logic [7:0] sr;
  logic       sout;
  logic       data_parity;
  logic [4:0] cnt;
  logic [2:0] bitcnt;


  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //


  always @(posedge clk_i, negedge rst_ni)
    if (!rst_ni)
    begin
        state      <= ST_IDLE;
        pop_o      <= 1'b0;

        sr         <= {$bits(sr){1'bx}};
        sout       <= 1'b1;                                                       //drive Tx high when idle
        cnt        <= 5'h0;
        bitcnt     <= 3'h0;

        sr_empty_o <= 1'b1;                                                       //Transmit Shift Register Empty
    end
    else
    begin
        pop_o <= 1'b0;

        if (baudout_i)
        begin
            cnt <= cnt -1;

            case (state)
              //wait until there's data in the Tx FIFO/Register and the stop-bit has been trasmitted
              ST_IDLE : if (~|cnt)
                        begin
                            if (!csr.lsr.thre)
                            begin
                                state      <= ST_START; 

                                pop_o      <= 1'b1;                                //pop byte from FIFO
                                sr         <= d_i;                                 //store databyte in shiftregister
                                sr_empty_o <= 1'b0;

                                case (csr.lcr.wls)
                                  wls_5bits: data_parity <= ^d_i[4:0];
                                  wls_6bits: data_parity <= ^d_i[5:0];
                                  wls_7bits: data_parity <= ^d_i[6:0];
                                  wls_8bits: data_parity <= ^d_i[7:0];
                                endcase

                                bitcnt     <= {1'b1,csr_i.lcr.wls};

                                sout       <= 1'b0;                                //start bit = '0'
                                cnt        <= 5'd15;                               //start bit is 16 baudout cycles
                            end
                         end


              //wait for start bit transmission to complete
              ST_START : if (~|cnt)
                         begin
                             state  <= ST_BYTE;

                             //first databit to transfer
                             //Transfer LSB first
                             sr     <= sr >> 1;
                             bitcnt <= bitcnt -1;

                             sout   <= sr[0];
                             cnt    <= 5'd15;                                      //data bit is 16 baudout cycles
                         end


              //wait for all databits to transmit
              ST_BYTE  : if (~|cnt)
                         begin
                             //transmit next bit
                             sr   <= sr >> 1;
                             bitcnt <= bitcnt -1;
                             sout   <= sr[0];
                             cnt    <= 5'd15;                                      //databit is 16 baudout cycles


                             //have all bits been transmitted?
                             if (~|bitcnt)
                             begin
                                 sr_empty_o <= 1'b1;                               //Transmit Shift Register is empty

                                 if (csr_i.lcr.pen)
                                 begin
                                     state <= ST_PARITY;

                                     case ({csr_i.lcr.stick_parity, csr_i.lcr.eps})
                                       2'b00: sout <= ~data_parity;                //odd parity
                                       2'b01: sout <=  data_parity;                //even parity
                                       2'b10: sout <= 1'b1;                        //forced 1
                                       2'b11: sout <= 1'b0;                        //forced 0
                                     endcase
                                     cnt   <= 5'd15;                               //Parity is 16 baudout cycles
                                 end
                                 else
                                 begin
                                     state <= ST_IDLE;

                                     sout  <= 1'b1;                                //stop bit = '1'
                                     cnt   <= !csr_i.lcr.stb ? 5'd15      :        //1 stop bit
                                               csr_i.lcr.wls == wls_5bits ? 5'd17  //1.5 stop bits
                                                                          : 5'd31; //2 stop bits
                                 end
                             end
                         end


              ST_PARITY: if (~|cnt)
                         begin
                             state <= ST_IDLE;

                             sout  <= 1'b1;                                        //stop bit = '1'
                             cnt   <= !csr_i.lcr.stb ? 5'd15      :                //1 stop bit
                                       csr_i.lcr.wls == wls_5bits ? 5'd23          //1.5 stop bits
                                                                  : 5'd31;         //2 stop bits
                         end

            endcase //state
        end //if baudout_i
    end


    //Generate serial output
    always @(posedge clk_i, negedge rst_ni)
      if (!rst_ni) sout_o <= 1'b1; //drive sout_o while idle
      else         sout_o <= sout & ~csr_i.lcr.set_break;

endmodule
