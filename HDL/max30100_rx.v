module max30100_rx(
   input  wire        clk,
   input  wire        rst_n,
   input  wire        maxRX_start,      // inicia leitura da FIFO
   input  wire        maxRX_i2c_ready,

   output wire [6:0] maxInit_i2c_addr,    // endereço do slave
   output wire       maxInit_i2c_rw,      // 0 = write, 1 = read
   output reg  [7:0] maxInit_i2c_reg,
   output reg        maxInit_done,
);

    localparam MAX30100_ADDR = 7'h57;
    localparam FIFO_REG      = 8'h05;  // início da FIFO (IR_H)

    reg [3:0] state;
    
    reg [7:0] ir_high, ir_low, red_high, red_low;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= 0;
            busy       <= 0;
            data_valid <= 0;
            i2c_start  <= 0;
        end else begin
            case (state)
                0: begin
                    data_valid <= 0;
                    if (start_read) begin
                        busy      <= 1;
                        i2c_addr  <= MAX30100_ADDR;
                        i2c_reg   <= FIFO_REG;
                        i2c_rw    <= 1;        // leitura
                        i2c_start <= 1;
                        state     <= 1;
                    end
                end

                1: begin
                    i2c_start <= 0;
                    if (i2c_ready) begin
                        ir_high  <= i2c_rdata;
                        state    <= 2;
                        i2c_reg  <= FIFO_REG + 1;
                        i2c_start <= 1;
                    end
                end

                2: begin
                    i2c_start <= 0;
                    if (i2c_ready) begin
                        ir_low   <= i2c_rdata;
                        state    <= 3;
                        i2c_reg  <= FIFO_REG + 2;
                        i2c_start <= 1;
                    end
                end

                3: begin
                    i2c_start <= 0;
                    if (i2c_ready) begin
                        red_high <= i2c_rdata;
                        state    <= 4;
                        i2c_reg  <= FIFO_REG + 3;
                        i2c_start <= 1;
                    end
                end

                4: begin
                    i2c_start <= 0;
                    if (i2c_ready) begin
                        red_low  <= i2c_rdata;
                        state    <= 5;
                    end
                end

                5: begin
                    // junta os 16 bits
                    ir_data   <= {ir_high, ir_low};
                    red_data  <= {red_high, red_low};
                    data_valid <= 1;
                    busy       <= 0;
                    state      <= 0;
                end
            endcase
        end
    end

endmodule
