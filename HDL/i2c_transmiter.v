// Envio dados para o MAX30100 INIT e LCD INIT e Write via I2C
module i2c_transmiter (
	input wire clk, rstn,
	input wire 		   tx_start,
	input wire [6:0]  tx_address,
	input wire        tx_rw,
	input wire [7:0]  tx_reg,
	input wire [7:0]  tx_data,
	input reg  [15:0] tx_REDdata,
	input reg  [15:0] tx_IRdata,
	
	output reg tx_busy,
	output reg tx_sda,
	output reg tx_scl,
	output reg tx_finished,
);
	
	reg [7:0] reg_Address;

	reg [2:0] currState, nextState;
	parameter [3:0] STATE_IDLE              = 4'b0000, 
					    STATE_START             = 4'b0001, 
					    STATE_PREPARE_ADDRESS   = 4'b0010,
					    STATE_SENDING_ADDRESS   = 4'b0011, 
					    STATE_WAIT              = 4'b0100,
						 STATE_PREPARE_REGISTER  = 4'b0101, 
					    STATE_SENDING_REGISTER  = 4'b0110,
					    STATE_PREPARE_DATA      = 4'b0111, 
					    STATE_SENDING_DATA      = 4'b1000,
					    STATE_STOP              = 4'b1001;
					
	reg [7:0] sb_reg_byte, sb_reg_byte_m1;
	reg sb_send_byte;
	reg [3:0] sb_counter;
	reg [1:0] sb_bit_counter;
	reg sb_byte_finished;
	reg sb_sda, sb_scl;

	/* Posso criar um if aqui? A maquina de estados seguiria dois caminhos. Se for transmitir
	para o MAX seria uma e se for para o LCD seria outra.
	*/

	always @(start, currState, sb_byte_finished) 
		if (max_init) begin
			case (currState)
				STATE_IDLE: begin
					if (start) nextState = STATE_START;
					else nextState = STATE_IDLE;
				end
				STATE_START: begin
					nextState = STATE_PREPARE_ADDRESS;
				end
				STATE_PREPARE_ADDRESS: begin
					nextState = STATE_SENDING_ADDRESS;
				end
				STATE_SENDING_ADDRESS: begin
					if (sb_byte_finished) nextState = STATE_WAIT0;   //SE TERMINOU, AVANÇA
					else nextState = STATE_SENDING_ADDRESS;
				end
				STATE_WAIT0: begin 
					nextState = STATE_PREPARE_REGISTER;
				end
				STATE_PREPARE_REGISTER: begin
					nextState = STATE_SENDING_REGISTER;
				end
				STATE_SENDING_REGISTER: begin
					if (sb_byte_finished) nextState = STATE_WAIT1;  //DECIDE SE VOLTA PARA O PREPARE BYTE OU SE AVAN�A
					else nextState = STATE_SENDING_REGISTER;
				end
				STATE_WAIT1: begin 
					nextState = STATE_PREPARE_DATA;
				end
				STATE_PREPARE_DATA: begin
					nextState = STATE_SENDING_DATA;
				end
				STATE_SENDING_DATA: begin
					if (sb_byte_finished) nextState = STATE_STOP;  //DECIDE SE VOLTA PARA O PREPARE BYTE OU SE AVAN�A
					else nextState = STATE_SENDING_DATA;
				end
				STATE_STOP: nextState = STATE_IDLE;

				default: nextState = STATE_IDLE;
			endcase
		end

