module spi_master (
    input clk,
    input rst,
    input start,
    input [7:0] data_in,
    input miso,

    output reg sclk,
    output reg mosi,
    output reg cs,
    output reg [7:0] data_out,
    output reg done
);

localparam IDLE=0, LOAD=1, TRANSFER=2, DONE=3;
reg [1:0] state;

reg [7:0] shift_tx, shift_rx;
reg [2:0] bit_cnt;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
        cs <= 1;
        sclk <= 0;      // CPOL = 0
        done <= 0;

        // ✅ FIXED INITIALIZATION
        mosi <= 0;
        data_out <= 0;
        shift_rx <= 0;
    end 
    else begin
        case(state)

        IDLE: begin
            cs <= 1;
            done <= 0;
            sclk <= 0;
            if (start)
                state <= LOAD;
        end

        LOAD: begin
            cs <= 0;
            shift_tx <= data_in;
            shift_rx <= 0;
            bit_cnt <= 3'd7;

            // ✅ FIX: preload first bit before first clock
            mosi <= data_in[7];

            state <= TRANSFER;
        end

        TRANSFER: begin
            sclk <= ~sclk;

            if (sclk == 0) begin
                // Falling edge → launch next bit
                mosi <= shift_tx[bit_cnt];
            end 
            else begin
                // Rising edge → sample
                shift_rx[bit_cnt] <= miso;

                if (bit_cnt == 0)
                    state <= DONE;
                else
                    bit_cnt <= bit_cnt - 1;
            end
        end

        DONE: begin
            cs <= 1;
            data_out <= shift_rx;
            done <= 1;
            state <= IDLE;
        end

        endcase
    end
end

endmodule
