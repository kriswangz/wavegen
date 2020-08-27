`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/06/29 20:22:58
// Design Name: 
// Module Name: Icache
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

//  implement instruction cache.
//  TODO: brust function is not supported, add it.  
//  TODO: Read latency is 3 clocks, inlcuding cpu read and read dma interface.
//  if you wanna get data from cache, set cpu_addr_i and assert cpu_read_valid_i simultaneously,
//  if tag_hit, the program will return ic_data and assert ack at 3 clocks later.
//  it is same for the other module.
//  if tag_miss, the program will read data from DMA CTRL's read channel, latency is also 3 clocks.


/************************************************************************

    cpu_addr_i          ____xxxxxxx______________________________________
    cpu_read_valid_i    ____|▔▔▔|______________________________________

    ic_addr_o           _______________________________________xxxxxx____
    ic_data_o           _______________________________________zzzzzz____
    ic_read_dma_ack_i   ____|▔▔▔|____|▔▔▔|____|▔▔▔|____|▔▔▔|____     

**************************************************************************/

module icache_top(
    clk, 
    rst,

    // interface with cpu
    cpu_addr_i,
    cpu_read_valid_i,
    ic_data_o,
    ic_addr_o,
    cpu_read_ack_o,

    //interface with DMA CTRL
    ic_read_dma_addr_o,
    ic_read_dma_valid_o,
    ic_read_dma_ack_i,
    ic_read_addr_from_dma,
    ic_read_dma_data_i

    );

    parameter dw = 128;
    // attention, addr[3:0] is not used. 33bits address are decoded by bytes, but datas width are 128 bits
    // so addr step value should be 10'd16(5'b10000)  
    parameter aw = 33; 

    // clock and reset
    input   clk;
    input   rst;

    // interface with cpu
    input   [aw - 1 : 0]      cpu_addr_i;
    input                     cpu_read_valid_i;
    output  [dw - 1 : 0]      ic_data_o;
    output  [aw - 1 : 0]      ic_addr_o;
    output                    cpu_read_ack_o;

    //interface with DMA CTRL
    output  [aw - 1 : 0]    ic_read_dma_addr_o;
    output                  ic_read_dma_valid_o;
    input                   ic_read_dma_ack_i;
    input   [aw - 1 : 0]    ic_read_addr_from_dma;
    input   [dw - 1 : 0]    ic_read_dma_data_i;

    

//
    wire    [aw - 1 : 0]    addr_o;
    wire    [dw - 1 : 0]    data_o;
    
    wire    tag_wea;
    wire    [8 : 0]         tag_addra;
    wire    [19 : 0]        tag_dina;
    wire    [8 : 0]         tag_addrb;
    wire    [19 : 0]        tag_doutb;        //compare tag and addr_in, if tag == addr_in, incidates hit.

    wire    ram_wea;
    wire    [8 : 0]         ram_addra;
    wire    [dw - 1 : 0]    ram_dina;   // 128bits inst. from DMA(DDR)
    wire    [8 : 0]         ram_addrb;
    wire    [dw - 1 : 0]    ram_doutb;  // send to fsm and send to data_o finnaly.
//
    //simple dual ram, implement by xilinx inc.
    //depth: 512
    //channel a : write
    //channel b : read
    // common clk is selected

    ic_ram_top ic_ram_top_inst (
        .clka(clk),    // input wire clka
        .wea(ram_wea),      // input wire [0 : 0] wea
        .addra(ram_addra),  // input wire [8 : 0] addra
        .dina(ram_dina),    // input wire [128 : 0] dina
        
        .clkb(clk),    // input wire clkb
        .addrb(ram_addrb),  // input wire [8 : 0] addrb
        .doutb(ram_doutb)  // output wire [18 : 0] doutb
);


    //depth: 512
    //channel a : write
    //channel b : read
    ic_tag_top ic_tag_top_inst ( 
        
        .clka(clk),    // input wire clka
        .wea(tag_wea),      // input wire [0 : 0] wea
        .addra(tag_addra),  // input wire [8 : 0] addra
        .dina(tag_dina),    // input wire [19 : 0] dina
        
        .clkb(clk),    // input wire clkb
        .addrb(tag_addrb),  // input wire [8 : 0] addrb
        .doutb(tag_doutb)  // output wire [19 : 0] doutb

);

//指令控制器的策略应该是可以定制的，包括了2种方�?
// 1 发生了hit miss则更新整个控制器或�?�更新对应地�?下的内容，如若不然，则始终不更新Icache内的内容，这样是cache的�?�用做法，如果指令的随机性很高，这也是一种有效的方式
// 2 写cache�?直在工作，保证当前指令永远在存储区域的正中间，如若深度为512，则当前指针永远�?256，这样可以保证短跳转指令能够顺利预测

//使用方案2似乎是可行的
    ic_fsm ic_fsm_inst(

        //clock and reset

        .clk(clk),
        .rst(rst),

        //interface with cpu
        .cpu_addr_i(cpu_addr_i),
        .cpu_read_valid_i(cpu_read_valid_i),
        .ic_data_o(ic_data_o),
        .ic_addr_o(ic_addr_o),
        .cpu_read_ack_o(cpu_read_ack_o),

        //interface with DMA CTRL
        .first_addr(33'h0),   // TODO!!!!, tentative 33'h0, address of first instruction address.
        .ic_read_dma_addr_o(ic_read_dma_addr_o),
        .ic_read_dma_valid_o(ic_read_dma_valid_o),

        .ic_read_dma_ack_i(ic_read_dma_ack_i),
        .ic_read_addr_from_dma(ic_read_addr_from_dma),
        .ic_read_dma_data_i(ic_read_dma_data_i),

        //interal interface
        .tag_wea_o(tag_wea),            //enable write operations           
        .tag_addra_o(tag_addra),        //write addr into tag ram
        .tag_dina_o(tag_dina),          //write data into ic ram
        .tag_addrb_o(tag_addrb),        //read addr into tag ram
        .tag_doutb_i(tag_doutb),

        .ram_wea_o(ram_wea),            //enable write operations 
        .ram_addra_o(ram_addra),        //write addr
        .ram_dina_o(ram_dina),          //write data 
        .ram_addrb_o(ram_addrb),        //read addr
        .ram_doutb_i(ram_doutb)         //read data from ic_ram

    );

endmodule
