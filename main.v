/*
 * (C) Arlet Ottens <arlet@c-scape.nl>
 * Verilog-only changes (C) Luni Libes
 */

module main;

`ifdef SIM

integer CYCLES = 1000;

reg clk = 0;
reg RST = 0;
wire sync;
`ifdef IRQ
    reg IRQ = 0;
    reg NMI = 0;
`endif

`ifdef AB13
    wire [12:0] AB;
`elsif AB14
    wire [13:0] AB;
`else
    wire [15:0] AB;
`endif

wire [7:0] DI;
wire [7:0] DO;
wire WE;

reg RDY = 1;

ram ram( 
    .clk(clk),
`ifdef ONEND
    .onend(onend),
`endif
    .RDY(RDY),
    .AB(AB),
    .DI(DI),
    .DO(DO),
    .WE(WE));

cpu cpu(
    .clk(clk), 
`ifdef ONEND
    .onend(onend),
`endif
    .RST(RST), 
    .AB(AB), 
    .sync(sync), 
    .DI(DI),
    .DO(DO),
    .WE(WE),
`ifdef IRQ 
    .IRQ(IRQ), 
    .NMI(NMI),
`endif 
    .RDY(RDY));

initial 
    begin
        //$monitor ("T=%0t clk=%0b AB=%h DI=%h DO=%h WE=%0b RST=%0b", $time, clk, AB, DI, DO, WE, RST);

        RST = 1;
        #500 clk = 1;
        #500 RST = 0;
        clk = 0;

        for (integer i = 0; i < CYCLES*2; i = i+1) begin
            #(1000/2) clk = ~clk;
        end

        $finish;
    end

`endif

endmodule
