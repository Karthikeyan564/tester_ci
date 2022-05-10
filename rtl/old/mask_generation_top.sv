module mask_generation_top
#(
	parameter max_image_sensor_w = 1920, // Max Width of the image sensor = 1920 (FHD)
	parameter max_image_sensor_h = 1080  // Max Height of the image sensor = 1080 (FHD)
 )
(
	input clk,    					// Clock
	input clk_en, 					// Clock Enable
	input rst_n,  					// Asynchronous reset active low

	// Image Sensor Signals

	input [10:0] image_sensor_w, 	// Width of the image sensor
	input [10:0] image_sensor_h, 	// Height of the image sensor

	// Pattern Input passed through the micro-processor

	input [4:0] pattern_w, 			// width of the pattern 
	input [4:0] pattern_h, 			// height of the pattern

	input [0:63] full_pattern,		// Bits for the repeated pattern (0: pixel 0 in row n, 1: pixel 0 in row n, ..., 31: pixel 31 in row n )
	input start_pattern,			// to load the 2D pattern for repetition
	input right_sliding,			// Direction of sliding 1-- right / 0 -- left

	input [1:0] mask_type,			// Choose the type of mask between  Repeated pattern 00 - sliding pattern 01 - Random Mask 10 
	
	output logic [0:max_image_sensor_w-1] mg_mask, // ROW MASK FOR THE IAMGE SENSOR
	output logic rp_valid 			// Valid signal for the output
	
);

// Repeating pattern Scheduler signals
logic load_pattern,load_pattern_rp;		    	// to load 1D the pattern for repetition
logic [0:31] pattern,pattern_rp; 				// ROW Pattern to repeat that will be sent to MG block

logic clk_en_rp;								// Clock Enable for the Repeated Pattern Scheduler


mask_generation #(max_image_sensor_w,max_image_sensor_h) mask_generation 
(	.clk(clk),   							// Clock
	.clk_en(clk_en), 						// Clock Enable
	.rst_n(rst_n),							// Asynchronous reset active low

	// Image Sensor Signals
	.image_sensor_w(image_sensor_w), 		// Width of the image sensor
	.image_sensor_h(image_sensor_h),		// Height of the image sensor

	// Pattern Input passed through the micro-processor
	.pattern_w(pattern_w), 					// size of the pattern W 
	.pattern(pattern),						// Bits for the repeated pattern (0: pixel 0 in row n, 1: pixel 0 in row n, ..., 31: pixel 31 in row n )
	.right_sliding(right_sliding),			// Direction of sliding 1-- right / 0 -- left
	.load_pattern(load_pattern), 			// to load the pattern for repetition


	.mask_type(mask_type),					// Choose the type of mask between  Repeated pattern 00 - sliding pattern 01 - Random Mask 10 

	.mg_mask(mg_mask), 						// output of the whole row mask 
	.rp_valid(rp_valid)						// Valid signal for the output
);

repeat_pattern_scheduler #(max_image_sensor_w,max_image_sensor_h) repeat_pattern_scheduler
(	.clk(clk),   							// Clock
	.clk_en(clk_en_rp), 					// Clock Enable
	.rst_n(rst_n),							// Asynchronous reset active low

	// Image Sensor Signals
	.image_sensor_w(image_sensor_w), 		// Width of the image sensor
	.image_sensor_h(image_sensor_h), 		// Height of the image sensor

	// Pattern Input passed through the micro-processor
	.pattern_w(pattern_w), 					// width of the pattern w 
	.pattern_h(pattern_h), 					// height of the pattern h

	.full_pattern(full_pattern),			// Bits for the repeated pattern (0: pixel 0 in row n, 1: pixel 0 in row n, ..., 31: pixel 31 in row n )
	.start_pattern_2D(start_pattern),		// to load the 2D pattern for repetition
	.mask_type(mask_type),					// Choose the type of mask between  Repeated pattern 00 - sliding pattern 01 - Random Mask 10 


	.rp_valid(rp_valid), 		// Valid signal outputed from MG block to see if the block is ready or not

	.load_pattern(load_pattern_rp), // to load 1D the pattern for repetition
	.pattern(pattern_rp) // ROW Pattern to repeat that will be sent to MG block

);


always_comb 
begin

case (mask_type)

	2'b00:
	begin 
		clk_en_rp = 1'b1;
		load_pattern = load_pattern_rp;
		pattern = pattern_rp;
	end

	2'b01: // Sliding Pattern
	begin
		clk_en_rp = 1'b0;
		pattern = full_pattern[0:31];
		load_pattern = start_pattern;
	end

	2'b10: // Random Pettern
	begin
		clk_en_rp = 1'b0;
		pattern = full_pattern[0:31];
		load_pattern = start_pattern;
	end

	default:
	begin 
		
		clk_en_rp = 1'b1;
		load_pattern = load_pattern_rp;
		pattern = pattern_rp;
	end

endcase

end


endmodule