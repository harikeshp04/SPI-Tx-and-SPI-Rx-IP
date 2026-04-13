module spi_top (
    input clk,
    input rst,
    input start,
    input [7:0] master_data_in,
    input [7:0] slave_data_in,

    output [7:0] master_data_out,
    output [7:0] slave_data_out,
    output done
);

wire sclk, mosi, miso, cs;

spi_master master (
    .clk(clk),
    .rst(rst),
    .start(start),
    .data_in(master_data_in),
    .miso(miso),
    .sclk(sclk),
    .mosi(mosi),
    .cs(cs),
    .data_out(master_data_out),
    .done(done)
);

spi_slave slave (
    .sclk(sclk),
    .cs(cs),
    .mosi(mosi),
    .data_in(slave_data_in),
    .miso(miso),
    .data_out(slave_data_out)
);

endmodule