//--------------------------TODO LCDINIT----------------------------------
		else if (lcd_init) begin
			case (currState)
				STATE_IDLE: begin
					if (start) nextState = STATE_START;
					else nextState = STATE_IDLE;
				end
				STATE_START: begin
					nextState = STATE_PREPARE_ADDRESS;
				end
				STATE_PREPARE_ADDRESS: begin
					nextState = STATE_SENDING_ADDRESS;
				end
				STATE_SENDING_ADDRESS: begin
					if (sb_byte_finished) nextState = STATE_WAIT0;   //SE TERMINOU, AVANÇA
					else nextState = STATE_SENDING_ADDRESS;
				end
				STATE_WAIT0: begin 
					nextState = STATE_PREPARE_REGISTER;
				end
				STATE_PREPARE_REGISTER: begin
					nextState = STATE_SENDING_REGISTER;
				end
				STATE_SENDING_REGISTER: begin
					if (sb_byte_finished) nextState = STATE_WAIT1;  //DECIDE SE VOLTA PARA O PREPARE BYTE OU SE AVAN�A
					else nextState = STATE_SENDING_REGISTER;
				end
				STATE_WAIT1: begin 
					nextState = STATE_PREPARE_DATA;
				end
				STATE_PREPARE_DATA: begin
					nextState = STATE_SENDING_DATA;
				end
				STATE_SENDING_DATA: begin
					if (sb_byte_finished) nextState = STATE_STOP;  //DECIDE SE VOLTA PARA O PREPARE BYTE OU SE AVAN�A
					else nextState = STATE_SENDING_DATA;
				end
				STATE_STOP: nextState = STATE_IDLE;

				default: nextState = STATE_IDLE;
			endcase
		end
//--------------------------TODO LCDWRITE----------------------------------
		else if (lcd_write) begin
			case (currState)
				STATE_IDLE: begin
					if (start) nextState = STATE_START;
					else nextState = STATE_IDLE;
				end
				STATE_START: begin
					nextState = STATE_PREPARE_ADDRESS;
				end
				STATE_PREPARE_ADDRESS: begin
					nextState = STATE_SENDING_ADDRESS;
				end
				STATE_SENDING_ADDRESS: begin
					if (sb_byte_finished) nextState = STATE_WAIT0;   //SE TERMINOU, AVANÇA
					else nextState = STATE_SENDING_ADDRESS;
				end
				STATE_WAIT0: begin 
					nextState = STATE_PREPARE_REGISTER;
				end
				STATE_PREPARE_REGISTER: begin
					nextState = STATE_SENDING_REGISTER;
				end
				STATE_SENDING_REGISTER: begin
					if (sb_byte_finished) nextState = STATE_WAIT1;  //DECIDE SE VOLTA PARA O PREPARE BYTE OU SE AVAN�A
					else nextState = STATE_SENDING_REGISTER;
				end
				STATE_WAIT1: begin 
					nextState = STATE_PREPARE_DATA;
				end
				STATE_PREPARE_DATA: begin
					nextState = STATE_SENDING_DATA;
				end
				STATE_SENDING_DATA: begin
					if (sb_byte_finished) nextState = STATE_STOP;  //DECIDE SE VOLTA PARA O PREPARE BYTE OU SE AVAN�A
					else nextState = STATE_SENDING_DATA;
				end
				STATE_STOP: nextState = STATE_IDLE;

				default: nextState = STATE_IDLE;
			endcase
		end


	always @(currState)
		case (currState)
			STATE_IDLE: 
			begin
				sda = 1'b1;
				scl = 1'b1;
				sb_send_byte = 1'b0;
				sb_receive_byte = 1'b0;
				finished = 1'b0;
			end
			STATE_START: 
			begin
				sda = 1'b0;
				scl = 1'b1;
				sb_send_byte = 1'b0;
				reg_Address = {address, rx_rw}; //address + 0 = WRITE.
				finished = 1'b0;
			end
			STATE_PREPARE_ADDRESS:
			//NESSE ESTADO EU TENHO QUE PREPARAR O BYTE QUE EU VOU MANDAR
			begin
				sda = 1'b0;
				scl = 1'b0;  
				sb_send_byte = 1'b1;
				finished = 1'b0;
				sb_reg_byte_m1 = reg_Address;									
			end
			STATE_SENDING_ADDRESS: 
			//NESSE ESTADO QUEM MANDA EH A OUTRA MAQUINA
			begin
				sda = sb_sda;
				scl = sb_scl;
				sb_send_byte = 1'b1;
				finished = 1'b0;
			end
			STATE_WAIT: 
			begin
				sda = 1'b0;
				scl = 1'b0;
				sb_send_byte = 1'b0;
				finished = 1'b0;
			end
			STATE_PREPARE_REGISTER: 
			begin
				sda = 1'b0;
				scl = 1'b0;  
				finished = 1'b0;
				sb_reg_byte_m1 = rx_reg;	
			end
			STATE_SENDING_REGISTER: 
			begin
				sda = sb_sda;
				scl = sb_scl;
				sb_send_byte = 1'b1;
				finished = 1'b0;
			end
			STATE_WAIT1: 
			begin
				sda = 1'b0;
				scl = 1'b0;
				sb_send_byte = 1'b0;
				sb_receive_byte = 1'b0;
				finished = 1'b0;
			end
			STATE_PREPARE_DATA: 
			begin
				sda = 1'b0;
				scl = 1'b0;  //NESSE ESTADO EU TENHO QUE PREPARAR O BYTE QUE EU VOU RECEBER
				sb_send_byte = 1'b0;
				finished = 1'b0;				
			end
			STATE_SENDING_DATA: 
			begin
				//NESSE ESTADO QUEM MANDA � A OUTRA M�QUINA
				sda = sb_sda;
				scl = sb_scl;
				sb_send_byte = 1'b1;
				finished = 1'b0;
			end
			
			STATE_STOP: 
			begin
				sda = 1'b0; 
				scl = 1'b1;
				sb_send_byte = 1'b0;
				finished = 1'b1;
			end
			
			default: 
			begin
				sda = 1'b1;
				scl = 1'b1;
				sb_send_byte = 1'b0;
				finished = 1'b0;
			end
	endcase
	
	
	always @(negedge rstn, posedge clk)
		if (rstn == 0) currState <= STATE_IDLE;
		else currState <= nextState;

