`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/15 09:19:57
// Design Name: 
// Module Name: cpu_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cpu_top(
 		clk,
 		rst,
		start,
		stop,
	    start_addr,

		cpu_read_ack, //from instruction mem module 
        cpu_read_data,
		cpu_read_valid,

        cpu_read_addr,
		cpu_read_valid,

        segment_instruc,
		segment_instruc_valid,

        axis_data,
        axis_valid,
        axis_last,
        axis_ready

    );

input 		        clk;
input 		        rst;
input		        start;
input		        stop;
input   [32:0]	    start_addr;

input   [127:0]     cpu_read_data;
input               cpu_read_ack;


output  [32:0]      cpu_read_addr;
output		        cpu_read_valid;

output  [127:0]     segment_instruc;
output		        segment_instruc_valid;

output  [31:0]      axis_data;
output              axis_valid;
output              axis_last;
input               axis_ready;


// wire define
wire    [127:0]     segment_instruc;
wire    [32:0]      cpu_read_addr;  
wire                cpu_read_valid;
wire                generate_done;

cpu_instr_fetch  cpu_instr_fetch_inst (
    .clk                     ( clk                            ),
    .rst                     ( rst                            ),
    .start                   ( start                          ),
    .stop                    ( stop                           ),
    .start_addr              ( start_addr             [32:0]  ),
    // cpu channel.
    .cpu_read_valid          ( cpu_read_valid                 ),
    .cpu_read_addr           ( cpu_read_addr          [32:0]  ),
    .cpu_read_data           ( cpu_read_data          [127:0] ),
    .cpu_read_ack            ( cpu_read_ack                   ),
    //siganls from cpu_instr_excute module.
    .generate_done           ( generate_done                  ),
    .segment_instruc         ( segment_instruc        [127:0] ),
    .segment_instruc_valid   ( segment_instruc_valid          )
);

cpu_instr_excute  cpu_instr_excute_inst (
    .clk                     ( clk                    ),
    .rst                     ( rst                   ),
    .instrcution             ( segment_instruc [127:0]),
    .instrc_valid            ( segment_instruc_valid  ),
    .axis_ready              ( axis_ready             ),

    .generate_done           ( generate_done          ),
    .axis_data               ( axis_data              ),
    .axis_valid              ( axis_valid             ),
    .axis_last               ( axis_last              )
);


endmodule
