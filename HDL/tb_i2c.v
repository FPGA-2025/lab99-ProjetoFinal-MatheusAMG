module tb_i2c;
   
reg fastclk;
reg rstn;
reg start;
reg [6:0] address;
reg [7:0] register;
reg sda_in;
reg scl_in;
wire[4:0] state; // For debug
wire [7:0] data;
wire sda;
wire scl;
wire finished;
wire ack;

	input wire fastclk, rstn ,
	inout wire scl,
	inout wire sda,
	output sl_clk,
	output ok

i2c i2c_dut (
   .clk(clk),
   .rstn(rstn), 
   .start(start),
   .address(address),
   .register(register),	
   .sda_in(sda_in),
   .state(state), // For debug
   .data(data),
   .sda(sda), 
   .scl(scl),
   .finished(finished), 
   .ack(ack)
);

always #1 clk = ~clk;
integer i;

initial begin
   $dumpfile("saida.vcd");
   $dumpvars(0, tb);
   $monitor("state=%b, data=%b, sda=%b, scl=%b, finished=%b, ack=%b",
             state, data, sda, scl, finished, ack);
   
   clk = 1'b0;
   rstn = 1'b0;
   start = 1'b0;
   address = 7'h50;
   register = 8'h00;
   sda_in = 1'b1;
   scl_in = 1'b1;
   
   #100
   rstn = 1'b1;
   
   #100
   start = 1'b1;

   for(i = 0; i < 1000; i = i + 1) begin
      #2;
   end

   $finish;

end


endmodule