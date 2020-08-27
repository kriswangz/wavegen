// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.2 (win64) Build 1909853 Thu Jun 15 18:39:09 MDT 2017
// Date        : Sat Jul  4 10:40:24 2020
// Host        : DESKTOP-AJKB1DE running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               C:/Users/chris/Desktop/wave_gen/wave_gen.srcs/sources_1/ip/ic_ram/ic_ram_stub.v
// Design      : ic_ram
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_3_6,Vivado 2017.2" *)
module ic_ram(clka, ena, wea, addra, dina, clkb, enb, addrb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,wea[0:0],addra[8:0],dina[127:0],clkb,enb,addrb[8:0],doutb[127:0]" */;
  input clka;
  input ena;
  input [0:0]wea;
  input [8:0]addra;
  input [127:0]dina;
  input clkb;
  input enb;
  input [8:0]addrb;
  output [127:0]doutb;
endmodule
