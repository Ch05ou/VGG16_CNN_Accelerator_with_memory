/* FE Release Version: 3.4.22 */
/* lang compiler Version: 3.0.4 */
//
//       CONFIDENTIAL AND PROPRIETARY SOFTWARE OF ARM PHYSICAL IP, INC.
//      
//       Copyright (c) 1993 - 2024 ARM Physical IP, Inc.  All Rights Reserved.
//      
//       Use of this Software is subject to the terms and conditions of the
//       applicable license agreement with ARM Physical IP, Inc.
//       In addition, this Software is protected by patents, copyright law 
//       and international treaties.
//      
//       The copyright notice(s) in this Software does not indicate actual or
//       intended publication of this Software.
//
//      Verilog model for Synchronous Single-Port Ram
//
//       Instance Name:              input_sram
//       Words:                      16384
//       Bits:                       8
//       Mux:                        32
//       Drive:                      6
//       Write Mask:                 Off
//       Write Thru:                 On
//       Extra Margin Adjustment:    On
//       Redundant Rows:             0
//       Redundant Columns:          0
//       Test Muxes                  On
//       Power Gating:               Off
//       Retention:                  On
//       Pipeline:                   Off
//       Weak Bit Test:	        Off
//       Read Disturb Test:	        Off
//       
//       Creation Date:  Sat Dec 14 18:22:17 2024
//       Version: 	r11p2
//
//      Modeling Assumptions: This model supports full gate level simulation
//          including proper x-handling and timing check behavior.  Unit
//          delay timing is included in the model. Back-annotation of SDF
//          (v3.0 or v2.1) is supported.  SDF can be created utilyzing the delay
//          calculation views provided with this generator and supported
//          delay calculators.  All buses are modeled [MSB:LSB].  All 
//          ports are padded with Verilog primitives.
//
//      Modeling Limitations: None.
//
//      Known Bugs: None.
//
//      Known Work Arounds: N/A
//
`timescale 1 ns/1 ps
// If ARM_UD_MODEL is defined at Simulator Command Line, it Selects the Fast Functional Model
`ifdef ARM_UD_MODEL

// Following parameter Values can be overridden at Simulator Command Line.

// ARM_UD_DP Defines the delay through Data Paths, for Memory Models it represents BIST MUX output delays.
`ifdef ARM_UD_DP
`else
`define ARM_UD_DP #0.001
`endif
// ARM_UD_CP Defines the delay through Clock Path Cells, for Memory Models it is not used.
`ifdef ARM_UD_CP
`else
`define ARM_UD_CP
`endif
// ARM_UD_SEQ Defines the delay through the Memory, for Memory Models it is used for CLK->Q delays.
`ifdef ARM_UD_SEQ
`else
`define ARM_UD_SEQ #0.01
`endif

`celldefine
// If POWER_PINS is defined at Simulator Command Line, it selects the module definition with Power Ports
`ifdef POWER_PINS
module input_sram (VDDCE, VDDPE, VSSE, CENY, WENY, AY, DY, Q, CLK, CEN, WEN, A, D,
    EMA, EMAW, EMAS, TEN, BEN, TCEN, TWEN, TA, TD, TQ, RET1N, STOV);
`else
module input_sram (CENY, WENY, AY, DY, Q, CLK, CEN, WEN, A, D, EMA, EMAW, EMAS, TEN,
    BEN, TCEN, TWEN, TA, TD, TQ, RET1N, STOV);
`endif

  parameter ASSERT_PREFIX = "";
  parameter BITS = 8;
  parameter WORDS = 16384;
  parameter MUX = 32;
  parameter MEM_WIDTH = 256; // redun block size 4, 128 on left, 128 on right
  parameter MEM_HEIGHT = 512;
  parameter WP_SIZE = 8 ;
  parameter UPM_WIDTH = 3;
  parameter UPMW_WIDTH = 2;
  parameter UPMS_WIDTH = 1;

  output  CENY;
  output  WENY;
  output [13:0] AY;
  output [7:0] DY;
  output [7:0] Q;
  input  CLK;
  input  CEN;
  input  WEN;
  input [13:0] A;
  input [7:0] D;
  input [2:0] EMA;   // 0
  input [1:0] EMAW;  // 0
  input  EMAS;       // 0
  input  TEN;        // 1
  input  BEN;        // 1
  input  TCEN;       // 1
  input  TWEN;       // 1
  input [13:0] TA;   // 0
  input [7:0] TD;    // 0
  input [7:0] TQ;    // 0
  input  RET1N;      // 1
  input  STOV;       // 0
