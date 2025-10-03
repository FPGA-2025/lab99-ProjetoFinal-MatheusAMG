module lcd_write (
   input wire clk,
   input wire rstn,
   input wire lcd__write_start,
   input wire lcd_write_I2Cready,

   output wire [6:0] lcd__write_addr,
   output wire lcd__write_rw,
   output wire [7:0] lcd__write_reg,
   output wire [15:0] lcd__write_IRdata,
   output wire [15:0] lcd__write_REDdata,
   output wire lcd__write_done,

);
   // TODO
   
endmodule