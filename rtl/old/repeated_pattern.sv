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

	input [4:0] pattern_w, // size of the pattern W 
	input [0:31] pattern,	// Bits for the repeated pattern
	//input [20:0] repetitionTimes, // How many times should the pattern be repeated // up to 1920x1080 (HD)
	input load_pattern, // to load the pattern for repetition

	//input rp_ready, // Ready signal for the module to verify the input

	output logic rp_mask_bit, // output of the repeated mask bit by bit
	output logic rp_valid // Valid signal for the output
);

// (LSB) 0 1 2 3 4 ..... 299(e.g.) (MSB)
logic [0:image_sensor_w-1] reg_curr, reg_next;

logic valid_next;
logic feedback_bit;

logic [21:0]counter;


always_ff @(posedge clk or negedge rst_n) 
begin
	if(~rst_n) 
	begin
		 rp_mask_bit<= 'd0;
		 rp_valid <= 1'b0;
		 reg_curr <= 'd0;
		 counter <='d0;
	end 
	else if(clk_en)
	begin

		if (load_pattern)
		begin
			reg_curr[0:31] <= pattern;
		end
		else
		begin
			reg_curr <= reg_next;
			rp_mask_bit <= feedback_bit;
			rp_valid <= valid_next;
		end
		 

		if (counter <= image_sensor_w)
			counter = counter + 22'd1;

	end
end


always_comb 
begin

	for (int i = 0; i < 32; i++) begin

		if(pattern_w == (i+1))
		begin 
			feedback_bit = reg_curr[i];	
		end
			
	end

	if (counter <= image_sensor_w)
	begin
		reg_next = {feedback_bit,reg_curr[0:image_sensor_w-2]};
		valid_next =1'b1;
	end
	else
		valid_next =1'b0;		

end

endmodule