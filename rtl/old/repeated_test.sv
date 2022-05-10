module repeated_test 
#(
	parameter image_sensor_w = 300, // Width of the image sensor
	parameter image_sensor_h = 300// Height of the image sensor
 )
(

	input [3:0] pattern, //4
	input [6:0] timesRepeat, //75
	input [2:0] pattern_size, //4



	output logic [299:0] repeatedPattern //300
	//input clk,    // Clock
	//input clk_en, // Clock Enable
	//input rst_n,  // Asynchronous reset active low
//
//	//// Pattern Input passed through the micro-processor
//
//	//input [4:0] pattern_w, // Width of the pattern max is 32 
//	//input [4:0] pattern_h, // Height of the pattern max is 32
//	//
//	//input [24:0] pattern,	// Bits for the repeated pattern
//
//	//input [10:0] repeat_pattern_vertical, // How many times should the row pattern repeated // up to 2048 (More than HD 1920)
//	//
//	//input rp_ready, // Ready signal for the module to verify the input
//
//	//output logic [image_sensor_w-1:0] rp_mask_bit, // output of the repeated mask row by row of the image sensor
	//output logic rp_valid // Valid signal for the output
);


//genvar i;
//for (i = 0; i < timesRepeat; i = i + 1) 
//begin
//
// always_comb
// begin
//
//  repeatedPattern[i * pattern_size +: pattern_size] = pattern[pattern_size-1:0]; 
// 
// end
//
//end

genvar i;
for (i = 0; i < 75; i = i + 1) begin
 always_comb begin
  repeatedPattern[i * 4 +: 4] = pattern;
 end
end

endmodule