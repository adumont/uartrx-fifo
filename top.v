`default_nettype none
//`include "const.vh"

module top (
        input  wire       clk,       // System clock.

        input  wire       RX,
        output wire       TX,

        input  wire       sw1,    // board button 1
        input  wire       sw2,    // board button 2
        output wire [7:0] leds       // board leds
    );

    localparam baudsDivider=24'd104;

    wire sw1_d; // pulse when sw pressed
    wire sw1_u; // pulse when sw released
    wire sw1_s; // sw state
    debouncer db_sw1 (.clk(clk), .PB(sw1), .PB_down(sw1_d), .PB_up(sw1_u), .PB_state(sw1_s));

    // UART-RX instantiation
    wire       rxuartlite0_o_wr;
    wire [7:0] rxuartlite0_o_data;
    rxuartlite #(.CLOCKS_PER_BAUD(baudsDivider)) rxuartlite0 (
        .i_clk(clk),
        .i_uart_rx(RX),
        .o_wr(rxuartlite0_o_wr),
        .o_data(rxuartlite0_o_data)
    );

    // FIFO instantiation
    wire [7:0] ufifo0_o_data;
    wire ufifo0_o_err; // full
    wire ufifo0_o_empty_n; // not empty
    ufifo #(.LGFLEN(4'd3)) ufifo0 (
        .i_clk(clk),
        .i_rst(1'b0),
        // write port (push)
        .i_wr(rxuartlite0_o_wr),
        .i_data(rxuartlite0_o_data),
        // read port (pop)
        .i_rd(sw1_d),
        .o_data(ufifo0_o_data),
        // flags
        .o_empty_n(ufifo0_o_empty_n), // not empty
        .o_status(),
        .o_err( ufifo0_o_err ) // overflow aka full
    );

    // Register for LEDs
    reg [7:0] r_leds = 0;
    reg r_txuartlite0_i_wr;

    always @( posedge clk) begin
        r_txuartlite0_i_wr <= 0;
        r_leds <= r_leds;

        if(sw1_d) begin
            if(ufifo0_o_empty_n) begin
                // FIFO not empty
                r_leds <= ufifo0_o_data;
                r_txuartlite0_i_wr <= 1;
            end
            else begin
                r_txuartlite0_i_wr <= 0;
                r_leds <= 8'b0;
            end
        end 
    end

    assign leds = r_leds;

    // UART-TX instantiation
    txuartlite #(.CLOCKS_PER_BAUD(baudsDivider)) txuartlite0 (
        .i_clk(clk),
        .i_wr(r_txuartlite0_i_wr),
        .i_data(r_leds),
        .o_uart_tx(TX),
        .o_busy()
    );

endmodule