//Pulsos de transmissão do byte
	always @(posedge clk)
	begin
	if (sb_send_byte)
		begin
			if (sb_counter == 0)
				begin
					sb_reg_byte <= sb_reg_byte_m1;
					sb_counter <= sb_counter + 1;	
					sb_scl <= 0;
					sb_sda <= 0;
				end
			else if (sb_counter == 10) // 9 pulsos sendo 8 para os bits e 1 para o ACK
				begin
					sb_sda <= 0;
					sb_scl <= 0;
					sb_byte_finished <= 1;
				end
			else
				begin
					if (sb_bit_counter == 0)
						begin
							sb_scl <= 0;
							sb_sda <= sb_reg_byte[7];				
				
							sb_bit_counter <= 1;
						end
					else if (sb_bit_counter == 1)
						begin
							sb_scl <= 1;
							sb_sda <= sb_reg_byte[7];				
				
							sb_bit_counter <= 2;
							if (sb_counter == 9)
								ack <= !sda_in;								
						end
					else
						begin
							sb_scl <= 0;
							sb_sda <= sb_reg_byte[7];				
				
							//Rotaciona o sb_reg_byte
							sb_reg_byte[7] <= sb_reg_byte[6];
							sb_reg_byte[6] <= sb_reg_byte[5];
							sb_reg_byte[5] <= sb_reg_byte[4];
							sb_reg_byte[4] <= sb_reg_byte[3];
							sb_reg_byte[3] <= sb_reg_byte[2];
							sb_reg_byte[2] <= sb_reg_byte[1];
							sb_reg_byte[1] <= sb_reg_byte[0];
				
							sb_bit_counter <= 0;				
							sb_counter <= sb_counter + 1;				
					
						end
				end
		end
	else
		begin
			sb_byte_finished <= 0;
			sb_sda <= 0;
			sb_scl <= 0;
			sb_counter <= 0;
			sb_bit_counter <= 0;
		end
	end

endmodule