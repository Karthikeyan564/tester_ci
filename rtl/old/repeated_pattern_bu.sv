//////////////////////////////////////////////////////////////////////////////////
// Company: UofT - ISML
// Engineer: Motasem Ahmed Sakr
//
// Create Date: 06/09/2020 01:52:13 AM
// Design Name:
// Module Name: Repeated Pattern (RP)
// Project Name: T6D
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module repeated_pattern 
#(
	parameter image_sensor_w = 300, // Width of the image sensor
	parameter image_sensor_h = 300// Height of the image sensor
 )
(
	input clk,    // Clock
	input clk_en, // Clock Enable
	input rst_n,  // Asynchronous reset active low

	// Pattern Input passed through the micro-processor

	input [4:0] pattern_w, // Width of the pattern max is 32 
	input [4:0] pattern_h, // Height of the pattern max is 32
	input [4:0] pattern_size, // size of the pattern W x H
	
	input [24:0] pattern,	// Bits for the repeated pattern

	input [10:0] repeat_pattern_vertical, // How many times should the row pattern be repeated // up to 2048 (More than HD 1920)
	
	input rp_ready, // Ready signal for the module to verify the input

	output logic [image_sensor_w-1:0] rp_mask_bit, // output of the repeated mask row by row of the image sensor
	output logic rp_valid // Valid signal for the output
);

logic [image_sensor_w-1:0] reg_curr, reg_next;

enum logic [2:0] {IDLE, ROW_GENERATION, ROW_OUTPUT} rp_curr_state, rp_next_state;
logic valid_next, valid_reg;

logic [4:0] pattern_index; // index while looping over the pattern



logic [4:0] row_pattern; // store the row pattern
logic [24:0] stored_pattern; // store the received pattern

logic [4:0] counter_pattern_rows; // counter for the row index in the pattern to know which row I am repeating now in the pattern  (e.g. if stored pattern 1100 and pattern_w=2, then row 0 = 11 and row 1 = 00)
logic [10:0] counter_rows; // counter for the rows of the image sensor to know when should I stop



always_comb 
begin

case (rp_curr_state)

	IDLE:
	begin 

		if (rp_ready)
		begin 
			rp_next_state <= ROW_GENERATION;
		end
		else
			rp_next_state <= IDLE;
	end

	ROW_GENERATION:
	begin 
		row_pattern = stored_pattern; // Defining the repeated pattern for each row


	end

	ROW_OUTPUT:
	begin

		row_pattern = stored_pattern; // Defining the repeated pattern for each row

		if (counter_rows < image_sensor_h)
		begin 
			for (int i = 0; i < repeat_pattern_vertical; i++) begin
				reg_next <= reg_next<<pattern_w;
				reg_next <= reg_next + row_pattern;	
			end
			//reg_next = {repeat_row_pattern{row_pattern}};
			valid_next = 1'b1;
			rp_next_state <= ROW_GENERATION;
			//reg_next [image_sensor_w-1:image_sensor_w-1-pattern_w] = row_pattern;
		end
		else
		begin 
			reg_next = '0;
			valid_next = 1'b0;
			rp_next_state <= IDLE;
		end

	end

endcase


end


always_ff @(posedge clk or negedge rst_n) 
begin : proc_
	if(~rst_n) 
	begin
		 rp_mask_bit<= 'd0;
		 rp_valid <= 1'b0;
		 reg_curr <= 'd0;
		 counter_pattern_rows <= 'd0;
		 rp_curr_state <= IDLE;
		 counter_rows <= 'd0;
		 valid_reg <= 1'b0;
	end 
	else if(clk_en)
	begin

		reg_curr <= reg_next;
		rp_curr_state <= rp_next_state;
		valid_reg <= valid_next;

		if (rp_ready)
		begin
			stored_pattern = pattern;
		end

		// Repeat the pattern vertically for ever

		if (counter_pattern_rows < pattern_h)
		begin 
			stored_pattern = stored_pattern << pattern_w;
			counter_pattern_rows = counter_pattern_rows + 5'd1;
		end
		else
		begin
			counter_pattern_rows = 'd0;
		end

		// Loop over the image sensor

		if (counter_rows < image_sensor_h)
		begin
			counter_rows = counter_rows + 11'd1;

		end
		else
		begin 
			counter_rows = 'd0;
		end
		 
	end

	rp_mask_bit = reg_curr;
	rp_valid = valid_reg;
end


endmodule