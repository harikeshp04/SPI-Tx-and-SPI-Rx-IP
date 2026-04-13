`timescale 1ns/1ps

module tb_spi;

reg clk, rst, start;
reg [7:0] master_data_in, slave_data_in;

wire [7:0] master_data_out, slave_data_out;
wire done;

spi_top dut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .master_data_in(master_data_in),
    .slave_data_in(slave_data_in),
    .master_data_out(master_data_out),
    .slave_data_out(slave_data_out),
    .done(done)
);

// Clock generation (10ns period)
always #5 clk = ~clk;

initial begin
    clk = 0;
    rst = 1;
    start = 0;

    master_data_in = 8'hA5;
    slave_data_in  = 8'h3C;

    // Waveform dump
    $dumpfile("spi.vcd");
    $dumpvars(0, tb_spi);

    // Reset release
    #20 rst = 0;

    // Start SPI transfer
    #10 start = 1;
    #10 start = 0;

    // Wait until done
    wait(done);

    #20;

    // Check results
    if (master_data_out == slave_data_in)
        $display("MASTER RECEIVED CORRECT: %h", master_data_out);
    else
        $display("ERROR in master");

    if (slave_data_out == master_data_in)
        $display("SLAVE RECEIVED CORRECT: %h", slave_data_out);
    else
        $display("ERROR in slave");

    #20 $finish;
end

endmodule