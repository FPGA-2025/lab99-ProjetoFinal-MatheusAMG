module i2c_transmitter (
	input wire clk, rstn, start ,
	input wire [6:0] address, 
	input wire [7:0] data,
	input wire sda_in,
	input wire scl_in,
	output reg sda, 
	output reg scl,
	output reg finished, 
	output reg ack
);
	
	reg [7:0] reg_Address, reg_Data;
	reg [2:0] currState, nextState;
	parameter [2:0] STATE_IDLE           = 3'b000, 
					STATE_START           = 3'b001, 
					STATE_PREPARE_ADDRESS = 3'b010, 
					STATE_SENDING_ADDRESS = 3'b011, 
					STATE_WAIT            = 3'b100,
					STATE_PREPARE_DATA    = 3'b101, 
					STATE_SENDING_DATA    = 3'b110,
					STATE_STOP            = 3'b111;
					
	reg [8:0] sb_reg_byte, sb_reg_byte_m1;
	reg sb_send_byte;
	reg [3:0] sb_counter;
	reg [1:0] sb_bit_counter;
	reg sb_byte_finished;
	reg sb_sda, sb_scl;
	
	
	always @(start, currState, sb_byte_finished)
		case (currState)
			STATE_IDLE: if (start) nextState = STATE_START;
						else nextState = STATE_IDLE;
			STATE_START: nextState = STATE_PREPARE_ADDRESS;
			STATE_PREPARE_ADDRESS: nextState = STATE_SENDING_ADDRESS;					 
			STATE_SENDING_ADDRESS: if (sb_byte_finished) nextState = STATE_WAIT;            //SE TERMINOU, AVANÇA
								else nextState = STATE_SENDING_ADDRESS;
			STATE_WAIT: nextState = STATE_PREPARE_DATA;							
			STATE_PREPARE_DATA: nextState = STATE_SENDING_DATA;
			STATE_SENDING_DATA: if (sb_byte_finished) nextState = STATE_STOP;  //DECIDE SE VOLTA PARA O PREPARE BYTE OU SE AVANÇA
						  else nextState = STATE_SENDING_DATA;
			STATE_STOP: nextState = STATE_IDLE;
			default: nextState = STATE_IDLE;
	endcase
	
	
	//Esse always tem que determinar:
	// sda, scl
	// send_byte (comando da máquina que manda o byte)
	// reg_byte (byte que a máquina que manda o byte vai mandar)
	//always @(currState, sb_sda, sb_scl, address, data)
	always @(currState)
		case (currState)
			STATE_IDLE: 
			begin
				sda = 1'b1;
				scl = 1'b1;
				sb_send_byte = 1'b0;
				finished = 1'b0;
			end
			STATE_START: 
			begin
				sda = 1'b0;
				scl = 1'b1;
				sb_send_byte = 1'b0;
				reg_Address = {address, 1'b0};
				reg_Data = data;
				finished = 1'b0;
			end
			STATE_PREPARE_ADDRESS: 
			begin
				sda = 1'b0;
				scl = 1'b0;  //NESSE ESTADO EU TENHO QUE PREPARAR O BYTE QUE EU VOU MANDAR
				sb_send_byte = 1'b1;
				finished = 1'b0;
				sb_reg_byte_m1 = {reg_Address , 1'b1};									
			end
			STATE_SENDING_ADDRESS: 
			begin
				//NESSE ESTADO QUEM MANDA É A OUTRA MÁQUINA
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
			STATE_PREPARE_DATA: 
			begin
				sda = 1'b0;
				scl = 1'b0;  //NESSE ESTADO EU TENHO QUE PREPARAR O BYTE QUE EU VOU MANDAR
				sb_send_byte = 1'b1;
				finished = 1'b0;
				sb_reg_byte_m1 = {reg_Data, 1'b1};
			end
			STATE_SENDING_DATA: 
			begin
				//NESSE ESTADO QUEM MANDA É A OUTRA MÁQUINA
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
		
		
	//SENDING_BYTE MACHINE
	//Uso: sb_reg_byte tem que estar escrito antes que sb_send_byte seja 1. 
	//     sb_reg_byte não pode ser modificado enquanto sb_send_byte for 1.
	//     sb_send_byte tem que ir para 0 no clk seguinte a sb_byte_finished = 1.
	
	
	
	
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
			else if (sb_counter == 10)
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
							sb_sda <= sb_reg_byte[8];				
				
							sb_bit_counter <= 1;
						end
					else if (sb_bit_counter == 1)
						begin
							sb_scl <= 1;
							sb_sda <= sb_reg_byte[8];				
				
							sb_bit_counter <= 2;
							if (sb_counter == 9)
								ack <= !sda_in;								
						end
					else
						begin
							sb_scl <= 0;
							sb_sda <= sb_reg_byte[8];				
				
							//Rotaciona o sb_reg_byte
							sb_reg_byte[8] <= sb_reg_byte[7];
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
			//sb_reg_byte <= 9'b110011001; //PARA DEBUG. Na hora de rodar o reg_byte é escrito pela outra máquina, antes do send_byte ativar.
		end
	end

endmodule