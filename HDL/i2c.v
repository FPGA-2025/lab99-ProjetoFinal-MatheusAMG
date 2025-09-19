module i2c(
	input wire fastclk, rstn,
	inout wire scl,
	inout wire sda,

	input wire i2c_start,           // sinal para iniciar transação I2C
	input wire [6:0] i2c_addr,      // endereço do slave
	input wire [7:0] i2c_reg,       // registrador a acessar
	input wire [7:0] i2c_data,      // dado a enviar
	input wire i2c_rw_tx,           // 0 = write, 1 = read

	output ok
);

	wire tr_sda, tr_scl;
	wire rx_sda, rx_scl;

	//--------------------Divisor de Clock--------------------
	wire slowclk;

	clock_divider clk_div(
		.cd_clk_in(fastclk),
		.cd_clk_out(slowclk)
	);

	//--------------------Transmissor--------------------
	
	i2c_transmitter tr(
		.clk(slowclk),
		.rstn(rstn),
		.start(i2c_start),
		.address(i2c_addr),
		.data(i2c_data),
		.sda_in(i2c_rw_tx),
		.sda(tr_sda),
		.scl(tr_scl),
		.finished(tr_finished),
		.ack(tr_ack)
	);
	
	wire       tr_finished;
	reg        tr_start;
	wire       tr_ack;
	//--------------------Receptor--------------------
	
	//Conecta o i2c transmitter
	i2c_transmitter tr(
		.clk(slowclk),
		.rstn(rstn),
		.start(tr_start),
		.address(tr_address),
		.data(tr_data),
		.sda_in(in_sda),
		.sda(tr_sda),
		.scl(tr_scl),
		.finished(tr_finished),
		.ack(tr_ack)
	);

	reg  [6:0] rx_address; 
	wire [7:0] rx_data;
	reg        rx_start;
	wire       rx_finished;
	wire       rx_ack;

	//Conecta o i2c receiver
	i2c_receiver rx(
		.clk(slowclk),
		.rstn(rstn),
		.start(rx_start),
		.address(rx_address),
		.sda_in(in_sda),
		.data(rx_data),
		.sda(rx_sda),
		.scl(rx_scl),
		.finished(rx_finished),
		.ack(rx_ack)
	);
	
	//--------------------Máquina de Estados--------------------
	reg [2:0] currState, nextState;

	parameter [2:0] STATE_PREPARE_TR = 3'b000, 
					    STATE_SENDING_TR = 3'b001, 
					    STATE_PREPARE_RX = 3'b010, 
					    STATE_SENDING_RX = 3'b011,

	assign sda = (tr_sda & rx_sda) ? 1'bz : 1'b0;
	assign scl = (tr_scl & rx_scl) ? 1'bz : 1'b0;	
	assign in_sda = sda;
	
	
	
	always @(tr_finished, rx_finished, currState)
		case (currState)
			STATE_PREPARE_TR_0: nextState = STATE_SENDING_TR_0;

			STATE_SENDING_TR_0: if (tr_finished) nextState = STATE_PREPARE_RX_0;   
					 else nextState = STATE_SENDING_TR_0;

			STATE_PREPARE_RX_0: nextState = STATE_SENDING_RX_0;
			STATE_SENDING_RX_0: if (rx_finished) nextState = STATE_PREPARE_TR_1;
					 else nextState = STATE_SENDING_RX_0;
			
			STATE_PREPARE_TR_1: nextState = STATE_SENDING_TR_1;
			STATE_SENDING_TR_1: if (tr_finished) nextState = STATE_PREPARE_RX_1;
					 else nextState = STATE_SENDING_TR_1;

			STATE_PREPARE_RX_1: nextState = STATE_SENDING_RX_1;
			STATE_SENDING_RX_1: if (rx_finished) nextState = STATE_PREPARE_TR_0;
					 else nextState = STATE_SENDING_RX_1;
		
			default: nextState = STATE_PREPARE_TR_0;
	endcase
	
	reg reg_ok;
	assign ok = reg_ok;
	
	always @(currState)
		if (i2c_rw_tx) begin // se for transmissão
			case (currState)
				: 
				default: 
			endcase			
		end

		else if (~i2c_rw_tx) begin
			case (currState)
				:
				default: 
			endcase
		end

		case (currState)
			STATE_PREPARE_TR_0:
			begin
				tr_start = 1'b1;
				rx_start = 1'b0;
				tr_address = 7'b0111111; //0x3F
				tr_data = 8'b11110000;			
				reg_ok = (rx_data == 8'b00001111);
			end
			STATE_SENDING_TR_0:
			begin
				tr_start = 1'b0;
				rx_start = 1'b0;
			end
			STATE_PREPARE_RX_0:				
			begin
				tr_start = 1'b0;
				rx_start = 1'b1;
				rx_address = 7'b0111111; //0x3F				
			end
			STATE_SENDING_RX_0:
			begin
				tr_start = 1'b0;
				rx_start = 1'b0;
			end			
			STATE_PREPARE_TR_1:
			begin
				tr_start = 1'b1;
				rx_start = 1'b0;
				tr_address = 7'b0111111; //0x3F
				tr_data = 8'b00001111;			
				reg_ok = (rx_data == 8'b11110000);
			end
			STATE_SENDING_TR_1:
			begin
				tr_start = 1'b0;
				rx_start = 1'b0;
			end
			STATE_PREPARE_RX_1:				
			begin
				tr_start = 1'b0;
				rx_start = 1'b1;
				rx_address = 7'b0111111; //0x3F				
			end
			STATE_SENDING_RX_1:
			begin
				tr_start = 1'b0;
				rx_start = 1'b0;
			end			
			default:
			begin
				tr_start = 1'b0;
				rx_start = 1'b0;
				reg_ok = 0;
			end
			
	endcase
		
	always @(negedge rstn, posedge slowclk)
		if (rstn == 0) currState <= STATE_PREPARE_TR_0;
		else currState <= nextState;

endmodule