`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/15 09:13:19
// Design Name: 
// Module Name: test_cpu_instr
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
module test_cpu_instr(

);   

// cpu_top Parameters
parameter PERIOD  = 5;
parameter test_cpu_data = 128'hA000_0000_0000_0000_0000_0D00_0000_0011;

// cpu_top Inputs
reg   clk                                  = 0 ;
reg   rst                                  = 1 ;
reg   start                                = 0 ;
reg   stop                                 = 0 ;
reg   [32:0]  start_addr                   = 0 ;
reg   [127:0]  cpu_read_data               = 0 ;
reg   cpu_read_ack                         = 0 ;
reg   axis_ready                           = 0 ;

// cpu_top Outputs
wire  cpu_read_valid                       ;
wire  [32:0]  cpu_read_addr                   ;
wire  [127:0]  segment_instruc             ;
wire  segment_instruc_valid                ;
wire  [31:0]  axis_data                    ;
wire  axis_valid                           ;
wire  axis_last                            ;


reg [31:0] data [7:0];

// ideal output
initial begin

    data[0] = 32'h80002000;
    data[1] = 32'h0;
    data[2] = 32'd0;
    data[3] = 32'd0;
    data[4] = 32'd0;
    data[5] = 32'd0;
    data[6] = {6'b000011, 26'hd00};
    data[7] = 32'd0;

end



initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #(PERIOD*2) rst  =  0;
end

initial begin
     #(PERIOD*2) axis_ready = 1'b1;
end
// add test vectors
initial 
begin
    $display("Time:%d ns; test vectors generate start", $stime);
    start = 1;
    start_addr = 33'd0;
    @(posedge clk)
        wait(cpu_read_valid);
    repeat(3) @(posedge clk);
    @(posedge clk);
    cpu_read_data = test_cpu_data;
    cpu_read_ack  =  1'b1;
    @(posedge clk)
    cpu_read_data = 128'd0;
    cpu_read_ack  =  1'b0;

    //generate a stop pulse signal in clk domain. 
    @(posedge clk);
    @(posedge clk)
        stop  = 1'b1;
    @(posedge clk)
        stop  = 1'b0;

    //#1000;
    //$display("Time:%d ns; test vectors generate over", $stime);
    //$finish;
end

integer i, errors = 0;

always @(posedge clk)begin
    if(stop) begin
        i = 0 ;
        errors = 0;
    end
    else if (start && axis_valid)begin
        $display("------------------------");
        for (i = 0; i < 8; i = i + 1)begin
            @ (negedge clk)begin
                if(axis_data  == data[i])begin
                    $display ("Time: %d, data is matched and data is %h", $time, axis_data);
                end
                else begin
                    errors = errors + 1;
                    if (errors  == 0) $display("Test over, 0 errors!");
                    else $display ("Time: %d, data is unmatched, error = %d, axis_data = %h, data is %h",$time, errors, axis_data, data[i]);
                end
            end     
        end
    end

end

cpu_top  u_cpu_top (
    .clk                     ( clk                            ),
    .rst                     ( rst                            ),
    .start                   ( start                          ),
    .stop                    ( stop                           ),
    .start_addr              ( start_addr             [32:0]  ),
    .cpu_read_data           ( cpu_read_data          [127:0] ),
    .cpu_read_ack            ( cpu_read_ack                   ),
    .axis_ready              ( axis_ready                     ),

    .cpu_read_valid          ( cpu_read_valid                 ),
    .cpu_read_addr           ( cpu_read_addr          [32:0]  ),
    .segment_instruc         ( segment_instruc        [127:0] ),
    .segment_instruc_valid   ( segment_instruc_valid          ),
    .axis_data               ( axis_data              [31:0]  ),
    .axis_valid              ( axis_valid                     ),
    .axis_last               ( axis_last                      )
);
 

endmodule
