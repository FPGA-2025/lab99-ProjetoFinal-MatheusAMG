module max30100_init (
   input  wire       clk,
   input  wire       rst_n,
   input  wire       maxInit_start,       // sinal para iniciar configuração
   input  wire       maxInit_i2c_ready    // pronto para próxima transação
   
   output wire [6:0] maxInit_i2c_addr,    // endereço do slave
   output wire       maxInit_i2c_rw,      // 0 = write, 1 = read
   output reg [7:0]  maxInit_i2c_reg,     // registrador a acessar
   output reg [7:0]  maxInit_i2c_data,    // dado a enviar
   output reg        maxInit_done,        // configuração concluída
);

   // Endereço fixo do MAX30100 (7 bits)
   localparam MAX30100_ADDR = 7'h57;
   assign i2c_addr = MAX30100_ADDR;
   assign i2c_rw   = 1'b0; // sempre escrita

   // Registradores
   localparam REG_MODE   = 8'h06;
   localparam REG_SPO2   = 8'h07;
   localparam REG_LED    = 8'h09;

   // Valores típicos de configuração
   localparam MODE_SPO2  = 8'h03; // SpO2 (HR + SpO2)
   localparam SPO2_CFG   = 8'h27; // 100 Hz sample rate, high-res
   localparam LED_CFG    = 8'h24; // corrente: IR = 6.2 mA, RED = 25.4 mA

   // FSM
   reg [1:0] currState, nextState;

   localparam [2:0] STATE_IDLE       = 3'b000,
                    CONFIG_OPP_MODE  = 3'b001,
                    STATE_WAIT_01    = 3'b010,
                    CONFIG_SPO2      = 3'b011,
                    STATE_WAIT_02    = 3'b100,
                    CONFIG_LEDS      = 3'b101,
                    STATE_WAIT_03    = 3'b110,
                    STATE_DONE       = 3'b111;

   always @(currState) begin
      case (currState)
         STATE_IDLE: begin
            if (start)     nextState = CONFIG_OPP_MODE;
            else           nextState = STATE_IDLE;
         end
         CONFIG_OPP_MODE: begin
            nextState = STATE_WAIT_01;
         end
         STATE_WAIT_01: begin
            if (i2c_ready) nextState = CONFIG_SPO2;
            else           nextState = STATE_WAIT_01;
         end
         CONFIG_SPO2: begin
            nextState = STATE_WAIT_02;
         end
         STATE_WAIT_02: begin
            if (i2c_ready) nextState = CONFIG_LEDS;
            else           nextState = STATE_WAIT_02;
         end
         CONFIG_LEDS: begin
            nextState = STATE_WAIT_03;
         end
         STATE_WAIT_03: begin
            if (i2c_ready) nextState = STATE_DONE;
            else           nextState = STATE_WAIT_03;
         end
         STATE_DONE: begin
            nextState = STATE_DONE; // permanece aqui
         end
         default: STATE_IDLE;
      endcase
   end

   always @(posedge clk, negedge rst_n) begin
      if (!rst_n) currState <= CONFIG_OPP_MODE;
      else        currState <= nextState;
   end

   always @(currState) begin
      case (currState)

         STATE_IDLE: begin  
            i2c_start = 0;
            i2c_reg   = 8'h00;
            i2c_data  = 8'h00;
            done      = 0;
         end

         CONFIG_OPP_MODE: begin  // Escreve REG_MODE 
            i2c_start = 1;
            i2c_reg   = REG_MODE;
            i2c_data  = MODE_SPO2;
            done      = 0;
         end

         STATE_WAIT_01: begin  
            i2c_start = 0;
            i2c_reg   = 8'h00;
            i2c_data  = 8'h00;
            done      = 0;
         end

         CONFIG_SPO2: begin    // Escreve REG_SPO2_CFG
            i2c_start = 1;
            i2c_reg   = REG_SPO2;
            i2c_data  = SPO2_CFG;
            done      = 0;
         end

         STATE_WAIT_02: begin  
            i2c_start = 0;
            i2c_reg   = 8'h00;
            i2c_data  = 8'h00;
            done      = 0;
         end


         CONFIG_LEDS: begin   // Escreve REG_LED_CFG
            i2c_start = 1;
            i2c_reg   = REG_LED;
            i2c_data  = LED_CFG;
            done      = 0;
         end

         STATE_WAIT_03: begin  
            i2c_start = 0;
            i2c_reg   = 8'h00;
            i2c_data  = 8'h00;
            done      = 0;
         end

         STATE_DONE: begin
            i2c_start = 0;
            i2c_reg   = 8'h00;
            i2c_data  = 8'h00;
            done  = 1;
         end

         default: begin
            i2c_start = 0;
            i2c_reg   = 8'h00;
            i2c_data  = 8'h00;
            done  = 0;
         end

      endcase
   end

endmodule

