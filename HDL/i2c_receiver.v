// Recebo dados do MAX30100 via I2C
module i2c_receiver (
	input wire       clk, rstn
	input wire       rx_start,
	input wire [6:0] rx_address,   // endereço do slave
	input wire       rx_rw,        // 0 = write, 1 = read
	input wire [7:0] rx_register,	 // registrador do max30100 a ser acessado
	input reg        rx_sda_in, 
	input reg        rx_scl_in,

	output reg        rx_busy,     // dado a receber
	output reg [15:0] rx_IRdata,   // dado a receber
	output reg [15:0] rx_REDdata,  // dado a receber
	output reg        rx_sda_out, 
	output reg        rx_scl_out,
	output reg        rx_finished, 
	// output reg        rx_ack       // Nao escrevo direto no sda?
);


	reg [7:0] reg_Address, reg_Data, reg_Register;
	reg [4:0] currState, nextState;

	parameter [4:0] STATE_IDLE           	   = 5'd1, 
						 STATE_START0           	= 5'd2, 
					
						 STATE_PREPARE_ADDRESS0 	= 5'd3, 
						 STATE_SENDING_ADDRESS0 	= 5'd4,
						 STATE_WAIT0            	= 5'd5,
					
						 STATE_PREPARE_REG 		   = 5'd6, 
						 STATE_SENDING_REG 		   = 5'd7,
						 STATE_WAIT1            	= 5'd8,
					
						 STATE_STOP0            	= 5'd9,
						 STATE_WAIT2				   = 5'd10,
						 STATE_START1              = 5'd11,
					
						 STATE_PREPARE_ADDRESS1 	= 5'd12, 
						 STATE_SENDING_ADDRESS1 	= 5'd13, 					
						 STATE_WAIT3            	= 5'd14,
					
						 STATE_PREPARE_DATA    	   = 5'd15, 
						 STATE_RECEIVING_DATA     	= 5'd16,
						 STATE_WAIT4				   = 5'd17,
				
						 STATE_STOP1            	= 5'd18;
					
	reg [8:0] sb_reg_byte, sb_reg_byte_m1;
	reg sb_send_byte, sb_receive_byte;
	reg [3:0] sb_counter;
	reg [1:0] sb_bit_counter;
	reg sb_byte_finished;
	reg sb_sda, sb_scl;
	reg sb_bit;
		
	always @(start, currState, sb_byte_finished) 
		case (currState)
			STATE_IDLE: if (start) nextState = STATE_START0;
						   else nextState = STATE_IDLE;
							
			STATE_START0: nextState = STATE_PREPARE_ADDRESS0;
			
			STATE_PREPARE_ADDRESS0: nextState = STATE_SENDING_ADDRESS0;
			
			STATE_SENDING_ADDRESS0: if (sb_byte_finished) nextState = STATE_WAIT0;            //SE TERMINOU, AVAN�A
											else nextState = STATE_SENDING_ADDRESS0;
						
			STATE_WAIT0: nextState = STATE_PREPARE_REG;
			
			STATE_PREPARE_REG: nextState = STATE_SENDING_REG;
			
			STATE_SENDING_REG: if(sb_byte_finished) nextState = STATE_WAIT1;
									 else nextState = STATE_SENDING_REG;
			
			STATE_WAIT1: nextState = STATE_STOP0;
			
			STATE_STOP0: nextState = STATE_WAIT2;
			STATE_WAIT2: nextState = STATE_START1;
			STATE_START1: nextState = STATE_PREPARE_ADDRESS1;
			
			STATE_PREPARE_ADDRESS1: nextState = STATE_SENDING_ADDRESS1;
			
			STATE_SENDING_ADDRESS1: if(sb_byte_finished) nextState = STATE_WAIT3;
											else nextState = STATE_SENDING_ADDRESS1;
			
			STATE_WAIT3: nextState = STATE_PREPARE_DATA;
			
			STATE_PREPARE_DATA: nextState = STATE_RECEIVING_DATA;
			
			STATE_RECEIVING_DATA: if (sb_byte_finished) nextState = STATE_WAIT4;  //DECIDE SE VOLTA PARA O PREPARE BYTE OU SE AVAN�A
						  				 else nextState = STATE_RECEIVING_DATA;
			
			STATE_WAIT4: nextState = STATE_STOP1;
			
			STATE_STOP1: nextState = STATE_IDLE;
			
			default: nextState = STATE_IDLE;
	endcase
	
	
	//Esse always tem que determinar:
	// sda, scl
	// send_byte (comando da m�quina que manda o byte)
	// reg_byte (byte que a m�quina que manda o byte vai mandar)
	//always @(currState, sb_sda, sb_scl, address, data)
	
	/*
		SLAVE ADDR+W -> SLAVE ACK -> WR SLAVE REGISTER ADDR -> SLAVE ACK -> STOP -> START -> SLAVE ADDR+R -> SLAVE ACK -> DATA -> MASTER NACK -> STOP
	*/
	
	always @(currState, sb_sda, sb_scl, address, data, register)
		case (currState)
			
			STATE_IDLE: 
			begin
				sda = 1'b1;
				scl = 1'b1;
				sb_send_byte = 1'b0;
				sb_receive_byte = 1'b0;
				finished = 1'b0;
				state = currState; // for debug
			end
			
			STATE_START0: 
			begin
				sda = 1'b0;
				scl = 1'b1;
				sb_send_byte = 1'b0;
				sb_receive_byte = 1'b0;
				reg_Address = {address, WRITE}; //address + 0 = send.
				reg_Register = register;
				finished = 1'b0;
				state = currState; // for debug
			end
			
