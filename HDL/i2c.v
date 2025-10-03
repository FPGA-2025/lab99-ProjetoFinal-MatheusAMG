module i2c(
	input wire fastclk, rstn,
	inout wire i2c_scl,
	inout wire i2c_sda,

	input wire i2c_start,               // sinal para iniciar transação I2C
	input wire [6:0]  i2c_addr,         // endereço do slave
	input wire [7:0]  i2c_reg,          // registrador a acessar
	input wire [7:0]  i2c_data,         // dado a enviar
	input wire [15:0] i2c_tx_REDsensor, // dado a enviar do sensor RED
	input wire [15:0] i2c_tx_IRsensor, // dado a enviar do sensor RED
	input wire i2c_rw,                  // 0 = write, 1 = read

	output wire [15:0] i2c_rx_REDsensor, // dado a receber do sensor RED
	output wire [15:0] i2c_rx_IRsensor,  // dado a receber do sensor IR
	output wire opp_finished             // sinal que indica que a transação foi concluída
);

	//--------------------Divisor de Clock---------------
	wire slowclk;

	clock_divider clk_div(
		.cd_clk_in(fastclk),
		.cd_clk_out(slowclk)
	);

	//--------------------Transmissor--------------------
	wire tr_start;
	wire tr_sda, tr_scl;
	wire tr_busy;
	wire tr_finished;

	i2c_transmitter tr(
		.clk(slowclk),
		.rstn(rstn),
		.tx_start(tr_start),
		.tx_address(i2c_addr),
		.tx_rw(i2c_rw),
		.tx_reg(i2c_reg),
		.tx_data(i2c_data),
		.tx_REDdata(i2c_tx_REDsensor),
		.tx_IRdata(i2c_tx_IRsensor),

		.tx_busy(tr_busy),
		.tx_sda(tr_sda),
		.tx_scl(tr_scl),
		.tx_finished(tr_finished)
	);

	//--------------------Receptor--------------------
	reg  rx_start;
	wire rx_sda, rx_scl;
	wire rx_busy;
	wire rx_finished;

	i2c_receiver rx(
		.clk(slowclk),
		.rstn(rstn),
		.rx_start(rx_start),
		.rx_address(i2c_addr),
		.rx_rw(i2c_data),
		.rx_register(i2c_rw),
		.rx_sda_in(rx_sda),
		.rx_scl_in(rx_scl),

		.rx_busy(rx_busy),
		.rx_IRdata(i2c_rx_IRsensor),
		.rx_REDdata(i2c_rx_REDsensor),
		.rx_sda_out(rx_sda),
		.rx_scl_out(rx_scl),
		.rx_finished(rx_finished),
	);

	//--------------------Controlador--------------------
	wire busy;
	assign busy = tx_busy | rx_busy;

	assign i2c_sda = (tr_sda & rx_sda) ? 1'bz : 1'b0;
	assign i2c_scl = (tr_scl & rx_scl) ? 1'bz : 1'b0;

	assign tr_start = (i2c_rw == 0 & i2c_start & ~busy) ? 1'b1 : 1'b0; // Inicia transmissão se for escrita
	assign rx_start = (i2c_rw == 1 & i2c_start & ~busy) ? 1'b1 : 1'b0; // Inicia recepção se for leitura

endmodule