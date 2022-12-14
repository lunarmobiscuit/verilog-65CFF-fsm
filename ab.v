/*
 * Address Bus (and PC) generator
 *
 * Copyright (C) Arlet Ottens, 2022, <arlet@c-scape.nl>
 * modification from the 65C02 (C) Luni Libes, <https://www.lunarmobiscuit.com/the-apple-4-or-the-mos-652402/>
 */

module ab(
    input clk,
    input RST,
    input [9:0] ab_op,
`ifdef STACK
    input [7:0] S,
`endif
    input [7:0] DI,
    input [7:0] DR,
    input [7:0] XY,
`ifdef AB13
    output [12:0] AB,
    output reg [12:0] PC );
`elsif AB14
    output [13:0] AB,
    output reg [13:0] PC );
`else
    output [15:0] AB,
    output reg [15:0] PC );
`endif

reg [7:0] ABH;
reg [7:0] ABL;
assign AB = { ABH, ABL };


/* 
 * ab_hold stores a copy of current address to be used
 * later.
 */
`ifdef AB13
    reg [12:0] ab_hold;
`elsif AB14
    reg [13:0] ab_hold;
`else
    reg [15:0] ab_hold;
`endif

always @(posedge clk)
    if( ab_op[7] ) 
        ab_hold = AB;

/*
 * update program counter
 */
always @(posedge clk)
    if( RST ) 
        PC <= 16'hfffc;
    else case( ab_op[6:5] )
        2'b01: PC <= AB + 16'h1;
        2'b10: PC <= 16'hfffa;
        2'b11: PC <= 16'hfffe;
    endcase

/*
 * determine base address
 */
`ifdef AB13
    reg [12:0] base;
`elsif AB14
    reg [13:0] base;
`else
    reg [15:0] base;
`endif

always @*
    case( ab_op[4:3] )
`ifdef STACK    
       2'b00: base = {8'h00, S};
`endif
       2'b01: base = PC;
       2'b10: base = {DI, DR};
       2'b11: base = ab_hold;
    endcase

/*
 * add offset to the base address. We split the address into
 * two separate bytes, because sometimes the address should
 * wrap within the page, so we can't always let the carry 
 * go through.
 */

wire abl_ci = ab_op[0];     // carry input from operation
reg abl_co;                 // carry output from low byte

always @* begin
    case( ab_op[2:1] )
        2'b00: {abl_co, ABL} = base[7:0] + 00 + abl_ci;
        2'b01: {abl_co, ABL} = base[7:0] + XY + abl_ci;
        2'b10: {abl_co, ABL} = base[7:0] + DI + abl_ci;
        2'b11: {abl_co, ABL} = XY        + DI + abl_ci;
    endcase
end

/*
 * carry input for high byte 
 */
wire abh_ci = ab_op[9] & abl_co;

/* 
 * calculate address high byte
 */
always @* begin
    case( ab_op[9:8] )
`ifdef AB13
        2'b00: ABH = base[12:8] + 8'h00 + abh_ci;   // ci = 0
        2'b01: ABH = base[12:8] + 8'h01 + abh_ci;   // ci = 0
        2'b10: ABH = base[12:8] + 8'h00 + abh_ci;   // ci = abl_ci
        2'b11: ABH = base[12:8] + 8'hff + abh_ci;   // ci = abl_ci
`elsif AB14
        2'b00: ABH = base[13:8] + 8'h00 + abh_ci;   // ci = 0
        2'b01: ABH = base[13:8] + 8'h01 + abh_ci;   // ci = 0
        2'b10: ABH = base[13:8] + 8'h00 + abh_ci;   // ci = abl_ci
        2'b11: ABH = base[13:8] + 8'hff + abh_ci;   // ci = abl_ci
`else
        2'b00: ABH = base[15:8] + 8'h00 + abh_ci;   // ci = 0
        2'b01: ABH = base[15:8] + 8'h01 + abh_ci;   // ci = 0
        2'b10: ABH = base[15:8] + 8'h00 + abh_ci;   // ci = abl_ci
        2'b11: ABH = base[15:8] + 8'hff + abh_ci;   // ci = abl_ci
`endif
    endcase
end

endmodule