/*====================================================================================*/

			STATE_PREPARE_ADDRESS0: 
			begin
				sda = 1'b0;
				scl = 1'b0;  
				sb_send_byte = 1'b1;
				sb_receive_byte = 1'b0;
				finished = 1'b0;
				sb_reg_byte_m1 = {reg_Address , 1'b1};
				state = currState; // for debug
			end
			
			STATE_SENDING_ADDRESS0: 
			begin
				//NESSE ESTADO QUEM MANDA � A OUTRA M�QUINA
				sda = sb_sda;
				scl = sb_scl;
				sb_send_byte = 1'b1;
				sb_receive_byte = 1'b0;
				finished = 1'b0;
				state = currState; // for debug
			end	
			
			STATE_WAIT0: 
			begin
				sda = 1'b0;
				scl = 1'b0;
				sb_send_byte = 1'b0;
				sb_receive_byte = 1'b0;
				finished = 1'b0;
				state = currState; // for debug
			end
			
/*====================================================================================*/

			STATE_PREPARE_REG:
			begin
				sda = 1'b0;
				scl = 1'b0;  
				sb_send_byte = 1'b1;
				sb_receive_byte = 1'b0;
				finished = 1'b0;
				sb_reg_byte_m1 = {reg_Register , 1'b1};
				state = currState; // for debug
			end
			
			STATE_SENDING_REG:
			begin
				//NESSE ESTADO QUEM MANDA � A OUTRA M�QUINA
				sda = sb_sda;
				scl = sb_scl;
				sb_send_byte = 1'b1;
				sb_receive_byte = 1'b0;
				finished = 1'b0;
				state = currState; // for debug
			end	
			
			STATE_WAIT1:
			begin
				sda = 1'b0;
				scl = 1'b0;
				sb_send_byte = 1'b0;
				sb_receive_byte = 1'b0;
				finished = 1'b0;
				state = currState; // for debug
			end
			
/*====================================================================================*/

			STATE_STOP0:
			begin
				sda = 1'b0; 
				scl = 1'b1;
				sb_send_byte = 1'b0;
				sb_receive_byte = 1'b0;
				data = reg_Data;
				finished = 1'b0;
				state = currState; // for debug
			end
			
			STATE_WAIT2:
			begin
				sda = 1'b1;
				scl = 1'b1;
				sb_send_byte = 1'b0;
				sb_receive_byte = 1'b0;
				finished = 1'b0;
				state = currState; // for debug
			end
			
			STATE_START1:
			begin
				sda = 1'b0;
				scl = 1'b1;
				sb_send_byte = 1'b0;
				sb_receive_byte = 1'b0;
				reg_Address = {address, READ}; //address + 1 = read.
				reg_Register = 8'b0;
				finished = 1'b0;
				state = currState; // for debug
			end
			
/*====================================================================================*/
			
			STATE_PREPARE_ADDRESS1:
			begin
				sda = 1'b0;
				scl = 1'b0;  
				sb_send_byte = 1'b1;
				sb_receive_byte = 1'b0;
				finished = 1'b0;
				sb_reg_byte_m1 = {reg_Address , 1'b1};									
				state = currState; // for debug
			end
			
			STATE_SENDING_ADDRESS1:
			begin
				//NESSE ESTADO QUEM MANDA � A OUTRA M�QUINA
				sda = sb_sda;
				scl = sb_scl;
				sb_send_byte = 1'b1;
				sb_receive_byte = 1'b0;
				finished = 1'b0;
				state = currState; // for debug
			end	
			
			STATE_WAIT3:
			begin
				sda = 1'b0;
				scl = 1'b0;
				sb_send_byte = 1'b0;
				sb_receive_byte = 1'b0;
				finished = 1'b0;
				state = currState; // for debug
			end

/*====================================================================================*/

			STATE_PREPARE_DATA: 
			begin
				sda = 1'b0;
				scl = 1'b0; 
				sb_send_byte = 1'b0;
				sb_receive_byte = 1'b1;
				finished = 1'b0;
				state = currState; // for debug
			end
			STATE_RECEIVING_DATA: 
			begin
				//NESSE ESTADO QUEM MANDA � A OUTRA M�QUINA
				sda = sb_sda;
				scl = sb_scl;
				sb_send_byte = 1'b0;
				sb_receive_byte = 1'b1;
				finished = 1'b0;
				state = currState; // for debug
			end
			
			STATE_WAIT4:
			begin
				sda = 1'b0;
				scl = 1'b0;
				sb_send_byte = 1'b0;
				sb_receive_byte = 1'b0;
				finished = 1'b0;
				state = currState; // for debug
			end
			
			STATE_STOP1: 
			begin
				sda = 1'b0; 
				scl = 1'b1;
				sb_send_byte = 1'b0;
				sb_receive_byte = 1'b0;
				data = reg_Data;
				finished = 1'b1;
				state = currState; // for debug
			end
			
			default: 
			begin
				sda = 1'b1;
				scl = 1'b1;
				sb_send_byte = 1'b0;
				sb_receive_byte = 1'b0;
				finished = 1'b0;
				state = currState; // for debug
			end
	endcase
	
	
	always @(negedge rstn, posedge clk)
		if (rstn == 0) currState <= STATE_IDLE;
		else currState <= nextState;
		
		
	//SENDING_BYTE MACHINE
	//Uso: sb_reg_byte tem que estar escrito antes que sb_send_byte seja 1. 
	//     sb_reg_byte n�o pode ser modificado enquanto sb_send_byte for 1.
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
	else if (sb_receive_byte)
		begin
			if (sb_counter == 0)
				begin
					reg_Data <= 8'b00000000;
					sb_counter <= sb_counter + 1;	
					sb_scl <= 0;
					sb_sda <= 0;
				end
			else if (sb_counter == 9)
				begin
					if (sb_bit_counter == 0)
						begin
							sb_scl <= 0;							
							sb_sda <= 0;
				
							sb_bit_counter <= 1;
						end
					else if (sb_bit_counter == 1)
						begin
							sb_scl <= 1;
							sb_sda <= 1; // NO ACK
				
							sb_bit_counter <= 2;							
						end
					else
						begin
							sb_scl <= 0;
							sb_sda <= 0;
				
							sb_bit_counter <= 0;				
							sb_counter <= sb_counter + 1;
							
						end
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
							sb_sda <= 1;
											
							sb_bit_counter <= 1;
						end
					else if (sb_bit_counter == 1)
						begin
							sb_scl <= 1;
							sb_sda <= 1;
							
							sb_bit <= sda_in;
				
							sb_bit_counter <= 2;							
						end
					else
						begin
							sb_scl <= 0;
							sb_sda <= 1;
				
							//Rotaciona o reg_data
							reg_Data[7] <= reg_Data[6];
							reg_Data[6] <= reg_Data[5];
							reg_Data[5] <= reg_Data[4];
							reg_Data[4] <= reg_Data[3];
							reg_Data[3] <= reg_Data[2];
							reg_Data[2] <= reg_Data[1];
							reg_Data[1] <= reg_Data[0];
							reg_Data[0] <= sb_bit;      //Escreve o novo bit no menos significativo
				
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