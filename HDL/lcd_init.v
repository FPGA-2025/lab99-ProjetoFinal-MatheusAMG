module lcd_init (
   input wire clk,
   input wire rstn,
   input wire lcd_init_start,
   input wire lcd_init_I2Cready,

   output wire [6:0] lcd__init_addr,
   output wire       lcd__init_rw,
   output wire [7:0] lcd__init_reg,
   output wire [7:0] lcd__init_data,
   output wire       lcd__init_done,
);
   // TODO
endmodule