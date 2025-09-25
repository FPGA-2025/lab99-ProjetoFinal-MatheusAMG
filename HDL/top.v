module top(
   input wire clk, rstn
   inout wire scl,
   inout wire sda
);


//-------------Max30100_Init----------------
   wire       start_maxInit;      // Inicia configuração

   wire       maxInit_start_i2c;  // sinal para iniciar transação I2C
   wire [6:0] maxInit_addr;       // endereço do slave
   wire [7:0] maxInit_init_reg;   // registrador a acessar
   wire [7:0] maxInit_init_data;  // dado a enviar
   wire       maxInit_init_rw;    // 0 = write, 1 = read
   wire       done;               // configuração concluída
   
   assign start_maxInit = reg_init_max;

   max30100 max30100_inst (
      .clk(clk),
      .rstn(rstn),
      .start(start_maxInit),            // Inicia configuração  
      .i2c_ready(i2c_ready),            // pronto para próxima transação

      .i2c_start(max30100_start_i2c),   // sinal para iniciar transação I2C
      .i2c_rw(max30100_init_rw),        // 0 = write, 1 = read
      .i2c_addr(max30100_addr),         // endereço do slave
      .i2c_reg(max30100_init_reg),      // registrador a acessar
      .i2c_data(maxInit_init_data),     // dado a enviar
      .done(done)                       // configuração concluída
   );

//-------------I2C----------------
   wire in_i2c_start;           // sinal para iniciar transação I2C
   wire [6:0] in_i2c_addr;      // endereço do slave
   wire [7:0] in_i2c_reg;       // registrador a acessar
   wire [7:0] in_i2c_data;      // dado a enviar
   wire in_i2c_rw;              // 0 = write, 1 = read

   wire i2c_ready;              // i2c envia sinal que pode ir para próxoximo estado
   
   assign in_i2c_start = (currState == STATE_INIT_MAX)    ? max30100_start_i2c:
                         (currState == STATE_RECEIVE_MAX) ? 1'b1: 
                                                            1'b0;

   assign in_i2c_addr  = (currState == STATE_INIT_MAX)    ? max30100_addr:
                         (currState == STATE_RECEIVE_MAX) ? max30100_addr:
                                                           7'b0000000;

   assign in_i2c_reg   = (currState == STATE_INIT_MAX)    ? max30100_reg:
                         (currState == STATE_RECEIVE_MAX) ? max30100_reg:
                                                           8'b00000000;

   assign in_i2c_data  = (currState == STATE_INIT_MAX)    ? max30100_data:
                         (currState == STATE_RECEIVE_MAX) ? max30100_data:
                                                           8'b00000000;

   assign in_i2c_rw    = (currState == STATE_INIT_MAX)    ? max30100_init_rw :
                         (currState == STATE_RECEIVE_MAX) ? max30100_init_rw :
                                                           1'b0;

   wire out_i2c_ready;          // Pronto para próxima transação

   i2c i2c_inst (
      .fastclk(clk),
      .rstn(rstn),
      .scl(scl),
      .sda(sda),
      .i2c_start(in_i2c_start), // sinal para iniciar transação I2C
      .i2c_addr(i2c_addr),      // endereço do slave
      .i2c_reg(i2c_reg),        // registrador a acessar
      .i2c_data(i2c_data),      // dado a enviar
      .i2c_rw(i2c_rw),          // 0 = write, 1 = read
      .ok(i2c_ready)
   );

   // Preciso de um mux nos parametros do i2c


   //-------------Max30100_RX----------------
   //refazer modulo
   wire        start_read;         // inicia leitura da FIFO
   wire        busy;               // ocupado durante a leitura
   wire        data_valid;         // 1 quando IR/RED prontos
   wire [15:0] ir_data;            // dado IR
   wire [15:0] red_data;           // dado RED

   assign start_read = reg_read_max;

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
   //-----------------Maquina de Estados-----------------
   reg[2:0] currState, nextState;

   //Estados
   localparam STATE_IDLE          = 3'b000, 
              STATE_INIT_MAX      = 3'b001,
              STATE_INIT_LCD      = 3'b010,
              STATE_RECEIVE_MAX   = 3'b011,
              STATE_SEND_LCD      = 3'b100,
   
   //Mudanca de estado
   always @(posedge clk, negedge rstn) begin
      if (!rstn) begin
         currState <= STATE_IDLE;
      end else begin
         currState <= nextState;
      end  
   end

   //Proximo estado
   always @(currState) begin
      case (currState)
         STATE_IDLE: begin
            if (!done) nextState = STATE_INIT_MAX;
            else nextState = STATE_IDLE;
         end
         STATE_INIT_MAX: begin
            if (done) nextState = STATE_INIT_LCD;
            else nextState = STATE_INIT_MAX;
         end
         STATE_INIT_LCD: begin
            if (done) nextState = STATE_RECEIVE_MAX;
            else nextState = STATE_SEND_LCD;
         end
         STATE_RECEIVE_MAX: begin
            if (done) nextState = STATE_SEND_LCD;
            else nextState = STATE_RECEIVE_MAX;
         end
         STATE_SEND_LCD: begin
            if (done) nextState = STATE_RECEIVE_MAX;
            else nextState = STATE_SEND_LCD;
         end
         default: nextState = STATE_IDLE;
      endcase
   end
   //Sinais de controle
   reg reg_init_max, reg_init_lcd, reg_read_max, reg_send_lcd;

   always @(currState) begin
      case (currState)
         STATE_IDLE: begin
            reg_init_max = 1'b0;
            reg_init_lcd = 1'b0;
            reg_read_max = 1'b0;
            reg_send_lcd = 1'b0;
         end
         STATE_INIT_MAX: begin
            reg_init_max = 1'b1;
            reg_init_lcd = 1'b0;
            reg_read_max = 1'b0;
            reg_send_lcd = 1'b0;
         end
         STATE_INIT_LCD: begin
            reg_init_max = 1'b0;
            reg_init_lcd = 1'b1;
            reg_read_max = 1'b0;
            reg_send_lcd = 1'b0;
         end
         STATE_RECEIVE_MAX: begin
            reg_init_max = 1'b0;
            reg_init_lcd = 1'b0;
            reg_read_max = 1'b1;
            reg_send_lcd = 1'b0;
         end
         STATE_SEND_LCD: begin
            reg_init_max = 1'b0;
            reg_init_lcd = 1'b0;
            reg_read_max = 1'b0;
            reg_send_lcd = 1'b1;
         end
         default: begin
            reg_init_max = 1'b0;
            reg_init_lcd = 1'b0;
            reg_read_max = 1'b0;
            reg_send_lcd = 1'b0;
         end
      endcase
   end

endmodule