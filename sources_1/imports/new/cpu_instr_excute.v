`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: UESTC
// Engineer: Chris Wang
// 
// Create Date: 2020/07/14 20:22:58
// Design Name: 
// Module Name: cpu_instr_excute
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

module cpu_instr_excute(
	input			clk,
	input			rst,
	input [127:0]	instrcution,
	input 			instrc_valid,
	output			generate_done,

	input			axis_ready,
	output[31:0]	axis_data,
	output			axis_valid,
	output			axis_last
);
	wire[32:0]		ddr_address;
	wire[25:0]		buff_length;
	wire[15:0]		segment_times;

	wire			next_data;
	// reg				write_en;
	reg		[15:0]	segment_num = 16'd0;
	reg		[2:0]	data_num = 3'd0;
	reg		[31:0]	data_gen = 32'd0;
	reg				tvalid;
	//jump instrcution parameter determination
	assign	ddr_address		= instrc_valid ? instrcution[96:64]	:ddr_address;
	assign	buff_length		= instrc_valid ? instrcution[57:32]	:buff_length;
	assign	segment_times	= instrc_valid ? instrcution[19:4]	:segment_times;

	assign	next_data 		= axis_ready&tvalid;		//the axis_valid signal cause timing loop;
	assign	axis_last		= data_num==3'd7 ?1'b1:1'b0;
	assign	axis_data		= data_gen;
	assign	axis_valid		= tvalid&(~generate_done);	//data valid signal align data
	assign	generate_done	= (segment_num>=segment_times)?1'b1:1'b0;

always @(posedge clk or posedge rst)//must use timing circui
	begin
		if(rst)
			tvalid <= 1'b0;
		else
			tvalid <= instrc_valid|(~generate_done&tvalid);
	end

always @(posedge clk or posedge rst)
	begin
		if(rst)
			begin
			data_num 		<='d0;
			segment_num		<='d0;
			end
		else if(generate_done)
			begin
			data_num 		<='d0;
			segment_num		<='d0;
			end
		else if(next_data)
			begin
			data_num 		<= data_num + 3'd1;
			if(data_num==3'd7)
			segment_num		<= segment_num+16'd1;
			else
			segment_num		<= segment_num;
			end
		else
			data_num 		<= data_num;
	end

always @(*)
	begin
		if(rst)
			data_gen <='d0;
		else case(data_num)
			3'd0:data_gen <=32'h80002000;
			3'd1:data_gen <=32'h0;
			3'd2:data_gen <=ddr_address[31:0];
			3'd3:data_gen <={31'd0,ddr_address[32]};
			3'd4:data_gen <=32'h0;
			3'd5:data_gen <=32'h0;
			3'd6:data_gen <={6'b000011,buff_length};
			3'd7:data_gen <=32'h0;
			default:data_gen <=32'h0;
		endcase
	end

endmodule
