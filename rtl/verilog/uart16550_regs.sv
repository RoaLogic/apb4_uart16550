/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//    UART16550 Register Module                                    //
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
// FILE NAME      : uart16550_regs.sv
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
 * address  Read                        Write
 * ------------------------------------------------------------------
 * 0x0      Receive Buffer Register     Transmit Holding Register
 *                                      LSB of divisor Latch
 * 0x1                                  Interrupt Enable Register
 *                                      MSB of Divisor Latch
 * 0x2      Interrupt Ident Register    FIFO Control Register
 * 0x3                                  Line Control Register
 * 0x4                                  Modem Control Register
 * 0x5      Line Status Register
 * 0x6      Modem Status Register
 * 0x7      Scratchpad Register Read    Scratchpad Register Write
 *
 *
 * Addr RW Register                         Bit7      Bit6       Bit5       Bit4       Bit3       Bit2       Bit1       Bit0
 * ------------------------------------------------------------------------------------------------------------------------------+
 * 0x0  R  Receive Buffer Register    RBR  Databit7 | Databit6 | Databit5 | Databit4 | Databit3 | Databit2 | Databit1 | Databit0 |
 * 0x0  W  Transmit Holding Register  THR  Databit7 | Databit6 | Databit5 | Databit4 | Databit3 | Databit2 | Databit1 | Databit0 |
 * 0x1  RW Interrupt Enable Register  IER  0        | 0        | 0        | 0        | EDSSI    | ELSI     | ETBEI    | EFBI     |
 * 0x2  R  Interrupt Ident Register   IIR  FIFOs En | FIFOs En | 0        | 0        | IIDbit2  | IIDbit1  | IIDbit0  | IntPend  |
 * 0x2  W  FIFO Control Register      FCR  RxTrig1  | RxTrig0  | reserved | reserved | DMA Mode | TxFIFORst| RxFIFORst| FIFO Ena |
 * 0x3  RW Line Control Register      LCR  DLAB     | Set Break| StkParity| EPS      | PEN      | STB      | WLS1     | WLS0     |
 * 0x4  RW Modem Control Register     MCR  0        | 0        | AFE      | Loop     | Out2     | Out1     | RTS      | DTR      |
 * 0x5  R  Line Status Register       LSR  RxFIFOErr| TEMT     | THRE     | BI       | FE       | PE       | OE       | DR       |
 * 0x6  R  Modem Status Register      MSR  DCD      | RI       | DSR      | CTS      | DDCD     | TERI     | DDSR     | DCTS     |
 * 0x7  RW Scratchpad Register        SCR  Bit7     | Bit6     | Bit5     | Bit4     | Bit3     | Bit2     | Bit1     | Bit0     |
 *
 * DLAB=1
 * 0x0  RW Divisor Latch LSB          DLL  Bit7     | Bit6     | Bit5     | Bit4     | Bit3     | Bit2     | Bit1     | Bit0     |
 * 0x1  RW Divisor Latch MSB          DLM  Bit15    | Bit14    | Bit13    | Bit12    | Bit11    | Bit10    | Bit9     | Bit8     |
 */

module uart16550_regs
import uart16550_pkg::*;
#(
  parameter [15:0] DL_RESET_VALUE  = 16'h44,
  parameter [ 1:0] WLS_RESET_VALUE =  2'b00,
  parameter        STB_RESET_VALUE =  1'b0,
  parameter        PEN_RESET_VALUE =  1'b0,
  parameter        EPS_RESET_VALUE =  1'b0
)
(
  input  logic       rst_ni,
  input  logic       clk_i,

  input  logic [2:0] adr_i,
  input  logic [7:0] d_i,
  output logic [7:0] q_o,
  input  logic       re_i,
  input  logic       we_i,

  output csr_t       csr_o,

  output logic       baudout_o,

  output logic       rts_no,
  input  logic       cts_ni,

  output logic       dtr_no,
  input  logic       dsr_ni,

  input  logic       dcd_ni,
  input  logic       ri_ni,

  output logic       txrdy_no,
  output logic       rxrdy_no,

  output logic       out1_no,
  output logic       out2_no,

  output logic       irq_o,

  //Tx status signals
  input  logic       tx_empty_i,
  output logic       tx_push_o,
  input  logic       tx_sr_empty_i,


  //Rx status signals
  input  logic       rx_empty_i,
  output logic       rx_pop_o,
  input  rx_d_t      rx_q_i,
  input  logic       overrun_error_i,
  input  logic       rx_fifo_error_i,
  output logic [3:0] rx_trigger_lvl_o,
  input  logic       rx_trigger_i
);

  //////////////////////////////////////////////////////////////////
  //
  // Functions
  //
