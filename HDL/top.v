module top(
   input wire clk, rstn
   inout wire scl,
   inout wire sda
);


//-------------Max30100_Init----------------
   wire       maxInit_startI2C; // sinal para iniciar transação I2C
   wire       maxInit_rw;       // 0 = write, 1 = read
   wire [6:0] maxInit_addr;     // endereço do slave
   wire [7:0] maxInit_reg;      // registrador a acessar
   wire [7:0] maxInit_data;     // dado a enviar
   wire       maxInit_done;     // configuração concluída

   max30100 max30100_inst (
      .clk(clk),
      .rstn(rstn),
      .maxInit_start(reg_init_max),           // Inicia configuração  
      .maxInit_i2c_ready(i2c_ready),          // pronto para próxima transação

      .maxInit_i2c_addr(maxInit_rw),            // 0 = write, 1 = read
      .maxInit_i2c_rw(maxInit_addr),        // endereço do slave
      .maxInit_i2c_reg(maxInit_reg),          // registrador a acessar
      .maxInit_i2c_data(maxInit_data),        // dado a enviar
      .maxInit_done(maxInit_done)             // configuração concluída
   );

   //-------------Max30100_RX----------------

   max30100_rx max30100_rx_inst (
      .clk(clk),
      .rstn(rstn),
      .start_read(reg_read_max), // inicia leitura da FIFO
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
   
   //-------------LCD_init----------------
   wire [6:0] lcdInit_adress;
   wire       lcdInit_rw;
   wire       lcdInit_done;     // configuração concluída
   wire [7:0] lcdInit_data;

   lcd_init lcd_init_inst (
      .clk(clk),
      .rstn(rstn),
      .lcd_init_start(reg_init_lcd),     // Inicia configuração
      .lcd_init_I2Cready(i2c_ready),          // configuração concluída

      .lcd__init_addr(lcdInit_adress),
      .lcd__init_rw(lcdInit_rw),
      .lcd__init_data(lcdInit_data),
      .lcd__init_done(lcdInit_done)
   );


   //-------------LCD_Write----------------
   wire [6:0] lcd_Write_adress;
   wire       lcd_Write_rw;
   wire       lcd_Write_done;
   wire [7:0] lcd_Write_data;

   lcd_write lcd_write_inst (
      .clk(clk),
      .rstn(rstn),
      .lcd__write_start(reg_write_lcd),
      .lcd_write_I2Cready(i2c_ready),    // Inicia envio
      
      .lcd__write_addr(lcd_Write_adress),
      .lcd__write_rw(lcd_write_rw),
      .lcd__write_IRdata(lcd_write_data),
      .lcd__write_REDdata(lcd_write_data),
      .lcd__write_done(lcd_write_done)      // Envio concluído
   );

   //-------------I2C---------------------
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
                                                            7'b0001000;

   assign in_i2c_reg   = (currState == STATE_INIT_MAX)    ? max30100_reg:
                         (currState == STATE_RECEIVE_MAX) ? max30100_reg:
                                                           8'b00010000;

   assign in_i2c_data  = (currState == STATE_INIT_MAX)    ? max30100_data:
                         (currState == STATE_RECEIVE_MAX) ? max30100_data:
                                                            8'b00010000;

   assign in_i2c_rw    = (currState == STATE_INIT_MAX)    ? max30100_init_rw :
                         (currState == STATE_RECEIVE_MAX) ? max30100_init_rw :
                                                            1'b0;

   wire out_i2c_ready;          // Pronto para próxima transação

   i2c i2c_inst (
      .fastclk(clk),
      .rstn(rstn),
      .i2c_scl(scl),            // Comunicacao I2C com mundo externo
      .i2c_sda(sda),            // Comunicacao I2C com mundo externo

      .i2c_start(i2c_start),     // sinal para iniciar transação I2C
      .i2c_addr(i2c_addr),       // endereço do slave
      .i2c_reg(i2c_reg),         // registrador a acessar
      .i2c_data(i2c_data),       // dado a enviar
      .i2c_tx_REDsensor(i2c_rw), // 0 = write, 1 = read
      .i2c_tx_IRsensor(i2c_rw),  // 0 = write, 1 = read
      .i2c_rw(i2c_rw),           // 0 = write, 1 = read

      .i2c_rx_REDsensor(i2c_rw), // 0 = write, 1 = read
      .i2c_rx_IRsensor(i2c_rw),  // 0 = write, 1 = read
      .opp_finished(i2c_ready),     // 0 = write, 1 = read

   );

   //-----------------Maquina de Estados-----------------
   reg[2:0] currState, nextState;

   //Estados
   localparam STATE_IDLE          = 3'b000, 
              STATE_INIT_MAX      = 3'b001,
              STATE_INIT_LCD      = 3'b010,
              STATE_RECEIVE_MAX   = 3'b011,
              STATE_MAX_TO_LCD    = 3'b100,
              STATE_SEND_LCD      = 3'b101;
   
   //Mudanca de estado
   always @(posedge clk, negedge rstn) begin
      if (!rstn) begin
         currState <= STATE_IDLE;
      end else begin
         currState <= nextState;
      end  
   end

   //Logica do prox estado
   //Feito só o MAX INIT e ReceiveMAX
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
         STATE_MAX_TO_LCD: begin
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
   reg reg_init_max, reg_init_lcd, reg_read_max, reg_write_lcd;

   always @(currState) begin
      case (currState)
         STATE_IDLE: begin
            reg_init_max  = 1'b0;
            reg_init_lcd  = 1'b0;
            reg_read_max  = 1'b0;
            reg_write_lcd = 1'b0;
         end
         STATE_INIT_MAX: begin
            reg_init_max  = 1'b1;
            reg_init_lcd  = 1'b0;
            reg_read_max  = 1'b0;
            reg_write_lcd = 1'b0;
         end
         STATE_INIT_LCD: begin
            reg_init_max  = 1'b0;
            reg_init_lcd  = 1'b1;
            reg_read_max  = 1'b0;
            reg_write_lcd = 1'b0;
         end
         STATE_RECEIVE_MAX: begin
            reg_init_max  = 1'b0;
            reg_init_lcd  = 1'b0;
            reg_read_max  = 1'b1;
            reg_write_lcd = 1'b0;
         end
         STATE_MAX_TO_LCD: begin
            reg_init_max  = 1'b0;
            reg_init_lcd  = 1'b0;
            reg_read_max  = 1'b0;
            reg_write_lcd = 1'b0;
         end
         STATE_SEND_LCD: begin
            reg_init_max  = 1'b0;
            reg_init_lcd  = 1'b0;
            reg_read_max  = 1'b0;
            reg_write_lcd = 1'b1;
         end
         default: begin
            reg_init_max  = 1'b0;
            reg_init_lcd  = 1'b0;
            reg_read_max  = 1'b0;
            reg_write_lcd = 1'b0;
         end
      endcase
   end

endmodule