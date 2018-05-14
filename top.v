`default_nettype none
//`include "const.vh"

// check connections to VGA adapter on https://github.com/Obijuan/MonsterLED/wiki

module top (
        input  wire       clk,       // System clock.

        input  wire       RX,       // RX

        input  wire       sw1,    // board button 1
        input  wire       sw2,    // board button 2
        output wire [7:0] leds       // board leds
    );

    wire sw1_d; // pulse when sw pressed
    wire sw1_u; // pulse when sw released
    wire sw1_s; // sw state
    debouncer db_sw1 (.clk(clk), .PB(sw1), .PB_down(sw1_d), .PB_up(sw1_u), .PB_state(sw1_s));

    // UART-RX instantiation
    wire       rxuartlite0_o_wr;
    wire [7:0] rxuartlite0_o_data;
    rxuartlite #(.CLOCKS_PER_BAUD(24'd104)) rxuartlite0 (.i_clk(clk), .i_uart_rx(RX), .o_wr(rxuartlite0_o_wr), .o_data(rxuartlite0_o_data));

    // FIFO instantiation
    wire [7:0] ufifo0_o_data;
    ufifo #(.LGFLEN(4'd10)) ufifo0 (
        .i_clk(clk),
        .i_rst(1'b0),
        .i_wr(rxuartlite0_o_wr),
        .i_data(rxuartlite0_o_data),
        .i_rd(sw1_d),
        .o_data(ufifo0_o_data),
        .o_empty_n(),
        .o_status(),
        .o_err()
    );

    reg ctl_reg_leds = 0;
    always @( posedge clk) begin
        ctl_reg_leds <= sw1_d;
    end

    // Register for LEDs
    reg [7:0] r_leds = 0;

    // always @( posedge clk) begin
    //     if(ctl_reg_leds) r_leds <= ufifo0_o_data;
    // end

    always @( posedge clk) begin
        if(rxuartlite0_o_wr) r_leds <= rxuartlite0_o_data;
    end

    assign leds = r_leds;

endmodule
