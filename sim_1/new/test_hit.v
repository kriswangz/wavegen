`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/01 17:33:37
// Design Name: 
// Module Name: test_hit
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


module test_hit(

    );

reg clk;
reg rst;

reg  [32:0]   cpu_addr_i = 33'd0;
reg  cpu_read_valid_i =  1'b0;

wire    [127:0]     ic_data_o;
wire    [32:0]      ic_addr_o;
wire    cpu_read_ack_o;

wire    [32:0]      ic_read_dma_addr_o;
wire                ic_read_dma_valid_o;

reg                 ic_read_dma_ack_i;
reg     [127:0]     ic_read_dma_data_i;

reg     [32:0]      ic_read_addr_from_dma;


initial begin
    #1 rst = 1;
    #1 rst = 0;
    #1 clk = 0;
    ic_read_dma_ack_i = 0;
    ic_read_dma_data_i = 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;
    forever  #5 clk = ~clk;
end

initial begin
    #20 cpu_addr_i = 33'd0;
        cpu_read_valid_i =  1'b0;

    @(posedge clk);
        wait(ic_read_dma_valid_o)fork
            ic_read_addr_from_dma   =  ic_read_dma_addr_o;
            ic_read_dma_ack_i = 1;

        join
    @(posedge clk);
            ic_read_dma_ack_i = 0;
    @(posedge clk);
            ic_read_dma_ack_i = 0;

    @(posedge clk);
        wait(ic_read_dma_valid_o)fork
            ic_read_addr_from_dma   =  ic_read_dma_addr_o;
            ic_read_dma_ack_i = 1;
        join

    @(posedge clk);
            ic_read_dma_ack_i = 0;
    @(posedge clk);
            ic_read_dma_ack_i = 0;
      
    #100
    @(posedge clk);
        cpu_addr_i = 33'd0;
        cpu_read_valid_i =  1'b0;
    @(posedge clk);
        cpu_addr_i = 33'd1024;
        cpu_read_valid_i =  1'b1;
    @(posedge clk);
        cpu_addr_i = 33'd0;
        cpu_read_valid_i =  1'b0;
end


icache_top icache_top_inst(
        .clk(clk), 
        .rst(rst),
    
        // interface with cpu
        .cpu_addr_i(cpu_addr_i),
        .cpu_read_valid_i(cpu_read_valid_i),
        .ic_data_o(ic_data_o),
        .ic_addr_o(ic_addr_o),
        .cpu_read_ack_o(cpu_read_ack_o),
    
        //interface with DMA CTRL
        .ic_read_dma_addr_o(ic_read_dma_addr_o),
        .ic_read_dma_valid_o(ic_read_dma_valid_o),
        .ic_read_dma_ack_i(ic_read_dma_ack_i),
        .ic_read_dma_data_i(ic_read_dma_data_i),
        .ic_read_addr_from_dma(ic_read_addr_from_dma)
    
        ); 
    
endmodule