`ifdef VERILATOR
  import "DPI-C" context function void getScope();
  initial getScope();


  /**
   * @brief DPI function to peek CSRs
   */
  export "DPI-C" function uart16550_peek;
  function byte uart16550_peek(input byte r);
  begin
      byte result;

      case(r)
          {4'h0,1'b0, RBR_ADR}: result = rx_q_i.d; //read only register
//          {4'h0,1'b0, THR_ADR}: result = csr.thr;
          {4'h0,1'b0, IER_ADR}: result = csr.ier;
          {4'h0,1'b0, IIR_ADR}: result = csr.iir;  //read only register
          {4'h1,1'b0, FCR_ADR}: result = csr.fcr;  //write only register
          {4'h0,1'b0, LCR_ADR}: result = csr.lcr;
          {4'h0,1'b0, MCR_ADR}: result = csr.mcr;
          {4'h0,1'b0, LSR_ADR}: result = csr.lsr;
          {4'h0,1'b0, MSR_ADR}: result = csr.msr;
          {4'h0,1'b0, SCR_ADR}: result = csr.scr;

          {4'h2,1'b0, DLL_ADR}: result = dl.dll;
          {4'h2,1'b0, DLM_ADR}: result = dl.dlm;
          default             : result = 0;
      endcase

      return result;
  end
  endfunction


  /**
   * @brief DPI task to poke CSRs
   */
  export "DPI-C" task uart16550_poke;
  task uart16550_poke(input byte r, input byte d);
  begin
      case(r)
          {4'h0,1'b0, IER_ADR}: begin force csr.ier = d; release csr.ier; end
          {4'h0,1'b0, IIR_ADR}: begin force csr.iir = d; release csr.iir; end
          {4'h1,1'b0, FCR_ADR}:       force csr.fcr = d;
          {4'h0,1'b0, LCR_ADR}: begin force csr.lcr = d; release csr.lcr; end
          {4'h0,1'b0, MCR_ADR}: begin force csr.mcr = d; release csr.mcr; end
          {4'h0,1'b0, LSR_ADR}:       force csr.lsr = d;
          {4'h0,1'b0, MSR_ADR}:       force csr.msr = d;
          {4'h0,1'b0, SCR_ADR}: begin force csr.scr = d; release csr.scr; end

          {4'h2,1'b0, DLL_ADR}: begin force dl.dll  = d; release dl.dll;  end
          {4'h2,1'b0, DLM_ADR}: begin force dl.dlm  = d; release dl.dlm;  end
          default             : ;                                              //some registers are simply not pokeable
      endcase
  end
  endtask


  /**
   * @brief DPI task to release CSR registers from force
   */
  export "DPI-C" task uart16550_release;
  task uart16550_release(input byte r);
  begin
      case(r)
          {4'h0,1'b0, IIR_ADR}: release csr.iir;
          {4'h1,1'b0, FCR_ADR}: release csr.fcr;
          {4'h0,1'b0, LSR_ADR}: release csr.lsr;
          {4'h0,1'b0, MSR_ADR}: release csr.msr;
          default             : ;                //no need to release other registers (already released)
      endcase
  end
  endtask
`endif

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  csr_t        csr;         //Control and Status registers
  dl_t         dl;          //Baud counter value
  logic [15:0] baud_cnt;    //baudout counter

  logic        write_thr;   //write to Transmit Hold Register
  logic        read_rbr,
               read_lsr,
               read_msr;

  logic        doe,
               dpe,
               dfe,
               dbi;

  logic        d_dcd_ni,
               d_ri_ni,
               d_dsr_ni,
               d_cts_ni;

  logic        ld_baud_cnt;

  
  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  //Drive CSRs out
  assign csr_o = csr;


  //TODO
  assign txrdy_no = 1'b1;
  assign rxrdy_no = 1'b1;


  /*
   * Register Accesses
   *
   * address  Read                        Write
   * ------------------------------------------------------------------
   * 0x0      Receive Buffer Register     Transmit Holding Register
   *                                      LSB of divisor Latch
   * 0x1                                  Interrupt Enable Register
   *                                      MSB of Divisor Latch
   * 0x2      Interrupt Ident Register    FIFO Control Register
   * 0x3                                  Line Control Register
   * 0x4                                  Modem Control Register
   * 0x5      Line Status Register
   * 0x6      Modem Status Register
   * 0x7      Scratchpad Register Read    Scratchpad Register Write
   */


  /*
   * Writeable Registers
   */

  //THR Transmit Holding Register
  //Not affected by MR (Master Reset = rst_ni)

  assign write_thr = we_i & (adr_i == THR_ADR);
  assign tx_push_o = write_thr;

  //IER Interrupt Enable Register
  always @(posedge clk_i, negedge rst_ni)
    if      (!rst_ni                  ) csr.ier <= 8'h00;
    else if ( we_i && adr_i == IER_ADR &&
             !csr.lcr.dlab            ) csr.ier <= d_i & 8'h0F; //Bits7:4 always zero

  //FCR FIFO Control Register
  always @(posedge clk_i, negedge rst_ni)
    if      (!rst_ni                  ) csr.fcr <= 8'h00;
    else if ( we_i && adr_i == FCR_ADR)
    begin
        csr.fcr.rx_trigger <= rxtrigger_t'(d_i[7:6]);
        csr.fcr.dma_mode   <= d_i[  3];
        csr.fcr.tx_rst     <= d_i[  2];
        csr.fcr.rx_rst     <= d_i[  1];
        csr.fcr.ena        <= d_i[  0];
    end
    else
    begin
        //FIFO reset bits are self clearing
        //FIFOs remain in reset when fifo_enable=0
        csr.fcr.rx_rst <= 1'b0;
        csr.fcr.tx_rst <= 1'b0;
    end

  //decode rx_trigger
  always_comb
    if (!csr.fcr.ena) rx_trigger_lvl_o = 4'd0;
    else
      case (csr.fcr.rx_trigger)
        rxtrigger01: rx_trigger_lvl_o = 4'd1;
        rxtrigger04: rx_trigger_lvl_o = 4'd4;
        rxtrigger08: rx_trigger_lvl_o = 4'd8;
        rxtrigger14: rx_trigger_lvl_o = 4'd14;
      endcase


  //LCR Line Control Register
  always @(posedge clk_i, negedge rst_ni)
    if      (!rst_ni                  ) csr.lcr <= 8'h00;
    else if ( we_i && adr_i == LCR_ADR) csr.lcr <= d_i;


  //MCR Modem Control Register
  always @(posedge clk_i, negedge rst_ni)
    if      (!rst_ni                  ) csr.mcr <= 8'h00;
    else if ( we_i && adr_i == MCR_ADR) csr.mcr <= d_i & 8'h0F; //Bits7:4 always zero


  //SCR Scratchpad Register
  always @(posedge clk_i, negedge rst_ni)
    if      (!rst_ni                 ) csr.scr <= 8'h00;
    else if (we_i && adr_i == SCR_ADR) csr.scr <= d_i;



  //DLL Divisor Latch LSB Register
  //Per spec not affected by MR (Master Reset = rst_ni), which doesn't make
  //much sense for an IP
  always @(posedge clk_i, negedge rst_ni)
    if      (!rst_ni             ) dl.dll <= DL_RESET_VALUE[7:0];
    else if ( we_i && adr_i == DLL_ADR &&
         csr.lcr.dlab            ) dl.dll <= d_i;


  //DLM Divisor Latch MSB Register
  //Per spec not affected by MR (Master Reset = rst_ni), which doesn't make
  //much sense for an IP
  always @(posedge clk_i, negedge rst_ni)
    if      (!rst_ni             ) dl.dlm <= DL_RESET_VALUE[15:8];
    else if ( we_i && adr_i == DLM_ADR &&
         csr.lcr.dlab            ) dl.dlm <= d_i;


  /*
   *  Read Registers
   */
  always @(posedge clk_i)
    case (adr_i)
      RBR_ADR : q_o <= csr.lcr.dlab ? dl.dll
                                    : rx_q_i.d;
      IER_ADR : q_o <= csr.lcr.dlab ? dl.dlm
                                    : csr.ier;
      IIR_ADR : q_o <= csr.iir;
      LCR_ADR : q_o <= csr.lcr;
      MCR_ADR : q_o <= csr.mcr;
      LSR_ADR : q_o <= csr.lsr;
      MSR_ADR : q_o <= csr.msr;
      SCR_ADR : q_o <= csr.scr;
      default : q_o <= 8'hx;
    endcase

  //some MSR bits are cleared upon reading MSR
  assign read_msr = re_i & (adr_i == MSR_ADR);

  //some LSR bits are cleared upon reading LSR
  assign read_lsr = re_i & (adr_i == LSR_ADR);

  //some LSR bits are cleared upon reading RBR
  assign read_rbr = re_i & (adr_i == RBR_ADR);
  assign rx_pop_o = read_rbr;


  /*
   * Encode Line Status Register
   */
  always @(posedge clk_i)
    begin
        doe <= overrun_error_i;
        dpe <= rx_q_i.pe;
        dfe <= rx_q_i.fe;
        dbi <= rx_q_i.bi;
    end


  always @(posedge clk_i, negedge rst_ni)
    if (!rst_ni) csr.lsr <= 8'h60;
    else
    begin
        csr.lsr.dr            <= ~rx_empty_i;
        csr.lsr.oe            <= (overrun_error_i & ~doe) | (csr.lsr.oe & ~read_lsr);
        csr.lsr.pe            <= (rx_q_i.pe  & ~dpe) | (csr.lsr.pe & ~read_lsr);
        csr.lsr.fe            <= (rx_q_i.fe  & ~dfe) | (csr.lsr.fe & ~read_lsr);;
        csr.lsr.bi            <= (rx_q_i.bi  & ~dbi) | (csr.lsr.bi & ~read_lsr);
        csr.lsr.thre          <= tx_empty_i;
        csr.lsr.temt          <= tx_empty_i & tx_sr_empty_i;
        csr.lsr.rx_fifo_error <= rx_fifo_error_i & csr.fcr.ena;
    end


  /*
   * Decode Modem Control Register 
   */
  assign out2_no = ~csr.mcr.out2;
  assign out1_no = ~csr.mcr.out1;
  assign rts_no  = ~csr.mcr.rts;
  assign dtr_no  = ~csr.mcr.dtr;



  /*
   * Encode Modem Status Register 
   */
   
   //Delay modem status inputs
   always @(posedge clk_i)
     begin
         d_dcd_ni <= dcd_ni;
         d_ri_ni  <= ri_ni;
         d_dsr_ni <= dsr_ni;
         d_cts_ni <= cts_ni;
     end


   //Generate MSR register
   always @(posedge clk_i, negedge rst_ni)
     if (!rst_ni) csr.msr <= 8'h00;
     else
     begin
         csr.msr.dcd  <= csr.mcr.loop ? csr.mcr.out2 : ~dcd_ni;
         csr.msr.ri   <= csr.mcr.loop ? csr.mcr.out1 : ~ri_ni;
         csr.msr.dsr  <= csr.mcr.loop ? csr.mcr.dtr  : ~dsr_ni;
         csr.msr.cts  <= csr.mcr.loop ? csr.mcr.rts  : ~cts_ni;
         csr.msr.ddcd <= (dcd_ni ^  d_dcd_ni) | (csr.msr.ddcd & ~read_msr); //detect state change and hold
         csr.msr.teri <= (ri_ni  & ~d_ri_ni ) | (csr.msr.teri & ~read_msr); //detect rising edge and hold
         csr.msr.ddsr <= (dsr_ni ^  d_dsr_ni) | (csr.msr.ddsr & ~read_msr); //detect state change and hold
         csr.msr.dcts <= (cts_ni ^  d_cts_ni) | (csr.msr.dcts & ~read_msr); //detect state change and hold
     end


  /*
   * Interrupt
   */
  always @(posedge clk_i, negedge rst_ni)
    if (!rst_ni) irq_o <= 1'b0;
    else         irq_o <= (csr.ier.edssi & |csr.msr[3:0]) |                //Modem Status Interrupt
                          (csr.ier.elsi  & |csr.lsr[4:1]) |                //Line Status Interrupt
                          (csr.ier.etbei &  csr.lsr.thre) |                //Transmit Holding Register Empty Interrupt
                          (csr.ier.erbi  & (csr.fcr.ena ? rx_trigger_i
                                                        : csr.lsr.dr) );   //Received Data Available Interrupt

  /*
   * Encode IIR register
   */
  always @(posedge clk_i, negedge rst_ni)
    if (!rst_ni) csr.iir <= 8'h0;
    else         csr.iir <= 8'h0;


  /*
   * Baud Generator
   *
   * The 16550 outputs a 16x 50/50 clock used as baudclock
   * The IP generates a 16x clock enable signal instead
   */

  //Load baud counter when either of the Divisor Latch register are loaded (written to)
  //Use a register as a delay. Ensure csr.dl is actually loaded before taking over the new value
  always @(posedge clk_i)
    ld_baud_cnt <= we_i & csr.lcr.dlab & (adr_i == DLL_ADR | adr_i == DLM_ADR);


  //generate baud counter
  always @(posedge clk_i, negedge rst_ni)
    if (!rst_ni)
      baud_cnt  <= 16'h0;
    else if (ld_baud_cnt || ~|baud_cnt)
      baud_cnt <= dl -1;
    else
      baud_cnt <= baud_cnt -1;

  //generate baudout
  always @(posedge clk_i)
    baudout_o <= |dl & ~|baud_cnt;

endmodule
