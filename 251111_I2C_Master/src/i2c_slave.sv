// I2C Slave Module
// Author: Hoseung Yoon
// Description: I2C Slave module that responds to master read/write requests.
//              Supports basic ACK/NACK and multi-byte transfers.
                
`timescale 1ns / 1ps

module i2c_slave #(
    parameter SLAVE_ADDR = 7'b101_0000 // example: 0x50
) (
    // Global Signals
    input logic clk,
    input logic rst,

	input logic [7:0] data_out,		// Data to send to master
	output logic [7:0] data_in,		// Data received from master
	input logic send_valid,			// Indicates data_tobe_master is valid

    // I2C Signals
	inout tri sda,
	inout tri scl
);

	logic [7:0] data_tobe_master;
	assign data_tobe_master = data_out;
    // State enumeration
    typedef enum logic [2:0] {
        READ_ADDR,
        SEND_ACK,
        READ_DATA,
        WRITE_DATA,
        SEND_ACK2
    } state_t;
	
	state_t state = READ_ADDR;

    // Internal signals
	reg [7:0] addr;
	reg [2:0] bit_count;
	reg sda_out = 0;
	reg start = 0;
	reg sda_out_en = 0;
	
	assign sda = sda_out_en ? sda_out : 1'bz;


    // Slave Start: negedge SDA while SCL is high
	always_ff @(negedge sda) begin : SLAVE_START
		if ((start == 0) && (scl == 1)) begin
			start <= 1;	
			bit_count <= 7;
		end
	end
	
    // Slave Stop: posedge SDA while SCL is high
	always_ff @(posedge sda) begin : SLAVE_STOP
		if ((start == 1) && (scl == 1)) begin
			state <= READ_ADDR;
			start <= 0;
			sda_out_en <= 0;
		end
	end


    // Master drives SDA on posedge SCL
    // Slave should drive SDA on negedge SCL (I2C standard)
	always_ff @(negedge scl) begin : SLAVE_SDA_DRIVE
		case(state)
			READ_ADDR: sda_out_en <= 0;			
			
			SEND_ACK: begin
				sda_out_en <= 1;	
				sda_out <= 0;   // Send ACK to master
			end
			
			READ_DATA: sda_out_en <= 0;
			
			WRITE_DATA: begin
			    sda_out_en <= 1;  // Drive data to master
				// sda_out <= data_tobe_master[bit_count];
				sda_out <= (send_valid) ? data_tobe_master[bit_count] : 1'bx;
			end
			
			SEND_ACK2: begin
				sda_out_en <= 1;
				sda_out <= 0;
			end
		endcase
	end

    // MAIN FSM
    // Prepare data on SCL rising edge -> to drive on next falling edge
    // Or sample data from master on SCL rising edge
	always_ff @(posedge scl, posedge rst) begin : SLAVE_SCL_RISE
		if (rst) begin
			state <= READ_ADDR;
			start <= 0;
			sda_out_en <= 0;
			bit_count <= 7;
			data_in <= 0;
			addr <= 0;
		end 
		else begin
		if (start == 1) begin
			case(state)
				READ_ADDR: begin
					addr[bit_count] <= sda;
					if(bit_count == 0) state <= SEND_ACK;	// rw_mode
					else bit_count <= bit_count - 1;	// addr sampling		
				end
				
				SEND_ACK: begin     // ADDR ACK sent, prepare for next state
					if(addr[7:1] == SLAVE_ADDR) begin   // Slave address match
						bit_count <= 7;
						if(addr[0] == 0) begin  // rw_mode check
							// data_in <= 0;
							state <= READ_DATA;	// SLAVE READ (MASTER WRITE)
						end
						else state <= WRITE_DATA;
					end
				end
				
				READ_DATA: begin    // Receive data from master (MASTER WRITE)
					data_in[bit_count] <= sda;
					if(bit_count == 0) begin
						state <= SEND_ACK2;
					end else bit_count <= bit_count - 1;
				end
				
				SEND_ACK2: begin    // ACK for received data
					state <= READ_ADDR;					
				end
				
				WRITE_DATA: begin   // Send data to master (MASTER READ)
					if(bit_count == 0) state <= READ_ADDR;
					else bit_count <= bit_count - 1;		
				end
			endcase
		end
		end
	end
endmodule
