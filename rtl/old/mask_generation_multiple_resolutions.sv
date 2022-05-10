//////////////////////////////////////////////////////////////////////////////////
// Company: UofT - ISML
// Engineer: Motasem Ahmed Sakr
//
// Create Date: 06/13/2020 02:00:09 AM
// Design Name:
// Module Name: Mask Generation (MG)
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

module mask_generation 
#(
	parameter max_image_sensor_w = 1920, // Max Width of the image sensor = 1920 (FHD)
	parameter max_image_sensor_h = 1080  // Max Height of the image sensor = 1080 (FHD)
	//parameter max_num_subframes = 1000   // Max Number of Subframes = 1000
 )
(
	input clk,    // Clock
	input clk_en, // Clock Enable
	input rst_n,  // Asynchronous reset active low

	// Image Sensor Signals

	input [10:0] image_sensor_w, // Width of the image sensor
	input [10:0] image_sensor_h, // Height of the image sensor
//	input [9:0]  num_subframes,  // Number of subframes

	// Pattern Input passed through the micro-processor

	input [4:0] pattern_w, // size of the pattern W 
	input [0:31] pattern,	// Bits for the repeated pattern (0: pixel 0 in row n, 1: pixel 0 in row n, ..., 31: pixel 31 in row n )
	input right_sliding,	// Direction of sliding 1-- right / 0 -- left
	input load_pattern, // to load the pattern for repetition


	input [1:0] mask_type,	// Choose the type of mask between  Repeated pattern 00 - sliding pattern 01 - Random Mask 10 

	//input rp_ready, // Ready signal for the module to verify the input

	//output logic rp_mask_bit, // output of the repeated mask bit by bit
	output logic [0:max_image_sensor_w-1] mg_mask, 
	output logic rp_valid // Valid signal for the output
);

// (LSB) 0 1 2 3 4 ..... 299(e.g.) (MSB)
logic [0:max_image_sensor_w-1] reg_curr, reg_next;
logic [0:31]stored_pattern;

logic valid_next;
logic feedback_bit;

logic [21:0] counter; // counter for repeating the pattern and random number across multiple columns based on the image_sensor_w
//logic [21:0] counter_subframes; // Counter for outputing the pattern up to number of subframes x image_sensor_h

// Registers for Sliding Pattern
logic [0:31] pre_reg_curr,pre_reg_next,post_reg_curr,post_reg_next;
logic slide_bit;


always @(*)
begin
	case (mask_type)

		2'b00: // Repeated Pattern
		begin 

			for (int i = 0; i < 32; i++) begin

				if(pattern_w == (i+1))
				begin 
					feedback_bit = reg_curr[i];	
				end
					
			end


			if (counter < image_sensor_w)
			begin
				reg_next = {feedback_bit,reg_curr[0:max_image_sensor_w-2]};
				valid_next =1'b0;
			end
			else
				valid_next =1'b1;		

		end

		2'b01: // Sliding Pattern
		begin 

			valid_next = 1'b1;
			// if (counter_subframes < num_subframes) 
			// begin
				
			// 	valid_next =1'b1;

			// end
			// else
			// begin 

			// 	valid_next =1'b0;

			// end

			for (int i = 0; i < max_image_sensor_w; i++)
			begin 
		
				if (right_sliding) // Shift Right
				begin

					pre_reg_next = 'd0;

					// Define the Sliding bit to the extra post reg
					if(image_sensor_w == (i+1))
					begin
						slide_bit = reg_curr[i];
						post_reg_next = {slide_bit,post_reg_curr[0:30]};

					end

					// Define the feedback bit to slide the pattern right
					if(pattern_w == (i+1))
					begin 

						feedback_bit = post_reg_curr[i];
						reg_next = {feedback_bit,reg_curr[0:max_image_sensor_w-2]};

					end
				
				end
				else // Shift Left
				begin

					post_reg_next = 'd0;

					// Define the Sliding bit to the extra pre reg
					if(image_sensor_w == (i+1))
					begin
						slide_bit = reg_curr[max_image_sensor_w-i];
						pre_reg_next  = {pre_reg_curr[1:31],slide_bit};
					end

					// Define the feedback bit to slide the pattern left
					if (pattern_w == (31-i))
					begin 

						feedback_bit = pre_reg_curr[i];
						reg_next = {reg_curr[1:max_image_sensor_w-1],feedback_bit};	
					
					end

				end

			end

		end

		2'b10: // Random Pattern: Fibonacci 
		begin 

			if (counter < image_sensor_w)
			begin
				reg_next = {(reg_curr[31]^reg_curr[21]^reg_curr[1]^reg_curr[0]),reg_curr[0:max_image_sensor_w-2]};
				valid_next =1'b0;
			end
			else
				valid_next =1'b1;		
		
		end
		
		default: // Repeating Pattern
		begin 

			for (int i = 0; i < 32; i++) begin

				if(pattern_w == (i+1))
				begin 
					feedback_bit = reg_curr[i];	
				end
				
			end

			if (counter < image_sensor_w)
			begin
				reg_next = {feedback_bit,reg_curr[0:max_image_sensor_w-2]};
				valid_next =1'b1;
			end
			else
				valid_next =1'b0;		

		end

	endcase

