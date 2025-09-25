module max30100_init (
   input  wire       clk,
   input  wire       rst_n,
   input  wire       start,       // sinal para iniciar configuração
   input  wire       i2c_ready    // pronto para próxima transação
   
   output wire [6:0]  i2c_addr,    // endereço do slave
   output wire        i2c_rw,      // 0 = write, 1 = read
   output reg         i2c_start,
   output reg [7:0]   i2c_reg,     // registrador a acessar
   output reg [7:0]   i2c_data,    // dado a enviar
   output reg         done,        // configuração concluída
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
   reg [2:0] currState;


   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         currState  <= 0;
         done       <= 0;
         i2c_start  <= 0;
      end 
      else begin
         case (currState)
            0: begin
               if (start) begin
                  // Escreve REG_MODE
                  i2c_reg   <= REG_MODE;
                  i2c_data  <= MODE_SPO2;
                  i2c_start <= 1;
                  currState <= 1;
               end
            end

            1: begin
                 i2c_start <= 0;
                 if (i2c_ready) begin
                     // Escreve REG_SPO2_CFG
                     i2c_reg   <= REG_SPO2;
                     i2c_data  <= SPO2_CFG;
                     i2c_start <= 1;
                     currState <= 2;
                  end
            end

            2: begin
               i2c_start <= 0;
               if (i2c_ready) begin
               // Escreve REG_LED_CFG
                  i2c_reg   <= REG_LED;
                  i2c_data  <= LED_CFG;
                  i2c_start <= 1;
                  currState <= 3;
                  end
            end

            3: begin
               i2c_start <= 0;
               if (i2c_ready) begin
                  done  <= 1;
                  currState <= 3; // fica aqui
               end
            end

            default: currState <= 0;

         endcase

      end

   end

endmodule

