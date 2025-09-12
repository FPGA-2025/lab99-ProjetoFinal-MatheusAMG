module clock_divider (
	input wire cd_clk_in ,
	output reg cd_clk_out
);

reg [31:0] clk_divider_counter ;

initial begin
	clk_divider_counter = 32'h0;
	cd_clk_out = 1'b0;
end

always @( posedge cd_clk_in ) begin
	if ( clk_divider_counter < 32'd1250000 ) begin
		clk_divider_counter <= clk_divider_counter + 1'b1;
	end else begin
		clk_divider_counter <= 32'h0;
		cd_clk_out <= ~cd_clk_out;
	end
end

endmodule