end

always_ff @(posedge clk or negedge rst_n) 
begin

	if(~rst_n) 
	begin
		 //rp_mask_bit<= 'd0;
		 rp_valid <= 1'b0;
		 reg_curr <= 'd0;
		 counter <='d0;
		 mg_mask <='d0;
		 pre_reg_curr <='d0;
		 post_reg_curr <='d0;
//		 counter_subframes <= 'd0;
	end 
	else if(clk_en)
	begin

		if (load_pattern)
		begin

			stored_pattern = pattern;
			reg_curr[0:31] = pattern;
			reg_curr[32:max_image_sensor_w-1] ='d0;
			rp_valid=1'd0;
			counter = 'd0;
        	pre_reg_curr ='d0;
        	post_reg_curr ='d0;
//        	counter_subframes <='d0;
	       
		end
		else
		begin


			reg_curr <= reg_next;
			pre_reg_curr<=pre_reg_next;
			post_reg_curr<=post_reg_next;

			
			rp_valid <= valid_next;

			// Output the 1-bit for the mask pixel by pixel
			// case (mask_type)
			// 	2'b00: // Repeated Pattern
			// 	begin 
			// 		//rp_mask_bit <= feedback_bit;
			// 	end

			// 	2'b01: // Sliding Pattern
			// 	begin 

			// 		mg_mask <= reg_curr;
			// 		// if(right_sliding)
			// 		// 	rp_mask_bit <= reg_curr[image_sensor_w-1];
			// 		// else
			// 		// 	rp_mask_bit <= reg_curr[0];
			// 	end
		
			// 	default : rp_mask_bit <= feedback_bit;
			// endcase

		// Controlling the time for outputing the mg_mask
			case (mask_type)
				2'b00: // Repeated Pattern
				begin 
						
					if (counter < image_sensor_w)
					begin 

						counter = counter + 22'd1;
						rp_valid <=1'b0;

					end 
					else
					begin 
						mg_mask <=reg_curr;
					end
						
				end

				2'b01: // Sliding Pattern
				begin

					mg_mask <= reg_curr;

					// if (counter_subframes < num_subframes)
					// 	counter_subframes = counter_subframes + 22'd1;

					// If you want to reset the pattern after reaching the max subframes
					// else
					// begin 

					// 	counter_subframes = 'd0; 
					// 	reg_curr[0:31] <= pattern;
					// 	reg_curr[32:max_image_sensor_w-1] <='d0;

					// end



				end

				2'b10: // Random Pattern: Fibonacci random number generator
				begin 
					
					if (counter < image_sensor_w) 
						counter = counter + 22'd1;
					else
					begin 
						mg_mask <=reg_curr;
						counter = 'd0;
					end

				end
		
				default : 
				begin

					if (counter < image_sensor_w) 
						counter = counter + 22'd1;
					else
					begin 
						mg_mask <=reg_curr;
						counter = 'd0;
					end

				end
			endcase

		end

	end
end



endmodule