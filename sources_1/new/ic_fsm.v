`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/06/29 20:24:31
// Design Name: 
// Module Name: ic_fsm
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


module ic_fsm(
        //clock and reset
        input   clk,
        input   rst,

        //interface with cpu
        input           [32 : 0]    cpu_addr_i,    // data from cpu
        input                       cpu_read_valid_i,

        output  reg     [127 : 0]   ic_data_o,     // if hit, data_o = ram_doutb, or data is not valid.
        output  reg     [32 : 0]    ic_addr_o,     // storage cpu_addr_i and delay 1 clock.
        output  reg                 cpu_read_ack_o,

        //interface with DMA CTRL
        input           [32 : 0]    first_addr,
        output  reg     [32 : 0]    ic_read_dma_addr_o,    // miss hit: read from ddr.
        output  reg                 ic_read_dma_valid_o,

        input                       ic_read_dma_ack_i,
        input           [32 : 0]    ic_read_addr_from_dma,
        input           [127 : 0]   ic_read_dma_data_i,
        
        // cache status signals
        output   reg                tag_hit,
        output   reg                tag_miss,
        //internal signals

        output                      tag_wea_o,            //enable write operations           
        output  reg     [8 : 0]     tag_addra_o,        //write addr into tag ram
        output  reg     [19 : 0]    tag_dina_o,          //write data into ic ram
        output  reg     [8 : 0]     tag_addrb_o,        //read addr into tag ram
        input           [19 : 0]    tag_doutb_i,
        // tag data is read in ic_top and is only used for judge cache is hit or miss

        output                      ram_wea_o,            //enable write operations 
        output  reg     [8 : 0]     ram_addra_o,        //wr         ite addr
        output  reg     [127 : 0]   ram_dina_o,          //write data 
        output  reg     [8 : 0]     ram_addrb_o,        //read addr
        input           [127 : 0]   ram_doutb_i         //read data from ic_ram
    );

// fsm description:
//idle: read first 512 depth inst data when reset is deasserted.
// cfetch�??? if hit, data will send to ic_data_o and refresh a data into cache to ensure short jump.
//          if not, fsm into lrefill state, read data from ddr
//          and save in cache, return idle.
    localparam  idle                    =   3'd1;
    localparam  preload_load_addr       =   3'd2;
    localparam  preload_load_data       =   3'd3;
    localparam  iloadaddr               =   3'd4;
    localparam  ifetch                  =   3'd5;
    localparam  irefill_load_addr       =   3'd6;
    localparam  irefill_load_data       =   3'd7;

    localparam  CACHE_DEPTH = 2;

    reg     [9:0]   cnt_preload;
    reg     [9:0]   cnt_refill;
    reg     [2:0]   nstate;
    reg     [2:0]   cstate;

    reg             preload_over = 1'b0;
    reg             refill_down  = 1'b0;
    reg     [32:0]  cpu_addr_reg;
    reg     [32:0]  tag_hit_addr;
    reg     [32:0]  ic_read_dma_first_addr;
    wire            tag_hit_wired;
    wire            tag_miss_wired;
    
    assign  tag_wea_o   =   1'b1;
    assign  ram_wea_o   =   1'b1;

// fsm
    always @(posedge clk or posedge rst)
    begin
        if(rst)
           cstate <= idle;
        else
           cstate <= nstate;
    end

    always @(*) begin
        case(cstate)
                idle:
                begin
                    if(preload_over)
                        nstate = iloadaddr;
                    else nstate = preload_load_addr;   // TODO:  nstate = preload_load_addr
                end

                preload_load_addr:
                begin
                    if(ic_read_dma_ack_i)
                        nstate = preload_load_data;
                    else nstate = preload_load_addr;
                end

                preload_load_data:
                    begin 
                        if(cnt_preload == CACHE_DEPTH -1)begin
                            nstate = iloadaddr;
                        end
                        else nstate = preload_load_addr; 
                    end
                iloadaddr:
                    begin
                        if(cpu_read_valid_i)
                                nstate = ifetch;
                        else  nstate = iloadaddr;
                    end
                ifetch:
                    begin
                        if(tag_hit_wired)     nstate = idle;
                        else    nstate = irefill_load_addr;             
                    end


                irefill_load_addr:
                    begin
                        if(ic_read_dma_ack_i)begin
                            nstate = irefill_load_data;
                        end
                        else begin
                            nstate = irefill_load_addr;
                        end                 
                    end


                irefill_load_data:
                    begin
                        if(cnt_refill == CACHE_DEPTH -1)begin
                            nstate = idle;
                        end
                        else begin
                            nstate = irefill_load_addr;
                        end
                    end
                default:
                     nstate = idle;
        endcase
    end

    always @(posedge clk)begin
        case(cstate)
                    idle:
                        begin
                            ic_read_dma_valid_o     <=      1'b0;
                            ic_read_dma_addr_o      <=      first_addr;        //33'h0 in general.
                            ic_data_o               <=      128'd0;
                            ic_addr_o               <=      33'd0;
                            cpu_read_ack_o          <=      1'b0;
                            tag_addrb_o             <=      9'd0;
                            ram_addrb_o             <=      9'd0;
                            cnt_preload             <=      10'd0;
                            cnt_refill              <=      10'd0;
                            cpu_addr_reg            <=      33'd0;
                            tag_addra_o             <=      9'd0;
                            tag_dina_o              <=      20'd0;
                            ram_addra_o             <=      9'd0;
                            ram_dina_o              <=      128'd0;                                    
                        end

                    preload_load_addr:
                        begin
                            ic_read_dma_valid_o     <=      1'b1;
                        end

                    preload_load_data:
                        begin
                                ic_read_dma_valid_o     <=      1'b0;
                                ic_read_dma_addr_o      <=      ic_read_dma_addr_o      +       33'd16; //128bits(16x8bits) data, so addr need +16
                                cnt_preload             <=      cnt_preload             +       10'd1;
                                tag_addra_o             <=      ic_read_addr_from_dma[12:4];
                                tag_dina_o              <=      ic_read_addr_from_dma[32:13];
                                ram_addra_o             <=      ic_read_addr_from_dma[12:4];
                                ram_dina_o              <=      ic_read_dma_data_i;

                            if(cnt_preload  ==  CACHE_DEPTH -1)begin
                                cnt_preload     <=  10'd0;
                                preload_over <= 1'b1; //disable preload during next operation.
                            end
                        end 
                    iloadaddr:
                        begin
                                cpu_addr_reg            <=      cpu_addr_i;
                                ram_addrb_o             <=      cpu_addr_i[12:4];
                                tag_addrb_o             <=      cpu_addr_i[12:4];
                                ic_read_dma_first_addr  <=      cpu_addr_reg;           //preload teh address of cpu address request.
                                tag_hit_addr            <=      cpu_addr_reg;                                                     
                   
                        end
                    ifetch: //judge tag_hit bit here, addr is load in iloadaddr state and data is load into tag_doutb_i in this state
                            // so if data is hited, tag hit will assert.
                        begin
                            if(tag_hit_wired)begin

                                ic_data_o               <=      ram_doutb_i;        
                                ic_addr_o               <=      tag_hit_addr;
                                cpu_read_ack_o          <=      1'b1;
                                
                            end
                            else begin
                                ic_data_o               <=      128'd0;
                                ic_addr_o               <=      10'd0;
                                cpu_read_ack_o          <=      1'b0; 
                                ic_read_dma_addr_o      <=      ic_read_dma_first_addr;
                            end
                        end
                    irefill_load_addr:
                        begin
                            ic_read_dma_valid_o     <=      1'b1;
                            cpu_read_ack_o          <=      1'b0;
                        end
                    irefill_load_data:
                        begin
                            ic_read_dma_valid_o     <=      1'b0;
                            ic_read_dma_addr_o      <=      ic_read_dma_addr_o      +       33'd16; //128bits(16x8bits) data, so addr need +16
                            cnt_refill             <=       cnt_refill              +       10'd1;
                            tag_addra_o             <=      ic_read_addr_from_dma[12:4];
                            tag_dina_o              <=      ic_read_addr_from_dma[32:13];
                            ram_addra_o             <=      ic_read_addr_from_dma[12:4];
                            ram_dina_o              <=      ic_read_dma_data_i;

                            ic_data_o               <=      ic_read_dma_data_i;         //return query results of request command.
                            ic_addr_o               <=      cpu_addr_reg;
                            cpu_read_ack_o          <=      1'b1;

                            if(cnt_refill  ==  CACHE_DEPTH)       refill_down     <=  1'b1; //disable preload during next operation.                            
                        end
                    default:
                        begin
                            ic_read_dma_valid_o     <=      1'b0;
                            ic_read_dma_addr_o      <=      first_addr;        //33'h0 in general.
                            ic_data_o               <=      128'd0;
                            ic_addr_o               <=      33'd0;
                            cpu_read_ack_o          <=      1'b0;
                            cnt_preload             <=      10'd0;
   
                        end

        endcase
    end


assign  tag_hit_wired = ( ((cpu_addr_reg[32:13]) == tag_doutb_i) && (cstate == ifetch))? 1'b1:1'b0;
assign  tag_miss_wired = ( (cpu_addr_reg[32:13]) != tag_doutb_i && (cstate == ifetch))? 1'b1:1'b0;


always @(posedge clk or posedge rst)begin
  if(rst)begin
        tag_hit     <=      1'b0;
        tag_miss    <=      1'b0;
  end
    else begin
        tag_hit     <=      tag_hit_wired;
        tag_miss    <=      tag_miss_wired;
    end
end

endmodule
