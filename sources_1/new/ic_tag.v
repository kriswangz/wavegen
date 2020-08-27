`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/06/29 20:24:45
// Design Name: 
// Module Name: ic_tag
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


module ic_tag_top(
    clka,
    wea,
    addra,
    dina,
    
    clkb,
    addrb,
    doutb
    );

    parameter tag_dw = 20;
    parameter tag_aw = 9;

    input   clka;
    input   wea;
    input   [tag_aw -1 : 0]     addra;
    input   [tag_dw -1 : 0]     dina;
    
    input   clkb;
    input   [tag_aw -1 : 0]     addrb;
    output   [tag_dw -1 : 0]     doutb;

    ic_tag ic_tag_inst ( 
    .clka(clka),    // input wire clka
    .ena(1'b1),      // input wire ena
    .wea(wea),      // input wire [0 : 0] wea
    .addra(addra),  // input wire [8 : 0] addra
    .dina(dina),    // input wire [19 : 0] dina
    
    .clkb(clkb),    // input wire clkb
    .enb(1'b1),      // input wire enb
    .addrb(addrb),  // input wire [8 : 0] addrb
    .doutb(doutb)  // output wire [19 : 0] doutb
);

endmodule
