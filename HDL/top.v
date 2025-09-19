module top(
   input wire clk, rstn
   inout wire scl,
   inout wire sda
);

//Dado vai ser enviado do max30100 para o i2c através dos cabos dado addr e reg

//-------------Max30100_Init----------------
   wire       start_init;          // sinal para iniciar transação I2C
   wire [6:0] i2c_addr;            // endereço do slave
   wire [7:0] i2c_reg;             // registrador a acessar
   wire [7:0] i2c_data;            // dado a enviar
   wire       i2c_rw;              // 0 = write, 1 = read
   wire       i2c_ready;
   wire       done;                // configuração concluída

//-------------Max30100_RX----------------
   wire        start_read;         // inicia leitura da FIFO
   wire        busy;               // ocupado durante a leitura
   wire        data_valid;         // 1 quando IR/RED prontos
   wire [15:0] ir_data;            // dado IR
   wire [15:0] red_data;           // dado RED


//-------------I2C----------------
   wire i2c_start;           // sinal para iniciar transação I2C
   wire [6:0] i2c_addr;      // endereço do slave
   wire [7:0] i2c_reg;       // registrador a acessar
   wire [7:0] i2c_data;      // dado a enviar
   wire i2c_rw_tx;           // 0 = write, 1 = read

   i2c i2c_inst (
      .fastclk(clk),
      .rstn(rstn),
      .scl(scl),
      .sda(sda),
      .i2c_start(i2c_start),   // sinal para iniciar transação I2C
      .i2c_addr(i2c_addr),     // endereço do slave
      .i2c_reg(i2c_reg),       // registrador a acessar
      .i2c_data(i2c_data),     // dado a enviar
      .i2c_rw_tx(i2c_rw),      // 0 = write, 1 = read
      .ok(i2c_ready)
   );

   max30100 max30100_inst (
      .clk(clk),
      .rstn(rstn),
      .start(start_init),      // Inicia configuração  
      .i2c_ready(i2c_ready),   // pronto para próxima transação

      .i2c_start(i2c_start),   // sinal para iniciar transação I2C
      .i2c_rw(i2c_rw),         // 0 = write, 1 = read
      .i2c_addr(i2c_addr),     // endereço do slave
      .i2c_reg(i2c_reg),       // registrador a acessar
      .i2c_data(i2c_data),     // dado a enviar
      .done(done)              // configuração concluída
   );

   max30100_rx max30100_rx_inst (
      .clk(clk),
      .rstn(rstn),
      .start_read(start_read), // inicia leitura da FIFO
      .i2c_rdata(i2c_rdata),
      .i2c_ready(i2c_ready)    // i2c envia sinal que pode ir para próxoximo estado

      .data_valid(data_valid), // 1 quando IR/RED prontos
      .ir_data(ir_data),       // dado IR
      .red_data(red_data),     // dado RED
      .busy(busy),             // ocupado durante a leitura
      .i2c_start(i2c_start),   // sinal para iniciar transação I2C
      .i2c_rw(i2c_rw),         // 0=write, 1=read
      .i2c_addr(i2c_addr),
      .i2c_reg(i2c_reg),
      .i2c_wdata(i2c_wdata),
   );

endmodule