`ifdef POWER_PINS
  inout VDDCE;
  inout VDDPE;
  inout VSSE;
`endif

  integer row_address;
  integer mux_address;
  reg [255:0] mem [0:511];
  reg [255:0] row;
  reg LAST_CLK;
  reg [255:0] row_mask;
  reg [255:0] new_data;
  reg [255:0] data_out;
  reg [63:0] readLatch0;
  reg [63:0] shifted_readLatch0;
  reg [2:0] read_mux_sel0;
  reg [7:0] Q_int;
  reg [7:0] Q_int_delayed;
  reg [7:0] writeEnable;

  reg NOT_CEN, NOT_WEN, NOT_A13, NOT_A12, NOT_A11, NOT_A10, NOT_A9, NOT_A8, NOT_A7;
  reg NOT_A6, NOT_A5, NOT_A4, NOT_A3, NOT_A2, NOT_A1, NOT_A0, NOT_D7, NOT_D6, NOT_D5;
  reg NOT_D4, NOT_D3, NOT_D2, NOT_D1, NOT_D0, NOT_EMA2, NOT_EMA1, NOT_EMA0, NOT_EMAW1;
  reg NOT_EMAW0, NOT_EMAS, NOT_TEN, NOT_TCEN, NOT_TWEN, NOT_TA13, NOT_TA12, NOT_TA11;
  reg NOT_TA10, NOT_TA9, NOT_TA8, NOT_TA7, NOT_TA6, NOT_TA5, NOT_TA4, NOT_TA3, NOT_TA2;
  reg NOT_TA1, NOT_TA0, NOT_TD7, NOT_TD6, NOT_TD5, NOT_TD4, NOT_TD3, NOT_TD2, NOT_TD1;
  reg NOT_TD0, NOT_RET1N, NOT_STOV;
  reg NOT_CLK_PER, NOT_CLK_MINH, NOT_CLK_MINL;
  reg clk0_int;

  wire  CENY_;
  wire  WENY_;
  wire [13:0] AY_;
  wire [7:0] DY_;
  wire [7:0] Q_;
 wire  CLK_;
  wire  CEN_;
  reg  CEN_int;
  reg  CEN_p2;
  wire  WEN_;
  reg  WEN_int;
  wire [13:0] A_;
  reg [13:0] A_int;
  wire [7:0] D_;
  reg [7:0] D_int;
  wire [2:0] EMA_;
  reg [2:0] EMA_int;
  wire [1:0] EMAW_;
  reg [1:0] EMAW_int;
  wire  EMAS_;
  reg  EMAS_int;
  wire  TEN_;
  reg  TEN_int;
  wire  BEN_;
  reg  BEN_int;
  wire  TCEN_;
  reg  TCEN_int;
  reg  TCEN_p2;
  wire  TWEN_;
  reg  TWEN_int;
  wire [13:0] TA_;
  reg [13:0] TA_int;
  wire [7:0] TD_;
  reg [7:0] TD_int;
  wire [7:0] TQ_;
  reg [7:0] TQ_int;
  wire  RET1N_;
  reg  RET1N_int;
  wire  STOV_;
  reg  STOV_int;

  assign CENY = CENY_; 
  assign WENY = WENY_; 
  assign AY[0] = AY_[0]; 
  assign AY[1] = AY_[1]; 
  assign AY[2] = AY_[2]; 
  assign AY[3] = AY_[3]; 
  assign AY[4] = AY_[4]; 
  assign AY[5] = AY_[5]; 
  assign AY[6] = AY_[6]; 
  assign AY[7] = AY_[7]; 
  assign AY[8] = AY_[8]; 
  assign AY[9] = AY_[9]; 
  assign AY[10] = AY_[10]; 
  assign AY[11] = AY_[11]; 
  assign AY[12] = AY_[12]; 
  assign AY[13] = AY_[13]; 
  assign DY[0] = DY_[0]; 
  assign DY[1] = DY_[1]; 
  assign DY[2] = DY_[2]; 
  assign DY[3] = DY_[3]; 
  assign DY[4] = DY_[4]; 
  assign DY[5] = DY_[5]; 
  assign DY[6] = DY_[6]; 
  assign DY[7] = DY_[7]; 
  assign Q[0] = Q_[0]; 
  assign Q[1] = Q_[1]; 
  assign Q[2] = Q_[2]; 
  assign Q[3] = Q_[3]; 
  assign Q[4] = Q_[4]; 
  assign Q[5] = Q_[5]; 
  assign Q[6] = Q_[6]; 
  assign Q[7] = Q_[7]; 
  assign CLK_ = CLK;
  assign CEN_ = CEN;
  assign WEN_ = WEN;
  assign A_[0] = A[0];
  assign A_[1] = A[1];
  assign A_[2] = A[2];
  assign A_[3] = A[3];
  assign A_[4] = A[4];
  assign A_[5] = A[5];
  assign A_[6] = A[6];
  assign A_[7] = A[7];
  assign A_[8] = A[8];
  assign A_[9] = A[9];
  assign A_[10] = A[10];
  assign A_[11] = A[11];
  assign A_[12] = A[12];
  assign A_[13] = A[13];
  assign D_[0] = D[0];
  assign D_[1] = D[1];
  assign D_[2] = D[2];
  assign D_[3] = D[3];
  assign D_[4] = D[4];
  assign D_[5] = D[5];
  assign D_[6] = D[6];
  assign D_[7] = D[7];
  assign EMA_[0] = EMA[0];
  assign EMA_[1] = EMA[1];
  assign EMA_[2] = EMA[2];
  assign EMAW_[0] = EMAW[0];
  assign EMAW_[1] = EMAW[1];
  assign EMAS_ = EMAS;
  assign TEN_ = TEN;
  assign BEN_ = BEN;
  assign TCEN_ = TCEN;
  assign TWEN_ = TWEN;
  assign TA_[0] = TA[0];
  assign TA_[1] = TA[1];
  assign TA_[2] = TA[2];
  assign TA_[3] = TA[3];
  assign TA_[4] = TA[4];
  assign TA_[5] = TA[5];
  assign TA_[6] = TA[6];
  assign TA_[7] = TA[7];
  assign TA_[8] = TA[8];
  assign TA_[9] = TA[9];
  assign TA_[10] = TA[10];
  assign TA_[11] = TA[11];
  assign TA_[12] = TA[12];
  assign TA_[13] = TA[13];
  assign TD_[0] = TD[0];
  assign TD_[1] = TD[1];
  assign TD_[2] = TD[2];
  assign TD_[3] = TD[3];
  assign TD_[4] = TD[4];
  assign TD_[5] = TD[5];
  assign TD_[6] = TD[6];
  assign TD_[7] = TD[7];
  assign TQ_[0] = TQ[0];
  assign TQ_[1] = TQ[1];
  assign TQ_[2] = TQ[2];
  assign TQ_[3] = TQ[3];
  assign TQ_[4] = TQ[4];
  assign TQ_[5] = TQ[5];
  assign TQ_[6] = TQ[6];
  assign TQ_[7] = TQ[7];
  assign RET1N_ = RET1N;
  assign STOV_ = STOV;

  assign `ARM_UD_DP CENY_ = RET1N_ ? (TEN_ ? CEN_ : TCEN_) : 1'bx;
  assign `ARM_UD_DP WENY_ = RET1N_ ? (TEN_ ? WEN_ : TWEN_) : 1'bx;
  assign `ARM_UD_DP AY_ = RET1N_ ? (TEN_ ? A_ : TA_) : {14{1'bx}};
  assign `ARM_UD_DP DY_ = RET1N_ ? (TEN_ ? D_ : TD_) : {8{1'bx}};
  assign `ARM_UD_SEQ Q_ = RET1N_ ? (BEN_ ? ((STOV_ ? (Q_int_delayed) : (Q_int))) : TQ_) : {8{1'bx}};

// If INITIALIZE_MEMORY is defined at Simulator Command Line, it Initializes the Memory with all ZEROS.
`ifdef INITIALIZE_MEMORY
  integer i;
  initial
    for (i = 0; i < MEM_HEIGHT; i = i + 1)
      mem[i] = {MEM_WIDTH{1'b0}};
`endif

  task failedWrite;
  input port_f;
  integer i;
  begin
    for (i = 0; i < MEM_HEIGHT; i = i + 1)
      mem[i] = {MEM_WIDTH{1'bx}};
  end
  endtask

  function isBitX;
    input bitval;
    begin
      isBitX = ( bitval===1'bx || bitval==1'bz ) ? 1'b1 : 1'b0;
    end
  endfunction


task loadmem;
	input [1000*8-1:0] filename;
	reg [BITS-1:0] memld [0:WORDS-1];
	integer i;
	reg [BITS-1:0] wordtemp;
	reg [13:0] Atemp;
  begin
	$readmemb(filename, memld);
     if (CEN_ === 1'b1) begin
	  for (i=0;i<WORDS;i=i+1) begin
	  wordtemp = memld[i];
	  Atemp = i;
	  mux_address = (Atemp & 5'b11111);
      row_address = (Atemp >> 5);
      row = mem[row_address];
        writeEnable = {8{1'b1}};
        row_mask =  ( {31'b0000000000000000000000000000000, writeEnable[7], 31'b0000000000000000000000000000000, writeEnable[6],
          31'b0000000000000000000000000000000, writeEnable[5], 31'b0000000000000000000000000000000, writeEnable[4],
          31'b0000000000000000000000000000000, writeEnable[3], 31'b0000000000000000000000000000000, writeEnable[2],
          31'b0000000000000000000000000000000, writeEnable[1], 31'b0000000000000000000000000000000, writeEnable[0]} << mux_address);
        new_data =  ( {31'b0000000000000000000000000000000, wordtemp[7], 31'b0000000000000000000000000000000, wordtemp[6],
          31'b0000000000000000000000000000000, wordtemp[5], 31'b0000000000000000000000000000000, wordtemp[4],
          31'b0000000000000000000000000000000, wordtemp[3], 31'b0000000000000000000000000000000, wordtemp[2],
          31'b0000000000000000000000000000000, wordtemp[1], 31'b0000000000000000000000000000000, wordtemp[0]} << mux_address);
        row = (row & ~row_mask) | (row_mask & (~row_mask | new_data));
        mem[row_address] = row;
  	end
  end
  end
  endtask

task dumpmem;
	input [1000*8-1:0] filename_dump;
	integer i, dump_file_desc;
	reg [BITS-1:0] wordtemp;
	reg [13:0] Atemp;
  begin
	dump_file_desc = $fopen(filename_dump);
     if (CEN_ === 1'b1) begin
	  for (i=0;i<WORDS;i=i+1) begin
	  Atemp = i;
	  mux_address = (Atemp & 5'b11111);
      row_address = (Atemp >> 5);
      row = mem[row_address];
        writeEnable = {8{1'b1}};
        data_out = (row >> (mux_address));
        readLatch0 = {data_out[252], data_out[248], data_out[244], data_out[240], data_out[236],
          data_out[232], data_out[228], data_out[224], data_out[220], data_out[216],
          data_out[212], data_out[208], data_out[204], data_out[200], data_out[196],
          data_out[192], data_out[188], data_out[184], data_out[180], data_out[176],
          data_out[172], data_out[168], data_out[164], data_out[160], data_out[156],
          data_out[152], data_out[148], data_out[144], data_out[140], data_out[136],
          data_out[132], data_out[128], data_out[124], data_out[120], data_out[116],
          data_out[112], data_out[108], data_out[104], data_out[100], data_out[96],
          data_out[92], data_out[88], data_out[84], data_out[80], data_out[76], data_out[72],
          data_out[68], data_out[64], data_out[60], data_out[56], data_out[52], data_out[48],
          data_out[44], data_out[40], data_out[36], data_out[32], data_out[28], data_out[24],
          data_out[20], data_out[16], data_out[12], data_out[8], data_out[4], data_out[0]};
        shifted_readLatch0 = readLatch0;
        Q_int = {shifted_readLatch0[56], shifted_readLatch0[48], shifted_readLatch0[40],
          shifted_readLatch0[32], shifted_readLatch0[24], shifted_readLatch0[16], shifted_readLatch0[8],
          shifted_readLatch0[0]};
   	$fdisplay(dump_file_desc, "%b", Q_int);
  end
  	end
//    $fclose(filename_dump);
  end
  endtask


  task readWrite;
  begin
    if (RET1N_int === 1'bx || RET1N_int === 1'bz) begin
      failedWrite(0);
      Q_int = {8{1'bx}};
    end else if (RET1N_int === 1'b0 && CEN_int === 1'b0) begin
      failedWrite(0);
      Q_int = {8{1'bx}};
    end else if (RET1N_int === 1'b0) begin
      // no cycle in retention mode
    end else if (^{CEN_int, EMA_int, EMAW_int, EMAS_int, RET1N_int, (STOV_int && !CEN_int)} 
     === 1'bx) begin
      failedWrite(0);
      Q_int = {8{1'bx}};
    end else if ((A_int >= WORDS) && (CEN_int === 1'b0)) begin
      Q_int = WEN_int !== 1'b1 ? D_int : {8{1'bx}};
      Q_int_delayed = WEN_int !== 1'b1 ? D_int : {8{1'bx}};
    end else if (CEN_int === 1'b0 && (^A_int) === 1'bx) begin
      failedWrite(0);
      Q_int = {8{1'bx}};
    end else if (CEN_int === 1'b0) begin
      mux_address = (A_int & 5'b11111);
      row_address = (A_int >> 5);
      if (row_address > 511)
        row = {256{1'bx}};
      else
        row = mem[row_address];
      writeEnable = ~{8{WEN_int}};
      if (WEN_int !== 1'b1) begin
        row_mask =  ( {31'b0000000000000000000000000000000, writeEnable[7], 31'b0000000000000000000000000000000, writeEnable[6],
          31'b0000000000000000000000000000000, writeEnable[5], 31'b0000000000000000000000000000000, writeEnable[4],
          31'b0000000000000000000000000000000, writeEnable[3], 31'b0000000000000000000000000000000, writeEnable[2],
          31'b0000000000000000000000000000000, writeEnable[1], 31'b0000000000000000000000000000000, writeEnable[0]} << mux_address);
        new_data =  ( {31'b0000000000000000000000000000000, D_int[7], 31'b0000000000000000000000000000000, D_int[6],
          31'b0000000000000000000000000000000, D_int[5], 31'b0000000000000000000000000000000, D_int[4],
          31'b0000000000000000000000000000000, D_int[3], 31'b0000000000000000000000000000000, D_int[2],
          31'b0000000000000000000000000000000, D_int[1], 31'b0000000000000000000000000000000, D_int[0]} << mux_address);
        row = (row & ~row_mask) | (row_mask & (~row_mask | new_data));
        mem[row_address] = row;
      end else begin
        data_out = (row >> (mux_address%4));
        readLatch0 = {data_out[252], data_out[248], data_out[244], data_out[240], data_out[236],
          data_out[232], data_out[228], data_out[224], data_out[220], data_out[216],
          data_out[212], data_out[208], data_out[204], data_out[200], data_out[196],
          data_out[192], data_out[188], data_out[184], data_out[180], data_out[176],
          data_out[172], data_out[168], data_out[164], data_out[160], data_out[156],
          data_out[152], data_out[148], data_out[144], data_out[140], data_out[136],
          data_out[132], data_out[128], data_out[124], data_out[120], data_out[116],
          data_out[112], data_out[108], data_out[104], data_out[100], data_out[96],
          data_out[92], data_out[88], data_out[84], data_out[80], data_out[76], data_out[72],
          data_out[68], data_out[64], data_out[60], data_out[56], data_out[52], data_out[48],
          data_out[44], data_out[40], data_out[36], data_out[32], data_out[28], data_out[24],
          data_out[20], data_out[16], data_out[12], data_out[8], data_out[4], data_out[0]};
      end
      if (WEN_int !== 1'b1) begin
        Q_int = D_int;
        Q_int_delayed = D_int;
      end else begin
        shifted_readLatch0 = (readLatch0 >> A_int[4:2]);
        Q_int = {shifted_readLatch0[56], shifted_readLatch0[48], shifted_readLatch0[40],
          shifted_readLatch0[32], shifted_readLatch0[24], shifted_readLatch0[16], shifted_readLatch0[8],
          shifted_readLatch0[0]};
      end
    end
  end
  endtask
  always @ (CEN_ or TCEN_ or TEN_ or CLK_) begin
  	if(CLK_ == 1'b0) begin
  		CEN_p2 = CEN_;
  		TCEN_p2 = TCEN_;
  	end
  end

  always @ RET1N_ begin
    if (CLK_ == 1'b1) begin
      failedWrite(0);
      Q_int = {8{1'bx}};
    end
    if (RET1N_ === 1'bx || RET1N_ === 1'bz) begin
      failedWrite(0);
      Q_int = {8{1'bx}};
    end else if (RET1N_ === 1'b0 && RET1N_int === 1'b1 && (CEN_p2 === 1'b0 || TCEN_p2 === 1'b0) ) begin
      failedWrite(0);
      Q_int = {8{1'bx}};
    end else if (RET1N_ === 1'b1 && RET1N_int === 1'b0 && (CEN_p2 === 1'b0 || TCEN_p2 === 1'b0) ) begin
      failedWrite(0);
      Q_int = {8{1'bx}};
    end
    if (RET1N_ == 1'b0) begin
      Q_int = {8{1'bx}};
      Q_int_delayed = {8{1'bx}};
      CEN_int = 1'bx;
      WEN_int = 1'bx;
      A_int = {14{1'bx}};
      D_int = {8{1'bx}};
      EMA_int = {3{1'bx}};
      EMAW_int = {2{1'bx}};
      EMAS_int = 1'bx;
      TEN_int = 1'bx;
      BEN_int = 1'bx;
      TCEN_int = 1'bx;
      TWEN_int = 1'bx;
      TA_int = {14{1'bx}};
      TD_int = {8{1'bx}};
      TQ_int = {8{1'bx}};
      RET1N_int = 1'bx;
      STOV_int = 1'bx;
    end else begin
      Q_int = {8{1'bx}};
      Q_int_delayed = {8{1'bx}};
      CEN_int = 1'bx;
      WEN_int = 1'bx;
      A_int = {14{1'bx}};
      D_int = {8{1'bx}};
      EMA_int = {3{1'bx}};
      EMAW_int = {2{1'bx}};
      EMAS_int = 1'bx;
      TEN_int = 1'bx;
      BEN_int = 1'bx;
      TCEN_int = 1'bx;
      TWEN_int = 1'bx;
      TA_int = {14{1'bx}};
      TD_int = {8{1'bx}};
      TQ_int = {8{1'bx}};
      RET1N_int = 1'bx;
      STOV_int = 1'bx;
    end
    RET1N_int = RET1N_;
  end


  always @ CLK_ begin
// If POWER_PINS is defined at Simulator Command Line, it selects the module definition with Power Ports
`ifdef POWER_PINS
    if (VDDCE === 1'bx || VDDCE === 1'bz)
      $display("ERROR: Illegal value for VDDCE %b", VDDCE);
    if (VDDPE === 1'bx || VDDPE === 1'bz)
      $display("ERROR: Illegal value for VDDPE %b", VDDPE);
    if (VSSE === 1'bx || VSSE === 1'bz)
      $display("ERROR: Illegal value for VSSE %b", VSSE);
`endif
  if (RET1N_ == 1'b0) begin
      // no cycle in retention mode
  end else begin
    if ((CLK_ === 1'bx || CLK_ === 1'bz) && RET1N_ !== 1'b0) begin
      failedWrite(0);
      Q_int = {8{1'bx}};
    end else if (CLK_ === 1'b1 && LAST_CLK === 1'b0) begin
      CEN_int = TEN_ ? CEN_ : TCEN_;
      EMA_int = EMA_;
      EMAW_int = EMAW_;
      EMAS_int = EMAS_;
      TEN_int = TEN_;
      BEN_int = BEN_;
      TWEN_int = TWEN_;
      TQ_int = TQ_;
      RET1N_int = RET1N_;
      STOV_int = STOV_;
      if (CEN_int != 1'b1) begin
        WEN_int = TEN_ ? WEN_ : TWEN_;
        A_int = TEN_ ? A_ : TA_;
        D_int = TEN_ ? D_ : TD_;
        TCEN_int = TCEN_;
        TA_int = TA_;
        TD_int = TD_;
        if (WEN_int === 1'b1)
          read_mux_sel0 = (TEN_ ? A_[4:2] : TA_[4:2] );
      end
      clk0_int = 1'b0;
      if (CEN_int === 1'b0 && WEN_int === 1'b1) 
         Q_int_delayed = {8{1'bx}};
    readWrite;
    end else if (CLK_ === 1'b0 && LAST_CLK === 1'b1) begin
      Q_int_delayed = Q_int;
    end
    LAST_CLK = CLK_;
  end
  end

endmodule
`endcelldefine
`else
`celldefine
// If POWER_PINS is defined at Simulator Command Line, it selects the module definition with Power Ports
`ifdef POWER_PINS
module input_sram (VDDCE, VDDPE, VSSE, CENY, WENY, AY, DY, Q, CLK, CEN, WEN, A, D,
    EMA, EMAW, EMAS, TEN, BEN, TCEN, TWEN, TA, TD, TQ, RET1N, STOV);
`else
module input_sram (CENY, WENY, AY, DY, Q, CLK, CEN, WEN, A, D, EMA, EMAW, EMAS, TEN,
    BEN, TCEN, TWEN, TA, TD, TQ, RET1N, STOV);
`endif

  parameter ASSERT_PREFIX = "";
  parameter BITS = 8;
  parameter WORDS = 16384;
  parameter MUX = 32;
  parameter MEM_WIDTH = 256; // redun block size 4, 128 on left, 128 on right
  parameter MEM_HEIGHT = 512;
  parameter WP_SIZE = 8 ;
  parameter UPM_WIDTH = 3;
  parameter UPMW_WIDTH = 2;
  parameter UPMS_WIDTH = 1;

  output  CENY;
  output  WENY;
  output [13:0] AY;
  output [7:0] DY;
  output [7:0] Q;
  input  CLK;
  input  CEN;
  input  WEN;
  input [13:0] A;
  input [7:0] D;
  input [2:0] EMA;
  input [1:0] EMAW;
  input  EMAS;
  input  TEN;
  input  BEN;
  input  TCEN;
  input  TWEN;
  input [13:0] TA;
  input [7:0] TD;
  input [7:0] TQ;
  input  RET1N;
  input  STOV;
`ifdef POWER_PINS
  inout VDDCE;
  inout VDDPE;
  inout VSSE;
`endif

  integer row_address;
  integer mux_address;
  reg [255:0] mem [0:511];
  reg [255:0] row;
  reg LAST_CLK;
  reg [255:0] row_mask;
  reg [255:0] new_data;
  reg [255:0] data_out;
  reg [63:0] readLatch0;
  reg [63:0] shifted_readLatch0;
  reg [2:0] read_mux_sel0;
  reg [7:0] Q_int;
  reg [7:0] Q_int_delayed;
  reg [7:0] writeEnable;

  reg NOT_CEN, NOT_WEN, NOT_A13, NOT_A12, NOT_A11, NOT_A10, NOT_A9, NOT_A8, NOT_A7;
  reg NOT_A6, NOT_A5, NOT_A4, NOT_A3, NOT_A2, NOT_A1, NOT_A0, NOT_D7, NOT_D6, NOT_D5;
  reg NOT_D4, NOT_D3, NOT_D2, NOT_D1, NOT_D0, NOT_EMA2, NOT_EMA1, NOT_EMA0, NOT_EMAW1;
  reg NOT_EMAW0, NOT_EMAS, NOT_TEN, NOT_TCEN, NOT_TWEN, NOT_TA13, NOT_TA12, NOT_TA11;
  reg NOT_TA10, NOT_TA9, NOT_TA8, NOT_TA7, NOT_TA6, NOT_TA5, NOT_TA4, NOT_TA3, NOT_TA2;
  reg NOT_TA1, NOT_TA0, NOT_TD7, NOT_TD6, NOT_TD5, NOT_TD4, NOT_TD3, NOT_TD2, NOT_TD1;
  reg NOT_TD0, NOT_RET1N, NOT_STOV;
  reg NOT_CLK_PER, NOT_CLK_MINH, NOT_CLK_MINL;
  reg clk0_int;

  wire  CENY_;
  wire  WENY_;
  wire [13:0] AY_;
  wire [7:0] DY_;
  wire [7:0] Q_;
 wire  CLK_;
  wire  CEN_;
  reg  CEN_int;
  reg  CEN_p2;
  wire  WEN_;
  reg  WEN_int;
  wire [13:0] A_;
  reg [13:0] A_int;
  wire [7:0] D_;
  reg [7:0] D_int;
  wire [2:0] EMA_;
  reg [2:0] EMA_int;
  wire [1:0] EMAW_;
  reg [1:0] EMAW_int;
  wire  EMAS_;
  reg  EMAS_int;
  wire  TEN_;
  reg  TEN_int;
  wire  BEN_;
  reg  BEN_int;
  wire  TCEN_;
  reg  TCEN_int;
  reg  TCEN_p2;
  wire  TWEN_;
  reg  TWEN_int;
  wire [13:0] TA_;
  reg [13:0] TA_int;
  wire [7:0] TD_;
  reg [7:0] TD_int;
  wire [7:0] TQ_;
  reg [7:0] TQ_int;
  wire  RET1N_;
  reg  RET1N_int;
  wire  STOV_;
  reg  STOV_int;

  buf B0(CENY, CENY_);
  buf B1(WENY, WENY_);
  buf B2(AY[0], AY_[0]);
  buf B3(AY[1], AY_[1]);
  buf B4(AY[2], AY_[2]);
  buf B5(AY[3], AY_[3]);
  buf B6(AY[4], AY_[4]);
  buf B7(AY[5], AY_[5]);
  buf B8(AY[6], AY_[6]);
  buf B9(AY[7], AY_[7]);
  buf B10(AY[8], AY_[8]);
  buf B11(AY[9], AY_[9]);
  buf B12(AY[10], AY_[10]);
  buf B13(AY[11], AY_[11]);
  buf B14(AY[12], AY_[12]);
  buf B15(AY[13], AY_[13]);
  buf B16(DY[0], DY_[0]);
  buf B17(DY[1], DY_[1]);
  buf B18(DY[2], DY_[2]);
  buf B19(DY[3], DY_[3]);
  buf B20(DY[4], DY_[4]);
  buf B21(DY[5], DY_[5]);
  buf B22(DY[6], DY_[6]);
  buf B23(DY[7], DY_[7]);
  buf B24(Q[0], Q_[0]);
  buf B25(Q[1], Q_[1]);
  buf B26(Q[2], Q_[2]);
  buf B27(Q[3], Q_[3]);
  buf B28(Q[4], Q_[4]);
  buf B29(Q[5], Q_[5]);
  buf B30(Q[6], Q_[6]);
  buf B31(Q[7], Q_[7]);
  buf B32(CLK_, CLK);
  buf B33(CEN_, CEN);
  buf B34(WEN_, WEN);
  buf B35(A_[0], A[0]);
  buf B36(A_[1], A[1]);
  buf B37(A_[2], A[2]);
  buf B38(A_[3], A[3]);
  buf B39(A_[4], A[4]);
  buf B40(A_[5], A[5]);
  buf B41(A_[6], A[6]);
  buf B42(A_[7], A[7]);
  buf B43(A_[8], A[8]);
  buf B44(A_[9], A[9]);
  buf B45(A_[10], A[10]);
  buf B46(A_[11], A[11]);
  buf B47(A_[12], A[12]);
  buf B48(A_[13], A[13]);
  buf B49(D_[0], D[0]);
  buf B50(D_[1], D[1]);
  buf B51(D_[2], D[2]);
  buf B52(D_[3], D[3]);
  buf B53(D_[4], D[4]);
  buf B54(D_[5], D[5]);
  buf B55(D_[6], D[6]);
  buf B56(D_[7], D[7]);
  buf B57(EMA_[0], EMA[0]);
  buf B58(EMA_[1], EMA[1]);
  buf B59(EMA_[2], EMA[2]);
  buf B60(EMAW_[0], EMAW[0]);
  buf B61(EMAW_[1], EMAW[1]);
  buf B62(EMAS_, EMAS);
  buf B63(TEN_, TEN);
  buf B64(BEN_, BEN);
  buf B65(TCEN_, TCEN);
  buf B66(TWEN_, TWEN);
  buf B67(TA_[0], TA[0]);
  buf B68(TA_[1], TA[1]);
  buf B69(TA_[2], TA[2]);
  buf B70(TA_[3], TA[3]);
  buf B71(TA_[4], TA[4]);
  buf B72(TA_[5], TA[5]);
  buf B73(TA_[6], TA[6]);
  buf B74(TA_[7], TA[7]);
  buf B75(TA_[8], TA[8]);
  buf B76(TA_[9], TA[9]);
  buf B77(TA_[10], TA[10]);
  buf B78(TA_[11], TA[11]);
  buf B79(TA_[12], TA[12]);
  buf B80(TA_[13], TA[13]);
  buf B81(TD_[0], TD[0]);
  buf B82(TD_[1], TD[1]);
  buf B83(TD_[2], TD[2]);
  buf B84(TD_[3], TD[3]);
  buf B85(TD_[4], TD[4]);
  buf B86(TD_[5], TD[5]);
  buf B87(TD_[6], TD[6]);
  buf B88(TD_[7], TD[7]);
  buf B89(TQ_[0], TQ[0]);
  buf B90(TQ_[1], TQ[1]);
  buf B91(TQ_[2], TQ[2]);
  buf B92(TQ_[3], TQ[3]);
  buf B93(TQ_[4], TQ[4]);
  buf B94(TQ_[5], TQ[5]);
  buf B95(TQ_[6], TQ[6]);
  buf B96(TQ_[7], TQ[7]);
  buf B97(RET1N_, RET1N);
  buf B98(STOV_, STOV);

  assign CENY_ = RET1N_ ? (TEN_ ? CEN_ : TCEN_) : 1'bx;
  assign WENY_ = RET1N_ ? (TEN_ ? WEN_ : TWEN_) : 1'bx;
  assign AY_ = RET1N_ ? (TEN_ ? A_ : TA_) : {14{1'bx}};
  assign DY_ = RET1N_ ? (TEN_ ? D_ : TD_) : {8{1'bx}};
   `ifdef ARM_FAULT_MODELING
     input_sram_error_injection u1(.CLK(CLK_), .Q_out(Q_), .A(A_int), .CEN(CEN_int), .TQ(TQ_), .BEN(BEN_), .WEN(WEN_int), .Q_in(Q_int));
  `else
  assign Q_ = RET1N_ ? (BEN_ ? ((STOV_ ? (Q_int_delayed) : (Q_int))) : TQ_) : {8{1'bx}};
  `endif

// If INITIALIZE_MEMORY is defined at Simulator Command Line, it Initializes the Memory with all ZEROS.
`ifdef INITIALIZE_MEMORY
  integer i;
  initial
    for (i = 0; i < MEM_HEIGHT; i = i + 1)
      mem[i] = {MEM_WIDTH{1'b0}};
`endif

  task failedWrite;
  input port_f;
  integer i;
  begin
    for (i = 0; i < MEM_HEIGHT; i = i + 1)
      mem[i] = {MEM_WIDTH{1'bx}};
  end
  endtask

  function isBitX;
    input bitval;
    begin
      isBitX = ( bitval===1'bx || bitval==1'bz ) ? 1'b1 : 1'b0;
    end
  endfunction


task loadmem;
	input [1000*8-1:0] filename;
	reg [BITS-1:0] memld [0:WORDS-1];
	integer i;
	reg [BITS-1:0] wordtemp;
	reg [13:0] Atemp;
  begin
	$readmemb(filename, memld);
     if (CEN_ === 1'b1) begin
	  for (i=0;i<WORDS;i=i+1) begin
	  wordtemp = memld[i];
	  Atemp = i;
	  mux_address = (Atemp & 5'b11111);
      row_address = (Atemp >> 5);
      row = mem[row_address];
        writeEnable = {8{1'b1}};
        row_mask =  ( {31'b0000000000000000000000000000000, writeEnable[7], 31'b0000000000000000000000000000000, writeEnable[6],
          31'b0000000000000000000000000000000, writeEnable[5], 31'b0000000000000000000000000000000, writeEnable[4],
          31'b0000000000000000000000000000000, writeEnable[3], 31'b0000000000000000000000000000000, writeEnable[2],
          31'b0000000000000000000000000000000, writeEnable[1], 31'b0000000000000000000000000000000, writeEnable[0]} << mux_address);
        new_data =  ( {31'b0000000000000000000000000000000, wordtemp[7], 31'b0000000000000000000000000000000, wordtemp[6],
          31'b0000000000000000000000000000000, wordtemp[5], 31'b0000000000000000000000000000000, wordtemp[4],
          31'b0000000000000000000000000000000, wordtemp[3], 31'b0000000000000000000000000000000, wordtemp[2],
          31'b0000000000000000000000000000000, wordtemp[1], 31'b0000000000000000000000000000000, wordtemp[0]} << mux_address);
        row = (row & ~row_mask) | (row_mask & (~row_mask | new_data));
        mem[row_address] = row;
  	end
  end
  end
  endtask

task dumpmem;
	input [1000*8-1:0] filename_dump;
	integer i, dump_file_desc;
	reg [BITS-1:0] wordtemp;
	reg [13:0] Atemp;
  begin
	dump_file_desc = $fopen(filename_dump);
     if (CEN_ === 1'b1) begin
	  for (i=0;i<WORDS;i=i+1) begin
	  Atemp = i;
	  mux_address = (Atemp & 5'b11111);
      row_address = (Atemp >> 5);
      row = mem[row_address];
        writeEnable = {8{1'b1}};
        data_out = (row >> (mux_address));
        readLatch0 = {data_out[252], data_out[248], data_out[244], data_out[240], data_out[236],
          data_out[232], data_out[228], data_out[224], data_out[220], data_out[216],
          data_out[212], data_out[208], data_out[204], data_out[200], data_out[196],
          data_out[192], data_out[188], data_out[184], data_out[180], data_out[176],
          data_out[172], data_out[168], data_out[164], data_out[160], data_out[156],
          data_out[152], data_out[148], data_out[144], data_out[140], data_out[136],
          data_out[132], data_out[128], data_out[124], data_out[120], data_out[116],
          data_out[112], data_out[108], data_out[104], data_out[100], data_out[96],
          data_out[92], data_out[88], data_out[84], data_out[80], data_out[76], data_out[72],
          data_out[68], data_out[64], data_out[60], data_out[56], data_out[52], data_out[48],
          data_out[44], data_out[40], data_out[36], data_out[32], data_out[28], data_out[24],
          data_out[20], data_out[16], data_out[12], data_out[8], data_out[4], data_out[0]};
        shifted_readLatch0 = readLatch0;
        Q_int = {shifted_readLatch0[56], shifted_readLatch0[48], shifted_readLatch0[40],
          shifted_readLatch0[32], shifted_readLatch0[24], shifted_readLatch0[16], shifted_readLatch0[8],
          shifted_readLatch0[0]};
   	$fdisplay(dump_file_desc, "%b", Q_int);
  end
  	end
//    $fclose(filename_dump);
  end
  endtask


  task readWrite;
  begin
    if (RET1N_int === 1'bx || RET1N_int === 1'bz) begin
      failedWrite(0);
      Q_int = {8{1'bx}};
    end else if (RET1N_int === 1'b0 && CEN_int === 1'b0) begin
      failedWrite(0);
      Q_int = {8{1'bx}};
    end else if (RET1N_int === 1'b0) begin
      // no cycle in retention mode
    end else if (^{CEN_int, EMA_int, EMAW_int, EMAS_int, RET1N_int, (STOV_int && !CEN_int)} 
     === 1'bx) begin
      failedWrite(0);
      Q_int = {8{1'bx}};
    end else if ((A_int >= WORDS) && (CEN_int === 1'b0)) begin
      Q_int = WEN_int !== 1'b1 ? D_int : {8{1'bx}};
      Q_int_delayed = WEN_int !== 1'b1 ? D_int : {8{1'bx}};
    end else if (CEN_int === 1'b0 && (^A_int) === 1'bx) begin
      failedWrite(0);
      Q_int = {8{1'bx}};
    end else if (CEN_int === 1'b0) begin
      mux_address = (A_int & 5'b11111);
      row_address = (A_int >> 5);
      if (row_address > 511)
        row = {256{1'bx}};
      else
        row = mem[row_address];
      writeEnable = ~{8{WEN_int}};
      if (WEN_int !== 1'b1) begin
        row_mask =  ( {31'b0000000000000000000000000000000, writeEnable[7], 31'b0000000000000000000000000000000, writeEnable[6],
          31'b0000000000000000000000000000000, writeEnable[5], 31'b0000000000000000000000000000000, writeEnable[4],
          31'b0000000000000000000000000000000, writeEnable[3], 31'b0000000000000000000000000000000, writeEnable[2],
          31'b0000000000000000000000000000000, writeEnable[1], 31'b0000000000000000000000000000000, writeEnable[0]} << mux_address);
        new_data =  ( {31'b0000000000000000000000000000000, D_int[7], 31'b0000000000000000000000000000000, D_int[6],
          31'b0000000000000000000000000000000, D_int[5], 31'b0000000000000000000000000000000, D_int[4],
          31'b0000000000000000000000000000000, D_int[3], 31'b0000000000000000000000000000000, D_int[2],
          31'b0000000000000000000000000000000, D_int[1], 31'b0000000000000000000000000000000, D_int[0]} << mux_address);
        row = (row & ~row_mask) | (row_mask & (~row_mask | new_data));
        mem[row_address] = row;
      end else begin
        data_out = (row >> (mux_address%4));
        readLatch0 = {data_out[252], data_out[248], data_out[244], data_out[240], data_out[236],
          data_out[232], data_out[228], data_out[224], data_out[220], data_out[216],
          data_out[212], data_out[208], data_out[204], data_out[200], data_out[196],
          data_out[192], data_out[188], data_out[184], data_out[180], data_out[176],
          data_out[172], data_out[168], data_out[164], data_out[160], data_out[156],
          data_out[152], data_out[148], data_out[144], data_out[140], data_out[136],
          data_out[132], data_out[128], data_out[124], data_out[120], data_out[116],
          data_out[112], data_out[108], data_out[104], data_out[100], data_out[96],
          data_out[92], data_out[88], data_out[84], data_out[80], data_out[76], data_out[72],
          data_out[68], data_out[64], data_out[60], data_out[56], data_out[52], data_out[48],
          data_out[44], data_out[40], data_out[36], data_out[32], data_out[28], data_out[24],
          data_out[20], data_out[16], data_out[12], data_out[8], data_out[4], data_out[0]};
      end
      if (WEN_int !== 1'b1) begin
        Q_int = D_int;
        Q_int_delayed = D_int;
      end else begin
        shifted_readLatch0 = (readLatch0 >> A_int[4:2]);
        Q_int = {shifted_readLatch0[56], shifted_readLatch0[48], shifted_readLatch0[40],
          shifted_readLatch0[32], shifted_readLatch0[24], shifted_readLatch0[16], shifted_readLatch0[8],
          shifted_readLatch0[0]};
      end
    end
  end
  endtask
  always @ (CEN_ or TCEN_ or TEN_ or CLK_) begin
  	if(CLK_ == 1'b0) begin
  		CEN_p2 = CEN_;
  		TCEN_p2 = TCEN_;
  	end
  end

  always @ RET1N_ begin
    if (CLK_ == 1'b1) begin
      failedWrite(0);
      Q_int = {8{1'bx}};
    end
    if (RET1N_ === 1'bx || RET1N_ === 1'bz) begin
      failedWrite(0);
      Q_int = {8{1'bx}};
    end else if (RET1N_ === 1'b0 && RET1N_int === 1'b1 && (CEN_p2 === 1'b0 || TCEN_p2 === 1'b0) ) begin
      failedWrite(0);
      Q_int = {8{1'bx}};
    end else if (RET1N_ === 1'b1 && RET1N_int === 1'b0 && (CEN_p2 === 1'b0 || TCEN_p2 === 1'b0) ) begin
      failedWrite(0);
      Q_int = {8{1'bx}};
    end
    if (RET1N_ == 1'b0) begin
      Q_int = {8{1'bx}};
      Q_int_delayed = {8{1'bx}};
      CEN_int = 1'bx;
      WEN_int = 1'bx;
      A_int = {14{1'bx}};
      D_int = {8{1'bx}};
      EMA_int = {3{1'bx}};
      EMAW_int = {2{1'bx}};
      EMAS_int = 1'bx;
      TEN_int = 1'bx;
      BEN_int = 1'bx;
      TCEN_int = 1'bx;
      TWEN_int = 1'bx;
      TA_int = {14{1'bx}};
      TD_int = {8{1'bx}};
      TQ_int = {8{1'bx}};
      RET1N_int = 1'bx;
      STOV_int = 1'bx;
    end else begin
      Q_int = {8{1'bx}};
      Q_int_delayed = {8{1'bx}};
      CEN_int = 1'bx;
      WEN_int = 1'bx;
      A_int = {14{1'bx}};
      D_int = {8{1'bx}};
      EMA_int = {3{1'bx}};
      EMAW_int = {2{1'bx}};
      EMAS_int = 1'bx;
      TEN_int = 1'bx;
      BEN_int = 1'bx;
      TCEN_int = 1'bx;
      TWEN_int = 1'bx;
      TA_int = {14{1'bx}};
      TD_int = {8{1'bx}};
      TQ_int = {8{1'bx}};
      RET1N_int = 1'bx;
      STOV_int = 1'bx;
    end
    RET1N_int = RET1N_;
  end


  always @ CLK_ begin
// If POWER_PINS is defined at Simulator Command Line, it selects the module definition with Power Ports
`ifdef POWER_PINS
    if (VDDCE === 1'bx || VDDCE === 1'bz)
      $display("ERROR: Illegal value for VDDCE %b", VDDCE);
    if (VDDPE === 1'bx || VDDPE === 1'bz)
      $display("ERROR: Illegal value for VDDPE %b", VDDPE);
    if (VSSE === 1'bx || VSSE === 1'bz)
      $display("ERROR: Illegal value for VSSE %b", VSSE);
`endif
  if (RET1N_ == 1'b0) begin
      // no cycle in retention mode
  end else begin
    if ((CLK_ === 1'bx || CLK_ === 1'bz) && RET1N_ !== 1'b0) begin
      failedWrite(0);
      Q_int = {8{1'bx}};
    end else if (CLK_ === 1'b1 && LAST_CLK === 1'b0) begin
      CEN_int = TEN_ ? CEN_ : TCEN_;
      EMA_int = EMA_;
      EMAW_int = EMAW_;
      EMAS_int = EMAS_;
      TEN_int = TEN_;
      BEN_int = BEN_;
      TWEN_int = TWEN_;
      TQ_int = TQ_;
      RET1N_int = RET1N_;
      STOV_int = STOV_;
      if (CEN_int != 1'b1) begin
        WEN_int = TEN_ ? WEN_ : TWEN_;
        A_int = TEN_ ? A_ : TA_;
        D_int = TEN_ ? D_ : TD_;
        TCEN_int = TCEN_;
        TA_int = TA_;
        TD_int = TD_;
        if (WEN_int === 1'b1)
          read_mux_sel0 = (TEN_ ? A_[4:2] : TA_[4:2] );
      end
      clk0_int = 1'b0;
      if (CEN_int === 1'b0 && WEN_int === 1'b1) 
         Q_int_delayed = {8{1'bx}};
    readWrite;
    end else if (CLK_ === 1'b0 && LAST_CLK === 1'b1) begin
      Q_int_delayed = Q_int;
    end
    LAST_CLK = CLK_;
  end
  end

  reg globalNotifier0;
  initial globalNotifier0 = 1'b0;

  always @ globalNotifier0 begin
    if ($realtime == 0) begin
    end else if (CEN_int === 1'bx || EMAS_int === 1'bx || EMAW_int[0] === 1'bx || 
      EMAW_int[1] === 1'bx || EMA_int[0] === 1'bx || EMA_int[1] === 1'bx || EMA_int[2] === 1'bx || 
      RET1N_int === 1'bx || (STOV_int && !CEN_int) === 1'bx || TEN_int === 1'bx || 
      clk0_int === 1'bx) begin
      Q_int = {8{1'bx}};
    if (clk0_int === 1'bx || CEN_int === 1'bx) begin
      D_int = {8{1'bx}};
    end
      failedWrite(0);
    end else begin
      readWrite;
   end
    globalNotifier0 = 1'b0;
  end

  always @ NOT_CEN begin
    CEN_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN begin
    WEN_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A13 begin
    A_int[13] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A12 begin
    A_int[12] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A11 begin
    A_int[11] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A10 begin
    A_int[10] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A9 begin
    A_int[9] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A8 begin
    A_int[8] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A7 begin
    A_int[7] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A6 begin
    A_int[6] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A5 begin
    A_int[5] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A4 begin
    A_int[4] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A3 begin
    A_int[3] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A2 begin
    A_int[2] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A1 begin
    A_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A0 begin
    A_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D7 begin
    D_int[7] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D6 begin
    D_int[6] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D5 begin
    D_int[5] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D4 begin
    D_int[4] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D3 begin
    D_int[3] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D2 begin
    D_int[2] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D1 begin
    D_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D0 begin
    D_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_EMA2 begin
    EMA_int[2] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_EMA1 begin
    EMA_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_EMA0 begin
    EMA_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_EMAW1 begin
    EMAW_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_EMAW0 begin
    EMAW_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_EMAS begin
    EMAS_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TEN begin
    TEN_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TCEN begin
    CEN_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN begin
    WEN_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA13 begin
    A_int[13] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA12 begin
    A_int[12] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA11 begin
    A_int[11] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA10 begin
    A_int[10] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA9 begin
    A_int[9] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA8 begin
    A_int[8] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA7 begin
    A_int[7] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA6 begin
    A_int[6] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA5 begin
    A_int[5] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA4 begin
    A_int[4] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA3 begin
    A_int[3] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA2 begin
    A_int[2] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA1 begin
    A_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA0 begin
    A_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD7 begin
    D_int[7] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD6 begin
    D_int[6] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD5 begin
    D_int[5] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD4 begin
    D_int[4] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD3 begin
    D_int[3] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD2 begin
    D_int[2] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD1 begin
    D_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD0 begin
    D_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_RET1N begin
    RET1N_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_STOV begin
    STOV_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end

  always @ NOT_CLK_PER begin
    clk0_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_CLK_MINH begin
    clk0_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_CLK_MINL begin
    clk0_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end


  wire STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire opopTENeq1andCENeq0cporopTENeq0andTCENeq0cpcp;
  wire opTENeq1andCENeq0cporopTENeq0andTCENeq0cp;

  wire STOVeq0, STOVeq1andEMASeq0, STOVeq1andEMASeq1, TENeq1andCENeq0, TENeq1andCENeq0andWENeq0;
  wire TENeq0andTCENeq0, TENeq0andTCENeq0andTWENeq0, TENeq1, TENeq0;

  assign STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (!EMA[2]) && (!EMA[1]) && (!EMA[0]) && (!EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (!EMA[2]) && (!EMA[1]) && (!EMA[0]) && (EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (!EMA[2]) && (!EMA[1]) && (EMA[0]) && (!EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (!EMA[2]) && (!EMA[1]) && (EMA[0]) && (EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (!EMA[2]) && (EMA[1]) && (!EMA[0]) && (!EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (!EMA[2]) && (EMA[1]) && (!EMA[0]) && (EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (!EMA[2]) && (EMA[1]) && (EMA[0]) && (!EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (!EMA[2]) && (EMA[1]) && (EMA[0]) && (EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (EMA[2]) && (!EMA[1]) && (!EMA[0]) && (!EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (EMA[2]) && (!EMA[1]) && (!EMA[0]) && (EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (EMA[2]) && (!EMA[1]) && (EMA[0]) && (!EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (EMA[2]) && (!EMA[1]) && (EMA[0]) && (EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (EMA[2]) && (EMA[1]) && (!EMA[0]) && (!EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (EMA[2]) && (EMA[1]) && (!EMA[0]) && (EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (EMA[2]) && (EMA[1]) && (EMA[0]) && (!EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (EMA[2]) && (EMA[1]) && (EMA[0]) && (EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (STOV) && (!EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (STOV) && (EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (!EMA[1]) && (!EMA[0]) && (!EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (!EMA[1]) && (!EMA[0]) && (!EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (!EMA[1]) && (!EMA[0]) && (EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (!EMA[1]) && (!EMA[0]) && (EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (!EMA[1]) && (EMA[0]) && (!EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (!EMA[1]) && (EMA[0]) && (!EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (!EMA[1]) && (EMA[0]) && (EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (!EMA[1]) && (EMA[0]) && (EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (EMA[1]) && (!EMA[0]) && (!EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (EMA[1]) && (!EMA[0]) && (!EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (EMA[1]) && (!EMA[0]) && (EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (EMA[1]) && (!EMA[0]) && (EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (EMA[1]) && (EMA[0]) && (!EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (EMA[1]) && (EMA[0]) && (!EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (EMA[1]) && (EMA[0]) && (EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (EMA[1]) && (EMA[0]) && (EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (!EMA[1]) && (!EMA[0]) && (!EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (!EMA[1]) && (!EMA[0]) && (!EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (!EMA[1]) && (!EMA[0]) && (EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (!EMA[1]) && (!EMA[0]) && (EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (!EMA[1]) && (EMA[0]) && (!EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (!EMA[1]) && (EMA[0]) && (!EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (!EMA[1]) && (EMA[0]) && (EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (!EMA[1]) && (EMA[0]) && (EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (EMA[1]) && (!EMA[0]) && (!EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (EMA[1]) && (!EMA[0]) && (!EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (EMA[1]) && (!EMA[0]) && (EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (EMA[1]) && (!EMA[0]) && (EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (EMA[1]) && (EMA[0]) && (!EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (EMA[1]) && (EMA[0]) && (!EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (EMA[1]) && (EMA[0]) && (EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (EMA[1]) && (EMA[0]) && (EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (STOV) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq1andEMASeq0 = 
         (STOV) && (!EMAS) && !(TEN ? CEN : TCEN);
  assign STOVeq1andEMASeq1 = 
         (STOV) && (EMAS) && !(TEN ? CEN : TCEN);
  assign TENeq1andCENeq0 = 
         !(!TEN || CEN);
  assign TENeq1andCENeq0andWENeq0 = 
         !(!TEN ||  CEN || WEN);
  assign TENeq0andTCENeq0 = 
         !(TEN || TCEN);
  assign TENeq0andTCENeq0andTWENeq0 = 
         !(TEN ||  TCEN || TWEN);
  assign opopTENeq1andCENeq0cporopTENeq0andTCENeq0cpcp = 
         ((TEN ? CEN : TCEN));
  assign opTENeq1andCENeq0cporopTENeq0andTCENeq0cp = 
         !(TEN ? CEN : TCEN);

  assign STOVeq0 = (!STOV) && !(TEN ? CEN : TCEN);
  assign TENeq1 = TEN;
  assign TENeq0 = !TEN;

  specify
    if (CEN == 1'b0 && TCEN == 1'b1)
       (TEN => CENY) = (1.000, 1.000);
    if (CEN == 1'b1 && TCEN == 1'b0)
       (TEN => CENY) = (1.000, 1.000);
    if (TEN == 1'b1)
       (CEN => CENY) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TCEN => CENY) = (1.000, 1.000);
    if (WEN == 1'b0 && TWEN == 1'b1)
       (TEN => WENY) = (1.000, 1.000);
    if (WEN == 1'b1 && TWEN == 1'b0)
       (TEN => WENY) = (1.000, 1.000);
    if (TEN == 1'b1)
       (WEN => WENY) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TWEN => WENY) = (1.000, 1.000);
    if (A[13] == 1'b0 && TA[13] == 1'b1)
       (TEN => AY[13]) = (1.000, 1.000);
    if (A[13] == 1'b1 && TA[13] == 1'b0)
       (TEN => AY[13]) = (1.000, 1.000);
    if (A[12] == 1'b0 && TA[12] == 1'b1)
       (TEN => AY[12]) = (1.000, 1.000);
    if (A[12] == 1'b1 && TA[12] == 1'b0)
       (TEN => AY[12]) = (1.000, 1.000);
    if (A[11] == 1'b0 && TA[11] == 1'b1)
       (TEN => AY[11]) = (1.000, 1.000);
    if (A[11] == 1'b1 && TA[11] == 1'b0)
       (TEN => AY[11]) = (1.000, 1.000);
    if (A[10] == 1'b0 && TA[10] == 1'b1)
       (TEN => AY[10]) = (1.000, 1.000);
    if (A[10] == 1'b1 && TA[10] == 1'b0)
       (TEN => AY[10]) = (1.000, 1.000);
    if (A[9] == 1'b0 && TA[9] == 1'b1)
       (TEN => AY[9]) = (1.000, 1.000);
    if (A[9] == 1'b1 && TA[9] == 1'b0)
       (TEN => AY[9]) = (1.000, 1.000);
    if (A[8] == 1'b0 && TA[8] == 1'b1)
       (TEN => AY[8]) = (1.000, 1.000);
    if (A[8] == 1'b1 && TA[8] == 1'b0)
       (TEN => AY[8]) = (1.000, 1.000);
    if (A[7] == 1'b0 && TA[7] == 1'b1)
       (TEN => AY[7]) = (1.000, 1.000);
    if (A[7] == 1'b1 && TA[7] == 1'b0)
       (TEN => AY[7]) = (1.000, 1.000);
    if (A[6] == 1'b0 && TA[6] == 1'b1)
       (TEN => AY[6]) = (1.000, 1.000);
    if (A[6] == 1'b1 && TA[6] == 1'b0)
       (TEN => AY[6]) = (1.000, 1.000);
    if (A[5] == 1'b0 && TA[5] == 1'b1)
       (TEN => AY[5]) = (1.000, 1.000);
    if (A[5] == 1'b1 && TA[5] == 1'b0)
       (TEN => AY[5]) = (1.000, 1.000);
    if (A[4] == 1'b0 && TA[4] == 1'b1)
       (TEN => AY[4]) = (1.000, 1.000);
    if (A[4] == 1'b1 && TA[4] == 1'b0)
       (TEN => AY[4]) = (1.000, 1.000);
    if (A[3] == 1'b0 && TA[3] == 1'b1)
       (TEN => AY[3]) = (1.000, 1.000);
    if (A[3] == 1'b1 && TA[3] == 1'b0)
       (TEN => AY[3]) = (1.000, 1.000);
    if (A[2] == 1'b0 && TA[2] == 1'b1)
       (TEN => AY[2]) = (1.000, 1.000);
    if (A[2] == 1'b1 && TA[2] == 1'b0)
       (TEN => AY[2]) = (1.000, 1.000);
    if (A[1] == 1'b0 && TA[1] == 1'b1)
       (TEN => AY[1]) = (1.000, 1.000);
    if (A[1] == 1'b1 && TA[1] == 1'b0)
       (TEN => AY[1]) = (1.000, 1.000);
    if (A[0] == 1'b0 && TA[0] == 1'b1)
       (TEN => AY[0]) = (1.000, 1.000);
    if (A[0] == 1'b1 && TA[0] == 1'b0)
       (TEN => AY[0]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (A[13] => AY[13]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (A[12] => AY[12]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (A[11] => AY[11]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (A[10] => AY[10]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (A[9] => AY[9]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (A[8] => AY[8]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (A[7] => AY[7]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (A[6] => AY[6]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (A[5] => AY[5]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (A[4] => AY[4]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (A[3] => AY[3]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (A[2] => AY[2]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (A[1] => AY[1]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (A[0] => AY[0]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TA[13] => AY[13]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TA[12] => AY[12]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TA[11] => AY[11]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TA[10] => AY[10]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TA[9] => AY[9]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TA[8] => AY[8]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TA[7] => AY[7]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TA[6] => AY[6]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TA[5] => AY[5]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TA[4] => AY[4]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TA[3] => AY[3]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TA[2] => AY[2]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TA[1] => AY[1]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TA[0] => AY[0]) = (1.000, 1.000);
    if (D[7] == 1'b0 && TD[7] == 1'b1)
       (TEN => DY[7]) = (1.000, 1.000);
    if (D[7] == 1'b1 && TD[7] == 1'b0)
       (TEN => DY[7]) = (1.000, 1.000);
    if (D[6] == 1'b0 && TD[6] == 1'b1)
       (TEN => DY[6]) = (1.000, 1.000);
    if (D[6] == 1'b1 && TD[6] == 1'b0)
       (TEN => DY[6]) = (1.000, 1.000);
    if (D[5] == 1'b0 && TD[5] == 1'b1)
       (TEN => DY[5]) = (1.000, 1.000);
    if (D[5] == 1'b1 && TD[5] == 1'b0)
       (TEN => DY[5]) = (1.000, 1.000);
    if (D[4] == 1'b0 && TD[4] == 1'b1)
       (TEN => DY[4]) = (1.000, 1.000);
    if (D[4] == 1'b1 && TD[4] == 1'b0)
       (TEN => DY[4]) = (1.000, 1.000);
    if (D[3] == 1'b0 && TD[3] == 1'b1)
       (TEN => DY[3]) = (1.000, 1.000);
    if (D[3] == 1'b1 && TD[3] == 1'b0)
       (TEN => DY[3]) = (1.000, 1.000);
    if (D[2] == 1'b0 && TD[2] == 1'b1)
       (TEN => DY[2]) = (1.000, 1.000);
    if (D[2] == 1'b1 && TD[2] == 1'b0)
       (TEN => DY[2]) = (1.000, 1.000);
    if (D[1] == 1'b0 && TD[1] == 1'b1)
       (TEN => DY[1]) = (1.000, 1.000);
    if (D[1] == 1'b1 && TD[1] == 1'b0)
       (TEN => DY[1]) = (1.000, 1.000);
    if (D[0] == 1'b0 && TD[0] == 1'b1)
       (TEN => DY[0]) = (1.000, 1.000);
    if (D[0] == 1'b1 && TD[0] == 1'b0)
       (TEN => DY[0]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[7] => DY[7]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[6] => DY[6]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[5] => DY[5]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[4] => DY[4]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[3] => DY[3]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[2] => DY[2]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[1] => DY[1]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[0] => DY[0]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[7] => DY[7]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[6] => DY[6]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[5] => DY[5]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[4] => DY[4]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[3] => DY[3]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[2] => DY[2]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[1] => DY[1]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[0] => DY[0]) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[7] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[6] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[5] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[4] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[3] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[2] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[1] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[0] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[7] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[6] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[5] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[4] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[3] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[2] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[1] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[0] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[7] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[6] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[5] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[4] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[3] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[2] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[1] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[0] : 1'b0)) = (1.000, 1.000);
    if (TQ[7] == 1'b1)
       (BEN => Q[7]) = (1.000, 1.000);
    if (TQ[7] == 1'b0)
       (BEN => Q[7]) = (1.000, 1.000);
    if (TQ[6] == 1'b1)
       (BEN => Q[6]) = (1.000, 1.000);
    if (TQ[6] == 1'b0)
       (BEN => Q[6]) = (1.000, 1.000);
    if (TQ[5] == 1'b1)
       (BEN => Q[5]) = (1.000, 1.000);
    if (TQ[5] == 1'b0)
       (BEN => Q[5]) = (1.000, 1.000);
    if (TQ[4] == 1'b1)
       (BEN => Q[4]) = (1.000, 1.000);
    if (TQ[4] == 1'b0)
       (BEN => Q[4]) = (1.000, 1.000);
    if (TQ[3] == 1'b1)
       (BEN => Q[3]) = (1.000, 1.000);
    if (TQ[3] == 1'b0)
       (BEN => Q[3]) = (1.000, 1.000);
    if (TQ[2] == 1'b1)
       (BEN => Q[2]) = (1.000, 1.000);
    if (TQ[2] == 1'b0)
       (BEN => Q[2]) = (1.000, 1.000);
    if (TQ[1] == 1'b1)
       (BEN => Q[1]) = (1.000, 1.000);
    if (TQ[1] == 1'b0)
       (BEN => Q[1]) = (1.000, 1.000);
    if (TQ[0] == 1'b1)
       (BEN => Q[0]) = (1.000, 1.000);
    if (TQ[0] == 1'b0)
       (BEN => Q[0]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[7] => Q[7]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[6] => Q[6]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[5] => Q[5]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[4] => Q[4]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[3] => Q[3]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[2] => Q[2]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[1] => Q[1]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[0] => Q[0]) = (1.000, 1.000);

// Define SDTC only if back-annotating SDF file generated by Design Compiler
   `ifdef NO_SDTC
       $period(posedge CLK, 3.000, NOT_CLK_PER);
   `else
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(negedge CLK &&& STOVeq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(negedge CLK &&& STOVeq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
   `endif

// Define SDTC only if back-annotating SDF file generated by Design Compiler
   `ifdef NO_SDTC
       $width(posedge CLK, 1.000, 0, NOT_CLK_MINH);
       $width(negedge CLK, 1.000, 0, NOT_CLK_MINL);
   `else
       $width(posedge CLK &&& STOVeq0, 1.000, 0, NOT_CLK_MINH);
       $width(negedge CLK &&& STOVeq0, 1.000, 0, NOT_CLK_MINL);
       $width(posedge CLK &&& STOVeq1andEMASeq0, 1.000, 0, NOT_CLK_MINH);
       $width(negedge CLK &&& STOVeq1andEMASeq0, 1.000, 0, NOT_CLK_MINL);
       $width(posedge CLK &&& STOVeq1andEMASeq1, 1.000, 0, NOT_CLK_MINH);
       $width(negedge CLK &&& STOVeq1andEMASeq1, 1.000, 0, NOT_CLK_MINL);
   `endif

    $setuphold(posedge CLK &&& TENeq1, posedge CEN, 1.000, 0.500, NOT_CEN);
    $setuphold(posedge CLK &&& TENeq1, negedge CEN, 1.000, 0.500, NOT_CEN);
    $setuphold(posedge RET1N &&& TENeq1, negedge CEN, 0.000, 0.500, NOT_RET1N);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, posedge WEN, 1.000, 0.500, NOT_WEN);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, negedge WEN, 1.000, 0.500, NOT_WEN);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, posedge A[13], 1.000, 0.500, NOT_A13);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, posedge A[12], 1.000, 0.500, NOT_A12);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, posedge A[11], 1.000, 0.500, NOT_A11);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, posedge A[10], 1.000, 0.500, NOT_A10);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, posedge A[9], 1.000, 0.500, NOT_A9);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, posedge A[8], 1.000, 0.500, NOT_A8);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, posedge A[7], 1.000, 0.500, NOT_A7);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, posedge A[6], 1.000, 0.500, NOT_A6);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, posedge A[5], 1.000, 0.500, NOT_A5);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, posedge A[4], 1.000, 0.500, NOT_A4);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, posedge A[3], 1.000, 0.500, NOT_A3);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, posedge A[2], 1.000, 0.500, NOT_A2);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, posedge A[1], 1.000, 0.500, NOT_A1);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, posedge A[0], 1.000, 0.500, NOT_A0);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, negedge A[13], 1.000, 0.500, NOT_A13);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, negedge A[12], 1.000, 0.500, NOT_A12);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, negedge A[11], 1.000, 0.500, NOT_A11);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, negedge A[10], 1.000, 0.500, NOT_A10);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, negedge A[9], 1.000, 0.500, NOT_A9);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, negedge A[8], 1.000, 0.500, NOT_A8);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, negedge A[7], 1.000, 0.500, NOT_A7);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, negedge A[6], 1.000, 0.500, NOT_A6);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, negedge A[5], 1.000, 0.500, NOT_A5);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, negedge A[4], 1.000, 0.500, NOT_A4);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, negedge A[3], 1.000, 0.500, NOT_A3);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, negedge A[2], 1.000, 0.500, NOT_A2);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, negedge A[1], 1.000, 0.500, NOT_A1);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, negedge A[0], 1.000, 0.500, NOT_A0);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[7], 1.000, 0.500, NOT_D7);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[6], 1.000, 0.500, NOT_D6);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[5], 1.000, 0.500, NOT_D5);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[4], 1.000, 0.500, NOT_D4);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[3], 1.000, 0.500, NOT_D3);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[2], 1.000, 0.500, NOT_D2);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[1], 1.000, 0.500, NOT_D1);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[0], 1.000, 0.500, NOT_D0);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[7], 1.000, 0.500, NOT_D7);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[6], 1.000, 0.500, NOT_D6);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[5], 1.000, 0.500, NOT_D5);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[4], 1.000, 0.500, NOT_D4);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[3], 1.000, 0.500, NOT_D3);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[2], 1.000, 0.500, NOT_D2);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[1], 1.000, 0.500, NOT_D1);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[0], 1.000, 0.500, NOT_D0);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, posedge EMA[2], 1.000, 0.500, NOT_EMA2);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, posedge EMA[1], 1.000, 0.500, NOT_EMA1);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, posedge EMA[0], 1.000, 0.500, NOT_EMA0);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, negedge EMA[2], 1.000, 0.500, NOT_EMA2);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, negedge EMA[1], 1.000, 0.500, NOT_EMA1);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, negedge EMA[0], 1.000, 0.500, NOT_EMA0);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, posedge EMAW[1], 1.000, 0.500, NOT_EMAW1);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, posedge EMAW[0], 1.000, 0.500, NOT_EMAW0);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, negedge EMAW[1], 1.000, 0.500, NOT_EMAW1);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, negedge EMAW[0], 1.000, 0.500, NOT_EMAW0);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, posedge EMAS, 1.000, 0.500, NOT_EMAS);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, negedge EMAS, 1.000, 0.500, NOT_EMAS);
    $setuphold(posedge CLK, posedge TEN, 1.000, 0.500, NOT_TEN);
    $setuphold(posedge CLK, negedge TEN, 1.000, 0.500, NOT_TEN);
    $setuphold(posedge CLK &&& TENeq0, posedge TCEN, 1.000, 0.500, NOT_TCEN);
    $setuphold(posedge CLK &&& TENeq0, negedge TCEN, 1.000, 0.500, NOT_TCEN);
    $setuphold(posedge RET1N &&& TENeq0, negedge TCEN, 0.000, 0.500, NOT_RET1N);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, posedge TWEN, 1.000, 0.500, NOT_TWEN);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, negedge TWEN, 1.000, 0.500, NOT_TWEN);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, posedge TA[13], 1.000, 0.500, NOT_TA13);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, posedge TA[12], 1.000, 0.500, NOT_TA12);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, posedge TA[11], 1.000, 0.500, NOT_TA11);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, posedge TA[10], 1.000, 0.500, NOT_TA10);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, posedge TA[9], 1.000, 0.500, NOT_TA9);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, posedge TA[8], 1.000, 0.500, NOT_TA8);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, posedge TA[7], 1.000, 0.500, NOT_TA7);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, posedge TA[6], 1.000, 0.500, NOT_TA6);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, posedge TA[5], 1.000, 0.500, NOT_TA5);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, posedge TA[4], 1.000, 0.500, NOT_TA4);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, posedge TA[3], 1.000, 0.500, NOT_TA3);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, posedge TA[2], 1.000, 0.500, NOT_TA2);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, posedge TA[1], 1.000, 0.500, NOT_TA1);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, posedge TA[0], 1.000, 0.500, NOT_TA0);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, negedge TA[13], 1.000, 0.500, NOT_TA13);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, negedge TA[12], 1.000, 0.500, NOT_TA12);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, negedge TA[11], 1.000, 0.500, NOT_TA11);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, negedge TA[10], 1.000, 0.500, NOT_TA10);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, negedge TA[9], 1.000, 0.500, NOT_TA9);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, negedge TA[8], 1.000, 0.500, NOT_TA8);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, negedge TA[7], 1.000, 0.500, NOT_TA7);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, negedge TA[6], 1.000, 0.500, NOT_TA6);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, negedge TA[5], 1.000, 0.500, NOT_TA5);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, negedge TA[4], 1.000, 0.500, NOT_TA4);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, negedge TA[3], 1.000, 0.500, NOT_TA3);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, negedge TA[2], 1.000, 0.500, NOT_TA2);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, negedge TA[1], 1.000, 0.500, NOT_TA1);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, negedge TA[0], 1.000, 0.500, NOT_TA0);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[7], 1.000, 0.500, NOT_TD7);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[6], 1.000, 0.500, NOT_TD6);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[5], 1.000, 0.500, NOT_TD5);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[4], 1.000, 0.500, NOT_TD4);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[3], 1.000, 0.500, NOT_TD3);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[2], 1.000, 0.500, NOT_TD2);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[1], 1.000, 0.500, NOT_TD1);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[0], 1.000, 0.500, NOT_TD0);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[7], 1.000, 0.500, NOT_TD7);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[6], 1.000, 0.500, NOT_TD6);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[5], 1.000, 0.500, NOT_TD5);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[4], 1.000, 0.500, NOT_TD4);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[3], 1.000, 0.500, NOT_TD3);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[2], 1.000, 0.500, NOT_TD2);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[1], 1.000, 0.500, NOT_TD1);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[0], 1.000, 0.500, NOT_TD0);
    $setuphold(posedge CLK &&& opopTENeq1andCENeq0cporopTENeq0andTCENeq0cpcp, posedge RET1N, 1.000, 0.500, NOT_RET1N);
    $setuphold(posedge CLK &&& opopTENeq1andCENeq0cporopTENeq0andTCENeq0cpcp, negedge RET1N, 1.000, 0.500, NOT_RET1N);
    $setuphold(posedge CEN &&& TENeq1, negedge RET1N, 0.000, 0.500, NOT_RET1N);
    $setuphold(posedge TCEN &&& TENeq0, negedge RET1N, 0.000, 0.500, NOT_RET1N);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, posedge STOV, 1.000, 0.500, NOT_STOV);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, negedge STOV, 1.000, 0.500, NOT_STOV);
  endspecify


endmodule
`endcelldefine
`endif
`timescale 1ns/1ps
module input_sram_error_injection (Q_out, Q_in, CLK, A, CEN, WEN, BEN, TQ);
   output [7:0] Q_out;
   input [7:0] Q_in;
   input CLK;
   input [13:0] A;
   input CEN;
   input WEN;
   input BEN;
   input [7:0] TQ;
   parameter LEFT_RED_COLUMN_FAULT = 2'd1;
   parameter RIGHT_RED_COLUMN_FAULT = 2'd2;
   parameter NO_RED_FAULT = 2'd0;
   reg [7:0] Q_out;
   reg entry_found;
   reg list_complete;
   reg [21:0] fault_table [511:0];
   reg [21:0] fault_entry;
initial
begin
   `ifdef DUT
      `define pre_pend_path TB.DUT_inst.CHIP
   `else
       `define pre_pend_path TB.CHIP
   `endif
   `ifdef ARM_NONREPAIRABLE_FAULT
      `pre_pend_path.SMARCHCHKBVCD_LVISION_MBISTPG_ASSEMBLY_UNDER_TEST_INST.MEM0_MEM_INST.u1.add_fault(14'd13210,3'd6,2'd1,2'd0);
   `endif
end
   task add_fault;
   //This task injects fault in memory
   //In order to inject fault in redundant column for Bit 0 to 3, column address
   //should have value in range of 28 to 31
   //In order to inject fault in redundant column for Bit 4 to 7, column address
   //should have value in range of 0 to 3
      input [13:0] address;
      input [2:0] bitPlace;
      input [1:0] fault_type;
      input [1:0] red_fault;
 
      integer i;
      reg done;
   begin
      done = 1'b0;
      i = 0;
      while ((!done) && i < 511)
      begin
         fault_entry = fault_table[i];
         if (fault_entry[0] === 1'b0 || fault_entry[0] === 1'bx)
         begin
            fault_entry[0] = 1'b1;
            fault_entry[2:1] = red_fault;
            fault_entry[4:3] = fault_type;
            fault_entry[7:5] = bitPlace;
            fault_entry[21:8] = address;
            fault_table[i] = fault_entry;
            done = 1'b1;
         end
         i = i+1;
      end
   end
   endtask
//This task removes all fault entries injected by user
task remove_all_faults;
   integer i;
begin
   for (i = 0; i < 512; i=i+1)
   begin
      fault_entry = fault_table[i];
      fault_entry[0] = 1'b0;
      fault_table[i] = fault_entry;
   end
end
endtask
task bit_error;
// This task is used to inject error in memory and should be called
// only from current module.
//
// This task injects error depending upon fault type to particular bit
// of the output
   inout [7:0] q_int;
   input [1:0] fault_type;
   input [2:0] bitLoc;
begin
   if (fault_type === 2'd0)
      q_int[bitLoc] = 1'b0;
   else if (fault_type === 2'd1)
      q_int[bitLoc] = 1'b1;
   else
      q_int[bitLoc] = ~q_int[bitLoc];
end
endtask
task error_injection_on_output;
// This function goes through error injection table for every
// read cycle and corrupts Q output if fault for the particular
// address is present in fault table
//
// If fault is redundant column is detected, this task corrupts
// Q output in read cycle
//
// If fault is repaired using repair bus, this task does not
// courrpt Q output in read cycle
//
   output [7:0] Q_output;
   reg list_complete;
   integer i;
   reg [8:0] row_address;
   reg [4:0] column_address;
   reg [2:0] bitPlace;
   reg [1:0] fault_type;
   reg [1:0] red_fault;
   reg valid;
begin
   entry_found = 1'b0;
   list_complete = 1'b0;
   i = 0;
   Q_output = Q_in;
   while(!list_complete)
   begin
      fault_entry = fault_table[i];
      {row_address, column_address, bitPlace, fault_type, red_fault, valid} = fault_entry;
      i = i + 1;
      if (valid == 1'b1)
      begin
         if (red_fault === NO_RED_FAULT)
         begin
            if (row_address == A[13:5] && column_address == A[4:0])
            begin
               if (bitPlace < 4)
                  bit_error(Q_output,fault_type, bitPlace);
               else if (bitPlace >= 4 )
                  bit_error(Q_output,fault_type, bitPlace);
            end
         end
      end
      else
         list_complete = 1'b1;
      end
   end
   endtask
   always @ (Q_in or CLK or A or CEN or WEN or BEN or TQ)
   begin
   if (CEN === 1'b0 && &WEN === 1'b1 && BEN === 1'b1)
      error_injection_on_output(Q_out);
   else if (BEN === 1'b0)
      Q_out = TQ;
   else
      Q_out = Q_in;
   end
endmodule
