module i2c(
	input wire fastclk, rstn,
	inout wire scl,
	inout wire sda,

	input wire i2c_start,           // sinal para iniciar transação I2C
	input wire [6:0] i2c_addr,      // endereço do slave
	input wire [7:0] i2c_reg,       // registrador a acessar
	input wire [7:0] i2c_data,      // dado a enviar
	input wire i2c_rw,              // 0 = write, 1 = read

	output wire ok                  // sinal que indica que a transação foi concluída
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
		.start(tr_start),
		.address(i2c_addr),
		.data(i2c_data),
		.sda_in(i2c_rw),
		.sda(tr_sda),
		.scl(tr_scl),
		.finished(tr_finished),
		.ack(tr_ack)
	);
	
	reg  tr_start;
	wire tr_finished;
	wire tr_ack;
	//--------------------Receptor--------------------
	
	//Conecta o i2c receiver
	i2c_receiver rx(
		.clk(slowclk),
		.rstn(rstn),
		.start(rx_start),
		.address(i2c_addr),
		.data(i2c_data),
		.sda_in(i2c_rw),
		.sda(rx_sda),
		.scl(rx_scl),
		.finished(rx_finished),
		.ack(rx_ack)
	);

	reg  rx_start;
	wire rx_finished;
	wire rx_ack;

	//--------------------Máquina de Estados--------------------
	reg [2:0] currState, nextState;

	parameter [2:0] STATE_IDLE			= 3'b000,
						 STATE_PREPARE_TR = 3'b001, 
					    STATE_SENDING_TR = 3'b010, 
					    STATE_PREPARE_RX = 3'b011, 
					    STATE_SENDING_RX = 3'b100;

	assign sda = (tr_sda & rx_sda) ? 1'bz : 1'b0;
	assign scl = (tr_scl & rx_scl) ? 1'bz : 1'b0;

	
	always @(i2c_start, tr_finished, rx_finished, currState)
		if (i2c_start & ~i2c_rw_tx) begin // se receber uma sinal para escrever
			case (currState)
				STATE_IDLE: begin
					nextState = STATE_PREPARE_TR;	
				end
				STATE_SENDING_TR: begin
					if (tr_finished) nextState = STATE_IDLE;   
						else nextState = STATE_SENDING_TR;
				end
				default: nextState = STATE_IDLE;
			endcase
		end

		else if (i2c_start & i2c_rw_tx) begin // se receber uma sinal para ler
			case (currState)
				STATE_PREPARE_RX: nextState = STATE_SENDING_RX;
				STATE_SENDING_RX: if (rx_finished) nextState = STATE_PREPARE_RX;   
						else nextState = STATE_SENDING_RX;
				default: nextState = STATE_IDLE;
			endcase

		else
			nextState = STATE_IDLE;
		end
	
	
	always @(currState)
		case (currState)
			STATE_IDLE: begin
				tr_start = 1'b0;
				rx_start = 1'b0;
			end
			STATE_PREPARE_TR:
			begin
				tr_start = 1'b1;
				rx_start = 1'b0;
			end
			STATE_SENDING_TR:
			begin
				tr_start = 1'b0;
				rx_start = 1'b0;
			end
			STATE_PREPARE_RX: begin
				tr_start = 1'b0;
				rx_start = 1'b1;	
			end
			STATE_SENDING_RX: begin
				tr_start = 1'b0;
				rx_start = 1'b0;
			end			
			default:	begin
				tr_start = 1'b0;
				rx_start = 1'b0;
			end
			
	endcase
		
	always @(negedge rstn, posedge slowclk)
		if (rstn == 0) currState <= STATE_IDLE;
		else currState <= nextState;

endmodule