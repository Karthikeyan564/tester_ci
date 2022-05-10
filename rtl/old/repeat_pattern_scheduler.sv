//////////////////////////////////////////////////////////////////////////////////
// Company: UofT - ISML
// Engineer: Motasem Ahmed Sakr
//
// Create Date: 06/19/2020 02:00:09 PM
// Design Name:
// Module Name: Repeat pattern scheduler  
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

module repeat_pattern_scheduler
#(
	parameter max_image_sensor_w = 1920, // Max Width of the image sensor = 1920 (FHD)
	parameter max_image_sensor_h = 1080  // Max Height of the image sensor = 1080 (FHD)
)
(
	input clk,    // Clock
	input clk_en, // Clock Enable
	input rst_n,  // Asynchronous reset active low

	// Image Sensor Signals

	input [10:0] image_sensor_w, // Width of the image sensor
	input [10:0] image_sensor_h, // Height of the image sensor

	// Pattern Input passed through the micro-processor

	input [4:0] pattern_w, // width of the pattern 
	input [4:0] pattern_h, // height of the pattern

	input [0:63] full_pattern,	// Bits for the repeated pattern (0: pixel 0 in row n, 1: pixel 0 in row n, ..., 31: pixel 31 in row n )
	input start_pattern_2D,	// to load the 2D pattern for repetition
	input [1:0] mask_type,	// Choose the type of mask between  Repeated pattern 00 - sliding pattern 01 - Random Mask 10 


	input rp_valid, 		// Valid signal outputed from MG block to see if the block is ready or not

	output logic load_pattern, // to load 1D the pattern for repetition
	output logic [0:31] pattern // ROW Pattern to repeat that will be sent to MG block
	
);


enum logic [2:0] {IDLE, ROW_GENERATION, SEND_ROW_MASK} rp_curr, rp_next;

logic [0:31] row_pattern;
logic [9:0] counter_pattern_w;
logic [10:0] counter_pattern_h;


always_ff @(posedge clk or negedge rst_n) 
begin
	if(~rst_n) 
	begin
		 
		 rp_curr <= IDLE;
		 counter_pattern_h = 'd0;
		 counter_pattern_w = 'd0;

	end else if(clk_en & mask_type == 2'b00) 
	begin
		
		rp_curr <= rp_next;

		if(start_pattern_2D)
		begin 

			rp_curr <= IDLE;
			//row_pattern = 'd0;
			counter_pattern_h = 'd0;
			counter_pattern_w = 'd0;

		end

		case (rp_next)
			
			ROW_GENERATION:
			begin 

				if(counter_pattern_w < ((pattern_w * pattern_h) - pattern_w))
				begin 
					counter_pattern_w = counter_pattern_w +10'd1;
				end
				else
				begin 
					counter_pattern_w = 'd0;
				end

			end

			SEND_ROW_MASK:
			begin 

				if (rp_valid)
				begin

					if(counter_pattern_h < image_sensor_h)
					begin 
						counter_pattern_h = counter_pattern_h +10'd1;
					end
					else
					begin 
						counter_pattern_w = 'd0;
					end					 

				end

			end

		endcase


	end
end

always_comb 
begin

	if(mask_type == 2'b00)
	begin 
		
		load_pattern = 1'b0;

		case (rp_curr)

			IDLE:
			begin

				//row_pattern = 'd0;
				if (start_pattern_2D)
				begin
					rp_next = ROW_GENERATION;
					pattern = full_pattern[counter_pattern_w +: 32];
					load_pattern = 1'b1;

				end
				else
					rp_next = IDLE;


			end

			ROW_GENERATION:
			begin

				if ((counter_pattern_w % pattern_w) == 0 )
				begin

					row_pattern = full_pattern[counter_pattern_w +: 32];
					rp_next = SEND_ROW_MASK;
				end
				else
					rp_next = ROW_GENERATION;

			end

			SEND_ROW_MASK:
			begin

				if(rp_valid)
				begin 

					if (counter_pattern_h < image_sensor_h)
						rp_next = ROW_GENERATION;
					else
						rp_next = IDLE;

					pattern = row_pattern;
					load_pattern = 1'b1;

				end
				else
				begin 

					rp_next = SEND_ROW_MASK;
					load_pattern = 1'b0;

				end


			end

		endcase



	end


end

endmodule