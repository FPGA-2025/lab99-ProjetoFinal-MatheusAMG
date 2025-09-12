module top (
	input wire fastclk, rstn ,
	output wire [1:0] state ,
	inout wire scl,
	inout wire sda,
	output sl_clk,
	output ack
);
	wire slowclk;
	assign sl_clk = slowclk;
	reg [1:0] currState, nextState;
	parameter [1:0] STATE_PREPARE_0 = 2'b00, 
					STATE_SENDING_0 = 2'b01, 
					STATE_PREPARE_1 = 2'b10, 
					STATE_SENDING_1 = 2'b11;
					
	//Divide o clock
	clock_divider clk_div(
		.cd_clk_in(fastclk),
		.cd_clk_out(slowclk)
	);
	
	wire finished;
	reg start;
	reg [6:0] address; 
	reg [7:0] data;
	
	wire tr_sda, tr_scl;
	wire in_sda, in_scl;
	
	//Conecta o i2c transmitter
	i2c_transmitter tr(
		.clk(slowclk),
		.rstn(rstn),
		.start(start),
		.address(address),
		.data(data),
		.sda_in(in_sda),
		.scl_in(in_scl),
		.sda(tr_sda),
		.scl(tr_scl),
		.finished(finished),
		.ack(ack)
	);

	
	
	assign sda = tr_sda ? 1'bz : 1'b0;
	assign scl = tr_scl ? 1'bz : 1'b0;
	assign in_sda = sda;
	assign in_scl = scl;
	

	always @(finished, currState)
		case (currState)
			STATE_PREPARE_0: nextState = STATE_SENDING_0;					 
			STATE_SENDING_0: if (finished) nextState = STATE_PREPARE_1;
					 else nextState = STATE_SENDING_0;
			STATE_PREPARE_1: nextState = STATE_SENDING_1;
			STATE_SENDING_1: if (finished) nextState = STATE_PREPARE_0;
					 else nextState = STATE_SENDING_1;
			default: nextState = STATE_PREPARE_0;
	endcase
	
	always @(currState)
		case (currState)
			STATE_PREPARE_0:
			begin
				start = 1'b1;
				address = 7'b0111111; //0x3F
				data = 8'b00000000;				
			end
			STATE_SENDING_0:
			begin
				start = 1'b0;
			end
			STATE_PREPARE_1:				
			begin
				start = 1'b1;
				address = 7'b0111111; //0x3F
				data = 8'b11111111;				
			end
			STATE_SENDING_1:				
			begin
				start = 1'b0;
			end
			default:
			begin
					start = 1'b0;
			end
			
	endcase
		
	assign state = currState;
	
	always @(negedge rstn, posedge slowclk)
		if (rstn == 0) currState <= STATE_PREPARE_0;
		else currState <= nextState;

endmodule