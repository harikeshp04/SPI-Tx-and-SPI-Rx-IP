module spi_slave (
    input sclk,
    input cs,
    input mosi,
    input [7:0] data_in,

    output reg miso,
    output reg [7:0] data_out
);

reg [7:0] shift_tx;
reg [2:0] bit_cnt;

// Pure synchronous design
always @(posedge sclk) begin
    if (cs) begin
        // Reset when CS is HIGH
        shift_tx <= data_in;
        bit_cnt <= 3'd7;
        miso <= data_in[7];
        data_out <= 8'd0;
    end 
    else begin
        // Sample MOSI
        data_out[bit_cnt] <= mosi;

        // Drive MISO
        miso <= shift_tx[bit_cnt];

        if (bit_cnt == 0)
            bit_cnt <= 3'd7;
        else
            bit_cnt <= bit_cnt - 1;
    end
end

endmodule
